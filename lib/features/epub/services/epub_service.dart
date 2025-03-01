import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';

/// Service for handling EPUB file operations
class EpubService {
  /// Open an EPUB file using the vocsy_epub_viewer
  static Future<void> openEpub(String filePath) async {
    final File file = File(filePath);

    if (await file.exists()) {
      VocsyEpub.setConfig(
        themeColor: Colors.blue[800]!,
        identifier: "iosBook",
        scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
        allowSharing: true,
        enableTts: true,
      );

      VocsyEpub.open(filePath);
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
