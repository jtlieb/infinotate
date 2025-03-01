/// Represents the state of an EPUB book
class EpubState {
  /// Path to the EPUB file
  final String? filePath;

  /// Whether the EPUB viewer is visible
  final bool isVisible;

  /// Current page index
  final int currentPage;

  /// Total number of pages
  final int totalPages;

  const EpubState({
    this.filePath,
    this.isVisible = false,
    this.currentPage = 0,
    this.totalPages = 0,
  });

  /// Create a copy of this state with the given fields replaced
  EpubState copyWith({
    String? filePath,
    bool? isVisible,
    int? currentPage,
    int? totalPages,
  }) {
    return EpubState(
      filePath: filePath ?? this.filePath,
      isVisible: isVisible ?? this.isVisible,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
