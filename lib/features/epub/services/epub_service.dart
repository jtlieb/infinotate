import 'dart:io';
import 'package:flutter/material.dart';
import 'flutter_epub_viewer_service.dart';

/// Service for handling EPUB file operations
/// This is a wrapper around FlutterEpubViewerService for backward compatibility
class EpubService {
  /// Open an EPUB file using the flutter_epub_viewer
  static Future<void> openEpub(String filePath) async {
    final File file = File(filePath);

    if (await file.exists()) {
      // Configure the viewer
      await FlutterEpubViewerService.configureViewer(
        themeColor: Colors.blue[800]!,
        identifier: "iosBook",
        scrollDirection: DocScrollDirection.allDirections,
        allowSharing: true,
        enableTts: true,
      );

      // Open the file
      await FlutterEpubViewerService.openFile(filePath);
    } else {
      throw Exception('EPUB file not found: $filePath');
    }
  }

  /// Get a list of sample EPUB files for testing
  static List<String> getSampleEpubFiles() {
    // In a real app, you would scan a directory or fetch from a database
    return [
      '/path/to/sample1.epub',
      '/path/to/sample2.epub',
      '/path/to/sample3.epub',
    ];
  }
}
