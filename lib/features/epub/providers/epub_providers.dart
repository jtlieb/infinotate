import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/epub_state.dart';

/// Provider for the EPUB state
final epubStateProvider = StateNotifierProvider<EpubStateNotifier, EpubState>(
  (ref) => EpubStateNotifier(),
);

/// Notifier for the EPUB state
class EpubStateNotifier extends StateNotifier<EpubState> {
  EpubStateNotifier() : super(const EpubState());

  /// Load an EPUB file
  void loadEpub(String filePath) {
    state = state.copyWith(filePath: filePath, isVisible: true, currentPage: 0);
  }

  /// Toggle the visibility of the EPUB viewer
  void toggleVisibility() {
    state = state.copyWith(isVisible: !state.isVisible);
  }

  /// Show the EPUB viewer
  void show() {
    state = state.copyWith(isVisible: true);
  }

  /// Hide the EPUB viewer
  void hide() {
    state = state.copyWith(isVisible: false);
  }

  /// Go to a specific page
  void goToPage(int page) {
    if (page >= 0 && page < state.totalPages) {
      state = state.copyWith(currentPage: page);
    }
  }

  /// Go to the next page
  void nextPage() {
    if (state.currentPage < state.totalPages - 1) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  /// Go to the previous page
  void previousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  /// Update the total number of pages
  void updateTotalPages(int totalPages) {
    state = state.copyWith(totalPages: totalPages);
  }
}
