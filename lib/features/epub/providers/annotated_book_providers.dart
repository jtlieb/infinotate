import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../domain/models/annotated_book.dart';
import '../../canvas/presentation/models/note.dart';

/// Provider for the list of annotated books
final annotatedBooksProvider =
    StateNotifierProvider<AnnotatedBooksNotifier, List<AnnotatedBook>>(
      (ref) => AnnotatedBooksNotifier(),
    );

/// Provider for the currently active book
final currentBookProvider =
    StateNotifierProvider<CurrentBookNotifier, AnnotatedBook?>(
      (ref) => CurrentBookNotifier(),
    );

/// Notifier for the list of annotated books
class AnnotatedBooksNotifier extends StateNotifier<List<AnnotatedBook>> {
  AnnotatedBooksNotifier()
    : super([
        // Add a sample book by default
        AnnotatedBook(
          id: 'sample-book',
          filePath: 'assets/books/pride_and_prejudice.epub',
          title: 'Pride and Prejudice',
          author: 'Jane Austen',
          lastModified: DateTime.now(),
          totalPages: 345,
        ),
      ]);

  /// Add a new book to the library
  void addBook(AnnotatedBook book) {
    state = [...state, book];
    developer.log('DEBUG: Added book ${book.id} - ${book.title}');
  }

  /// Update an existing book
  void updateBook(AnnotatedBook updatedBook) {
    state = [
      for (final book in state)
        if (book.id == updatedBook.id) updatedBook else book,
    ];
    developer.log(
      'DEBUG: Updated book ${updatedBook.id} - ${updatedBook.title}',
    );
  }

  /// Remove a book from the library
  void removeBook(String bookId) {
    state = state.where((book) => book.id != bookId).toList();
    developer.log('DEBUG: Removed book $bookId');
  }

  /// Add a note to a book
  void addNoteToBook(String bookId, Note note) {
    state = [
      for (final book in state)
        if (book.id == bookId)
          book.copyWith(
            notes: [...book.notes, note],
            lastModified: DateTime.now(),
          )
        else
          book,
    ];
    developer.log('DEBUG: Added note ${note.id} to book $bookId');
  }

  /// Update a note in a book
  void updateNoteInBook(String bookId, Note updatedNote) {
    state = [
      for (final book in state)
        if (book.id == bookId)
          book.copyWith(
            notes: [
              for (final note in book.notes)
                if (note.id == updatedNote.id) updatedNote else note,
            ],
            lastModified: DateTime.now(),
          )
        else
          book,
    ];
    developer.log('DEBUG: Updated note ${updatedNote.id} in book $bookId');
  }

  /// Remove a note from a book
  void removeNoteFromBook(String bookId, String noteId) {
    state = [
      for (final book in state)
        if (book.id == bookId)
          book.copyWith(
            notes: book.notes.where((note) => note.id != noteId).toList(),
            lastModified: DateTime.now(),
          )
        else
          book,
    ];
    developer.log('DEBUG: Removed note $noteId from book $bookId');
  }

  /// Update the last page of a book
  void updateLastPage(String bookId, int lastPage) {
    state = [
      for (final book in state)
        if (book.id == bookId)
          book.copyWith(lastPage: lastPage, lastModified: DateTime.now())
        else
          book,
    ];
    developer.log('DEBUG: Updated last page to $lastPage for book $bookId');
  }
}

/// Notifier for the currently active book
class CurrentBookNotifier extends StateNotifier<AnnotatedBook?> {
  CurrentBookNotifier() : super(null);

  /// Set the current book
  void setBook(AnnotatedBook book) {
    state = book;
    developer.log('DEBUG: Set current book to ${book.id} - ${book.title}');
  }

  /// Clear the current book
  void clearBook() {
    state = null;
    developer.log('DEBUG: Cleared current book');
  }

  /// Add a note to the current book
  void addNote(Note note) {
    if (state != null) {
      state = state!.copyWith(
        notes: [...state!.notes, note],
        lastModified: DateTime.now(),
      );
      developer.log(
        'DEBUG: Added note ${note.id} to current book ${state!.id}',
      );
    }
  }

  /// Update a note in the current book
  void updateNote(Note updatedNote) {
    if (state != null) {
      state = state!.copyWith(
        notes: [
          for (final note in state!.notes)
            if (note.id == updatedNote.id) updatedNote else note,
        ],
        lastModified: DateTime.now(),
      );
      developer.log(
        'DEBUG: Updated note ${updatedNote.id} in current book ${state!.id}',
      );
    }
  }

  /// Remove a note from the current book
  void removeNote(String noteId) {
    if (state != null) {
      state = state!.copyWith(
        notes: state!.notes.where((note) => note.id != noteId).toList(),
        lastModified: DateTime.now(),
      );
      developer.log(
        'DEBUG: Removed note $noteId from current book ${state!.id}',
      );
    }
  }

  /// Update the last page of the current book
  void updateLastPage(int lastPage) {
    if (state != null) {
      state = state!.copyWith(lastPage: lastPage, lastModified: DateTime.now());
      developer.log(
        'DEBUG: Updated last page to $lastPage for current book ${state!.id}',
      );
    }
  }
}
