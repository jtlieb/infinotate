import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../epub/providers/annotated_book_providers.dart';
import '../../../epub/services/file_picker_service.dart';
import '../../../epub/domain/models/annotated_book.dart';
import 'unified_reader_page.dart';

/// The main home page of the application
/// Displays a list of books and allows creating new notes
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(annotatedBooksProvider);

    return Scaffold(
      appBar: null, // Remove the app bar
      body: SafeArea(
        child: Column(
          children: [
            // Header with Infinotate title and add button
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 16.0, 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Infinotate title in Samsung Messages style
                  Text(
                    'Infinotate',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  // More prominent Add button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(
                        230,
                      ), // Using withAlpha for better precision
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 5.0,
                          spreadRadius: 0.0,
                          offset: const Offset(-2.0, 0.0),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      icon: Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        'Add Book',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => _addNewBook(context, ref),
                    ),
                  ),
                ],
              ),
            ),

            // Book list
            Expanded(
              child:
                  books.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(128),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No books in your library',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add an EPUB book to get started',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
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
                                    : Container(
                                      width: 40,
                                      height: 60,
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.book,
                                        color: Colors.grey,
                                      ),
                                    ),
                            title: Text(book.title),
                            subtitle: Text(
                              '${book.author} • ${book.notes.length} notes',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              // Navigate to the unified reader page with this book
                              _openBookReader(context, ref, book);
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      // Remove the floating action button
    );
  }

  /// Add a new book using the file picker
  Future<void> _addNewBook(BuildContext context, WidgetRef ref) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening file picker...'),
        duration: Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Check if FilePicker is working
    final isPickerWorking = await FilePickerService.isPickerWorking();
    if (!isPickerWorking && context.mounted) {
      // If FilePicker is not working, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File picker is not available on this device.'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String? filePath;

    try {
      filePath = await FilePickerService.pickEpubFile();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file picker: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      if (filePath != null) {
        // Create a new annotated book
        final newBook = AnnotatedBook(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          filePath: filePath,
          title: _extractTitleFromPath(filePath),
          author: 'Unknown Author', // In a real app, extract from EPUB metadata
          lastModified: DateTime.now(),
        );

        // Add the book to the library
        ref.read(annotatedBooksProvider.notifier).addBook(newBook);

        // Navigate to the unified reader page with this book
        _openBookReader(context, ref, newBook);
      } else {
        // Show a message if no file was selected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No EPUB file selected'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Extract a title from the file path
  String _extractTitleFromPath(String filePath) {
    final fileName = filePath.split('/').last;
    final fileNameWithoutExtension = fileName.split('.').first;
    return fileNameWithoutExtension.replaceAll('_', ' ');
  }

  /// Open the book reader with the selected book
  void _openBookReader(
    BuildContext context,
    WidgetRef ref,
    AnnotatedBook book,
  ) {
    // Navigate to the unified reader page with this book
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedReaderPage(initialBook: book),
      ),
    );
  }
}
