import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/epub_providers.dart';
import '../../providers/annotated_book_providers.dart';
import '../../services/file_picker_service.dart';
import '../../services/flutter_epub_viewer_service.dart' as service;
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '../../../../core/widgets/stylus_input_ignored_widget.dart';

// State provider to track if the EPUB is being loaded
final epubLoadingProvider = StateProvider<bool>((ref) => false);

// State provider to track if the EPUB viewer is embedded
final epubEmbeddedProvider = StateProvider<bool>((ref) => false);

/// A widget that displays an EPUB book in a swipeable panel
class SwipeableEpubViewer extends ConsumerStatefulWidget {
  const SwipeableEpubViewer({super.key});

  @override
  ConsumerState<SwipeableEpubViewer> createState() =>
      _SwipeableEpubViewerState();
}

class _SwipeableEpubViewerState extends ConsumerState<SwipeableEpubViewer>
    with SingleTickerProviderStateMixin {
  // Controls the position of the EPUB viewer
  // 0.0 = fully visible
  // 1.0 = swiped off-screen
  double _swipePosition = 0.0;

  // Width of the visible portion when minimized (in pixels)
  static const double _minVisibleWidth = 25.0;

  // Width of the EPUB viewer (as a percentage of screen width)
  static const double _epubWidthPercentage = 0.5;

  // Width of the swipe tab
  static const double _tabWidth = 80.0;
  static const double _tabHeight = 50.0;

  // Tab offset when minimized (negative value to move it outside the EPUB viewer)
  static const double _tabOffsetWhenMinimized = -60.0;

  // Corner radius values for the tab
  static const double _tabCornerRadius = 12.0;

  // Animation controller for smooth swipe
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isInitialized = false;

  // EPUB controller
  final EpubController _epubController = EpubController();

  // Debounce mechanism to prevent rapid animations
  DateTime _lastAnimationTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeAnimationController();
  }

  void _initializeAnimationController() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuint,
    );

    _animationController.addListener(() {
      if (mounted) {
        setState(() {
          _swipePosition = _animation.value;
        });
      }
    });

    _isInitialized = true;

    // Check if we need to load a sample book
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSampleBookIfNeeded();
        // Start with the panel fully visible
        _swipePosition = 0.0;
      }
    });
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _animationController.dispose();
    }
    super.dispose();
  }

  // Simple animation to target position
  void _animateToPosition(double targetPosition) {
    if (!_isInitialized) return;

    // Debounce animations - prevent rapid changes that cause flickering
    final now = DateTime.now();
    if (now.difference(_lastAnimationTime).inMilliseconds < 200) {
      return; // Skip if too soon after last animation
    }
    _lastAnimationTime = now;

    // Stop any ongoing animation
    _animationController.stop();

    // Set up the animation
    _animation = Tween<double>(
      begin: _swipePosition,
      end: targetPosition,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Reset and run the animation
    _animationController.reset();
    _animationController.forward();
  }

  // Load the sample book if no book is currently loaded
  void _loadSampleBookIfNeeded() {
    try {
      final currentBook = ref.read(currentBookProvider);
      final books = ref.read(annotatedBooksProvider);

      if (currentBook == null && books.isNotEmpty) {
        // Set the first book as the current book
        ref.read(currentBookProvider.notifier).setBook(books.first);

        // Load the EPUB
        ref.read(epubStateProvider.notifier).loadEpub(books.first.filePath);
      }
    } catch (e) {
      debugPrint('Error loading sample book: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    final epubState = ref.watch(epubStateProvider);
    final currentBook = ref.watch(currentBookProvider);

    // If no book is loaded or the EPUB viewer is not visible, return an empty container
    if (!epubState.isVisible ||
        epubState.filePath == null ||
        currentBook == null) {
      return const SizedBox.shrink();
    }

    // Calculate the width of the EPUB viewer (constant at 50% of screen width)
    final screenWidth = MediaQuery.of(context).size.width;
    final epubWidth = screenWidth * _epubWidthPercentage;

    // Calculate the translation offset based on swipe position
    // When fully visible (_swipePosition = 0.0), offset is 0
    // When fully swiped (_swipePosition = 1.0), offset is (epubWidth - _minVisibleWidth)
    final translationOffset = _swipePosition * (epubWidth - _minVisibleWidth);

    // Calculate if the EPUB viewer is mostly hidden (>80% swiped)
    final bool isEpubMostlyHidden = _swipePosition > 0.8;
    final bool isEpubFullyHidden = _swipePosition >= 0.99;

    // Calculate tab position for hit testing
    final tabProgress =
        _swipePosition <= 0.6 ? 0.0 : (_swipePosition - 0.6) / 0.4;
    final tabLeftPosition = tabProgress * _tabOffsetWhenMinimized;

    // Create a Stack to hold both the EPUB viewer and the tab
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Add a GestureDetector for the right edge of the screen
        // This allows swiping from the right edge to bring the EPUB viewer back
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: _minVisibleWidth,
          child: IgnorePointer(
            // Only detect gestures when the EPUB viewer is mostly hidden
            ignoring: !isEpubMostlyHidden,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (isEpubMostlyHidden) {
                  setState(() {
                    // Calculate position change based on drag
                    final dragAmount =
                        -details.delta.dx / (epubWidth - _minVisibleWidth);
                    _swipePosition = (_swipePosition - dragAmount).clamp(
                      0.0,
                      1.0,
                    );
                  });
                }
              },
              onHorizontalDragEnd: (details) {
                if (isEpubMostlyHidden) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity < -300) {
                    // Fast swipe left - show
                    _animateToPosition(0.0);
                  } else if (velocity.abs() < 300) {
                    // Slow swipe - toggle based on how far we've dragged
                    _animateToPosition(_swipePosition > 0.95 ? 1.0 : 0.0);
                  }
                }
              },
              onTap: () {
                if (isEpubMostlyHidden) {
                  _animateToPosition(0.0); // Open the EPUB viewer
                }
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        ),

        // Main EPUB viewer container - positioned off-screen when minimized
        Positioned(
          top: 0,
          bottom: 0,
          // When minimized, position it completely off-screen except for the visible strip
          right: -translationOffset,
          width: epubWidth,
          child: IgnorePointer(
            // Ignore pointer events when mostly hidden, allowing canvas to receive them
            ignoring: isEpubMostlyHidden,
            child: Material(
              // Use Material widget to ensure proper rendering
              color: Colors.transparent,
              child: _buildEpubContainer(
                context,
                epubState,
                currentBook,
                epubWidth,
              ),
            ),
          ),
        ),

        // Tab for swiping - always visible and interactive
        Positioned(
          bottom: 16,
          // Position the tab at the edge of the visible portion
          right:
              isEpubFullyHidden
                  ? -20
                  : epubWidth - translationOffset - _tabWidth - tabLeftPosition,
          width: _tabWidth, // Always use fixed tab width
          height: _tabHeight,
          child: _buildSwipeTab(epubWidth, tabProgress, isEpubFullyHidden),
        ),
      ],
    );
  }

  // Build the swipe tab separately
  Widget _buildSwipeTab(
    double epubWidth,
    double tabProgress,
    bool isFullyMinimized,
  ) {
    final topLeftRadius = tabProgress * _tabCornerRadius;
    final bottomLeftRadius = tabProgress * _tabCornerRadius;

    return Transform.scale(
      // Subtle scale effect based on swipe position
      scale: 1.0 + (tabProgress * 0.1),
      child: Material(
        elevation: 0, // Remove elevation from the tab itself
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(topLeftRadius),
          bottomLeft: Radius.circular(bottomLeftRadius),
          topRight: const Radius.circular(_tabCornerRadius),
          bottomRight: const Radius.circular(_tabCornerRadius),
        ),
        child: GestureDetector(
          // Add gesture detector to the tab for swiping
          onHorizontalDragUpdate: (details) {
            setState(() {
              // Calculate position change based on drag
              final dragAmount =
                  details.delta.dx / (epubWidth - _minVisibleWidth);
              _swipePosition = (_swipePosition + dragAmount).clamp(0.0, 1.0);
            });
          },
          onHorizontalDragEnd: (details) {
            // Simple threshold-based decision
            final velocity = details.primaryVelocity ?? 0;

            if (velocity > 300) {
              // Fast swipe right - dismiss
              _animateToPosition(1.0);
            } else if (velocity < -300) {
              // Fast swipe left - show
              _animateToPosition(0.0);
            } else {
              // Based on position
              _animateToPosition(_swipePosition > 0.5 ? 1.0 : 0.0);
            }
          },
          onTap: () {
            // Toggle between open and closed on tap
            _animateToPosition(_swipePosition < 0.5 ? 1.0 : 0.0);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200, // Lighter grey with constant opacity
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(topLeftRadius),
                bottomLeft: Radius.circular(bottomLeftRadius),
                topRight: const Radius.circular(_tabCornerRadius),
                bottomRight: const Radius.circular(_tabCornerRadius),
              ),
              border: Border.all(
                color: Colors.grey.shade400, // More visible border color
                width: 1.0, // Thinner border
              ),
            ),
            child: Row(
              // Align chevron to the left when minimized, center otherwise
              mainAxisAlignment:
                  isFullyMinimized
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: isFullyMinimized ? 8.0 : 0),
                  child: Icon(
                    _swipePosition < 0.5
                        ? Icons.keyboard_double_arrow_right
                        : Icons.keyboard_double_arrow_left,
                    color: Colors.grey.shade700,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build the main epub container with all its contents
  Widget _buildEpubContainer(
    BuildContext context,
    dynamic epubState,
    dynamic currentBook,
    double epubWidth,
  ) {
    return Stack(
      clipBehavior: Clip.none, // Prevent clipping of child widgets
      children: [
        // Main EPUB container with shadow on the left edge only
        PhysicalModel(
          color: Colors.white,
          elevation: 5.0, // Increased from 3.0 to 5.0
          shadowColor: Colors.black.withAlpha(
            20,
          ), // Using withAlpha for better precision
          // Add a custom shadow that only appears on the left side
          child: Container(
            width:
                double.infinity, // Ensure full width within parent constraints
            height: double.infinity, // Ensure full height
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(
                  color: Colors.grey.shade400, // Match the tab border color
                  width: 1.0,
                ),
              ),
              // Add box shadow only on the left side
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(
                    20,
                  ), // Using withAlpha instead of withOpacity
                  blurRadius: 5.0,
                  spreadRadius: 0.0,
                  offset: const Offset(
                    -2.0,
                    0.0,
                  ), // Shadow only on the left side
                ),
              ],
            ),
            child: _buildEpubContent(context, epubState.filePath!),
          ),
        ),

        // Navigation controls - centered in the available space with more spacing
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center, // Center alignment instead of spaceEvenly
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed:
                      epubState.currentPage > 0
                          ? () {
                            ref.read(epubStateProvider.notifier).previousPage();
                            // Update the current book's last page
                            if (currentBook != null) {
                              ref
                                  .read(currentBookProvider.notifier)
                                  .updateLastPage(epubState.currentPage - 1);
                            }
                          }
                          : null,
                ),
                const SizedBox(width: 10), // Reduced spacing from 40 to 10
                Text(
                  '${epubState.currentPage + 1} / ${epubState.totalPages}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10), // Reduced spacing from 40 to 10
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed:
                      epubState.currentPage < epubState.totalPages - 1
                          ? () {
                            ref.read(epubStateProvider.notifier).nextPage();
                            // Update the current book's last page
                            if (currentBook != null) {
                              ref
                                  .read(currentBookProvider.notifier)
                                  .updateLastPage(epubState.currentPage + 1);
                            }
                          }
                          : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build the EPUB content
  Widget _buildEpubContent(BuildContext context, String filePath) {
    // Determine if the file path is an asset path
    final isAsset = FilePickerService.isAssetPath(filePath);

    // Check if the EPUB is being loaded
    final isLoading = ref.watch(epubLoadingProvider);

    // Check if the EPUB viewer is embedded
    final isEmbedded = ref.watch(epubEmbeddedProvider);

    // If the EPUB is embedded, show the embedded viewer
    if (isEmbedded) {
      // Create the source based on the file path
      final epubSource =
          isAsset
              ? service.FlutterEpubViewerService.getSourceForAsset(filePath)
              : service.FlutterEpubViewerService.getSourceForFile(filePath);

      // Return the EpubViewer widget
      return StylusInputIgnoredWidget(
        child: EpubViewer(
          epubController: _epubController,
          epubSource: epubSource,
          displaySettings: EpubDisplaySettings(
            flow: EpubFlow.paginated,
            snap: true,
          ),
          onChaptersLoaded: (chapters) {
            debugPrint('Chapters loaded: ${chapters.length}');
          },
          onEpubLoaded: () {
            debugPrint('EPUB loaded');
          },
          onRelocated: (dynamic value) {
            // Update the current page with default values
            int currentPage = 0;
            int totalPages = 1;

            // Log the value for debugging
            debugPrint('Relocated: $value');

            // Update the page info in the state
            ref
                .read(epubStateProvider.notifier)
                .updatePageInfo(
                  currentPage: currentPage,
                  totalPages: totalPages,
                );

            // Update the current book's last page
            final currentBook = ref.read(currentBookProvider);
            if (currentBook != null) {
              ref
                  .read(currentBookProvider.notifier)
                  .updateLastPage(currentPage);
            }
          },
          onTextSelected: (dynamic selection) {
            // Log the selection for debugging
            debugPrint('Text selected: $selection');
          },
        ),
      );
    }

    // If the EPUB is loading, show a loading spinner
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading EPUB...'),
          ],
        ),
      );
    }

    // Otherwise, show a button to open the EPUB
    return StylusInputIgnoredWidget(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'EPUB Viewer',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            isAsset ? 'Asset: $filePath' : 'File: $filePath',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _openEpubBook(context, filePath, isAsset),
            child: const Text('Open EPUB'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Swipe left or right to navigate between pages',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Open the EPUB book
  void _openEpubBook(
    BuildContext context,
    String filePath,
    bool isAsset,
  ) async {
    // Set loading state to true
    ref.read(epubLoadingProvider.notifier).state = true;

    try {
      // Set embedded state to true before opening the EPUB
      ref.read(epubEmbeddedProvider.notifier).state = true;

      // No need to configure the viewer anymore as we're using the EpubController directly
    } catch (e) {
      // Reset states on error
      ref.read(epubLoadingProvider.notifier).state = false;
      ref.read(epubEmbeddedProvider.notifier).state = false;

      // Show a more detailed error message
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error Opening EPUB'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to open: ${filePath.split('/').last}'),
                    const SizedBox(height: 10),
                    Text('Error: ${e.toString()}'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
      debugPrint('Error opening EPUB: $e');
    } finally {
      // Set loading state to false
      ref.read(epubLoadingProvider.notifier).state = false;
    }
  }
}
