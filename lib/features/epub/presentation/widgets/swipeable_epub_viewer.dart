import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/epub_providers.dart';
import '../../providers/annotated_book_providers.dart';

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
  static const double _minVisibleWidth = 20.0;

  // Width of the EPUB viewer (as a percentage of screen width)
  static const double _epubWidthPercentage = 0.5;

  // Width of the swipe tab
  static const double _tabWidth = 80.0;
  static const double _tabHeight = 50.0;

  // Tab offset when minimized (negative value to move it outside the EPUB viewer)
  static const double _tabOffsetWhenMinimized = -40.0;

  // Corner radius values for the tab
  static const double _tabCornerRadius = 12.0;

  // Animation controller for smooth swipe
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isInitialized = false;

  // Debounce mechanism to prevent rapid animations
  DateTime _lastAnimationTime = DateTime.now();

  // Listener for detecting stylus input across the EPUB viewer area only
  bool _isStylusInput = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimationController();
  }

  void _initializeAnimationController() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
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
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuint),
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

    // Only cover the right half of the screen with touch events
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: epubWidth,
        height: double.infinity,
        child: GestureDetector(
          // Add a top-level gesture detector to ensure touch events are captured
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            // Skip if stylus input
            if (_isStylusInput) return;

            // Simple direct manipulation
            setState(() {
              // Calculate position change based on drag
              final dragAmount =
                  details.delta.dx / (epubWidth - _minVisibleWidth);
              _swipePosition = (_swipePosition + dragAmount).clamp(0.0, 1.0);
            });
          },
          onHorizontalDragEnd: (details) {
            // Skip if stylus input
            if (_isStylusInput) return;

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
          child: Material(
            // Use Material widget to ensure proper rendering
            color: Colors.transparent,
            child: Stack(
              children: [
                // The EPUB viewer - always present
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: -translationOffset,
                  width: epubWidth,
                  child: _buildEpubContainer(context, epubState, currentBook),
                ),

                // Edge swipe detector - only when minimized
                if (_swipePosition > 0.9)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: _minVisibleWidth + 20,
                    child: GestureDetector(
                      onTap: () => _animateToPosition(0.0),
                      onHorizontalDragEnd: (details) {
                        // Skip if stylus input
                        if (_isStylusInput) return;

                        // Simple velocity check
                        if ((details.primaryVelocity ?? 0) < -300) {
                          _animateToPosition(0.0); // Open
                        }
                      },
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                // Listener for detecting stylus input across the EPUB viewer area only
                Positioned.fill(
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (event) {
                      if (event.kind == PointerDeviceKind.stylus) {
                        setState(() {
                          _isStylusInput = true;
                        });
                      }
                    },
                    onPointerUp: (event) {
                      if (event.kind == PointerDeviceKind.stylus) {
                        setState(() {
                          _isStylusInput = false;
                        });
                      }
                    },
                    child: Container(color: Colors.transparent),
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
  ) {
    // Calculate the tab's left position based on swipe position
    // Only start moving the tab when the slide is 60% complete
    // This prevents the button from moving under the user's finger during most of the slide
    final tabProgress =
        _swipePosition <= 0.6
            ? 0.0
            : (_swipePosition - 0.6) /
                0.4; // Normalize the remaining 40% to 0-100%
    final tabLeftPosition = tabProgress * _tabOffsetWhenMinimized;

    // Calculate corner radius transformation
    // When visible, keep normal corners (right side rounded)
    // When minimized, transform to have both sides rounded
    final topLeftRadius = tabProgress * _tabCornerRadius;
    final bottomLeftRadius = tabProgress * _tabCornerRadius;

    return Stack(
      clipBehavior: Clip.none, // Prevent clipping of child widgets
      children: [
        // Main EPUB container with shadow on the left edge only
        PhysicalModel(
          color: Colors.white,
          elevation: 6.0,
          shadowColor: Colors.black.withAlpha(
            77,
          ), // Using withAlpha instead of withOpacity (0.3 * 255 ≈ 77)
          child: Container(
            width:
                double.infinity, // Ensure full width within parent constraints
            height: double.infinity, // Ensure full height
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(
                  color:
                      Colors
                          .grey
                          .shade300, // Subtle border color matching the tab
                  width: 1.0,
                ),
              ),
            ),
            child: _buildEpubContent(context, epubState.filePath!),
          ),
        ),

        // Tab for swiping away the epub (aligned with navigation controls)
        Positioned(
          bottom: 16, // Same position as the navigation controls
          left: tabLeftPosition,
          width: _tabWidth,
          height: _tabHeight, // Use the animated height
          // Use a higher z-index to ensure the tab is above other elements
          child: Transform.scale(
            // Subtle scale effect based on swipe position
            scale: 1.0 + (tabProgress * 0.1),
            child: Material(
              elevation: 0, // Remove elevation from the tab
              color: Colors.transparent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(topLeftRadius),
                bottomLeft: Radius.circular(bottomLeftRadius),
                topRight: const Radius.circular(_tabCornerRadius),
                bottomRight: const Radius.circular(_tabCornerRadius),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      Colors
                          .grey
                          .shade200, // Lighter grey with constant opacity
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(topLeftRadius),
                    bottomLeft: Radius.circular(bottomLeftRadius),
                    topRight: const Radius.circular(_tabCornerRadius),
                    bottomRight: const Radius.circular(_tabCornerRadius),
                  ),
                  border: Border.all(
                    color: Colors.grey.shade300, // More subtle border color
                    width: 1.0, // Thinner border
                  ),
                ),
                child: Row(
                  // Adjust alignment based on swipe position
                  // When minimized, shift the arrow to be centered in the visible portion
                  mainAxisAlignment:
                      _swipePosition > 0.9
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                  children: [
                    // Add padding that increases as the tab moves off-screen
                    // This keeps the arrow centered in the visible portion
                    Padding(
                      padding: EdgeInsets.only(
                        left:
                            _swipePosition > 0.9
                                ? (_tabWidth - _minVisibleWidth) * 0.5 -
                                    15 // Center in visible area
                                : 0, // No padding when fully visible
                      ),
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
    // For now, we'll just display a placeholder
    // In a real implementation, you would use the vocsy_epub_viewer to display the content
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('EPUB Viewer', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Text('File: $filePath', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 32),
        const Text(
          'Swipe left or right to navigate between pages',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
