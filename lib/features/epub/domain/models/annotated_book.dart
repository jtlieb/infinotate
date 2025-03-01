import 'epub_state.dart';
import '../../../../features/canvas/presentation/models/note.dart';

/// Represents an EPUB book with its annotations
class AnnotatedBook {
  /// Unique identifier for the book
  final String id;

  /// Path to the EPUB file
  final String filePath;

  /// Title of the book
  final String title;

  /// Author of the book
  final String author;

  /// Cover image path (if available)
  final String? coverPath;

  /// Last opened page
  final int lastPage;

  /// Total number of pages
  final int totalPages;

  /// Notes associated with this book
  final List<Note> notes;

  /// Last modified timestamp
  final DateTime lastModified;

  const AnnotatedBook({
    required this.id,
    required this.filePath,
    required this.title,
    required this.author,
    this.coverPath,
    this.lastPage = 0,
    this.totalPages = 0,
    this.notes = const [],
    required this.lastModified,
  });

  /// Create a copy of this book with the given fields replaced
  AnnotatedBook copyWith({
    String? id,
    String? filePath,
    String? title,
    String? author,
    String? coverPath,
    int? lastPage,
    int? totalPages,
    List<Note>? notes,
    DateTime? lastModified,
  }) {
    return AnnotatedBook(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      author: author ?? this.author,
      coverPath: coverPath ?? this.coverPath,
      lastPage: lastPage ?? this.lastPage,
      totalPages: totalPages ?? this.totalPages,
      notes: notes ?? this.notes,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  /// Create an EpubState from this book
  EpubState toEpubState({bool isVisible = false}) {
    return EpubState(
      filePath: filePath,
      isVisible: isVisible,
      currentPage: lastPage,
      totalPages: totalPages,
    );
  }

  /// Create an AnnotatedBook from an EpubState and notes
  static AnnotatedBook fromEpubState({
    required String id,
    required EpubState epubState,
    required String title,
    required String author,
    String? coverPath,
    List<Note> notes = const [],
  }) {
    return AnnotatedBook(
      id: id,
      filePath: epubState.filePath!,
      title: title,
      author: author,
      coverPath: coverPath,
      lastPage: epubState.currentPage,
      totalPages: epubState.totalPages,
      notes: notes,
      lastModified: DateTime.now(),
    );
  }
}
