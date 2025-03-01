import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/epub_providers.dart';

/// A widget that displays an EPUB book as an overlay
class EpubViewerOverlay extends ConsumerWidget {
  const EpubViewerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final epubState = ref.watch(epubStateProvider);

    // If the EPUB viewer is not visible, return an empty container
    if (!epubState.isVisible || epubState.filePath == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Swipe left to right (next page)
          if (details.primaryVelocity! < 0) {
            ref.read(epubStateProvider.notifier).nextPage();
          }
          // Swipe right to left (previous page)
          else if (details.primaryVelocity! > 0) {
            ref.read(epubStateProvider.notifier).previousPage();
          }
        },
        child: Container(
          color: Colors.white,
          child: Stack(
            children: [
              // EPUB content
              Center(child: _buildEpubContent(context, epubState.filePath!)),

              // Close button
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ref.read(epubStateProvider.notifier).hide();
                  },
                ),
              ),

              // Navigation controls
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed:
                          epubState.currentPage > 0
                              ? () {
                                ref
                                    .read(epubStateProvider.notifier)
                                    .previousPage();
                              }
                              : null,
                    ),
                    Text(
                      '${epubState.currentPage + 1} / ${epubState.totalPages}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed:
                          epubState.currentPage < epubState.totalPages - 1
                              ? () {
                                ref.read(epubStateProvider.notifier).nextPage();
                              }
                              : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
