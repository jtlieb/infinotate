import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/epub_providers.dart';
import '../../providers/annotated_book_providers.dart';
import '../../services/file_picker_service.dart';
import '../../domain/models/annotated_book.dart';

/// A page that displays a list of EPUB files
class EpubLibraryPage extends ConsumerWidget {
  const EpubLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(annotatedBooksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('EPUB Library')),
      body:
          books.isEmpty
              ? const Center(
                child: Text(
                  'No books in your library. Add one to get started!',
                ),
              )
              : ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return ListTile(
                    leading:
                        book.coverPath != null
                            ? Image.file(
                              width: 40,
                              height: 60,
                              fit: BoxFit.cover,
                              File(book.coverPath!),
                            )
                            : const Icon(Icons.book, size: 40),
                    title: Text(book.title),
                    subtitle: Text(book.author),
                    trailing: Text('${book.notes.length} notes'),
                    onTap: () {
                      // Set the current book
                      ref.read(currentBookProvider.notifier).setBook(book);

                      // Update the EPUB state
                      ref
                          .read(epubStateProvider.notifier)
                          .loadEpub(book.filePath);

                      // Navigate back to the canvas
                      Navigator.pop(context);
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final filePath = await FilePickerService.pickEpubFile();

          if (filePath != null) {
            // Create a new annotated book
            final newBook = AnnotatedBook(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              filePath: filePath,
              title: _extractTitleFromPath(filePath),
              author:
                  'Unknown Author', // In a real app, extract this from the EPUB metadata
              lastModified: DateTime.now(),
            );

            // Add the book to the library
            ref.read(annotatedBooksProvider.notifier).addBook(newBook);

            // Set as current book
            ref.read(currentBookProvider.notifier).setBook(newBook);

            // Load the EPUB
            ref.read(epubStateProvider.notifier).loadEpub(filePath);

            // Navigate back to the canvas
            if (context.mounted) {
              Navigator.pop(context);
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Extract a title from the file path
  String _extractTitleFromPath(String filePath) {
    final fileName = filePath.split('/').last;
    final fileNameWithoutExtension = fileName.split('.').first;
    return fileNameWithoutExtension.replaceAll('_', ' ');
  }
}
