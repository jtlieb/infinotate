import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

// Define our own enum that matches the package's enum
enum DocScrollDirection { allDirections, horizontal, vertical }

// Convert our enum to the package's enum
EpubFlow _convertToPackageFlow(DocScrollDirection direction) {
  switch (direction) {
    case DocScrollDirection.horizontal:
      return EpubFlow.paginated;
    case DocScrollDirection.vertical:
      return EpubFlow.scrolled;
    case DocScrollDirection.allDirections:
      return EpubFlow.paginated; // Default to paginated for allDirections
  }
}

/// A service that wraps the flutter_epub_viewer package to handle the async methods properly
class FlutterEpubViewerService {
  // Controller for the EPUB viewer
  static EpubController? _epubController;

  // Source for the EPUB file
  static EpubSource? _epubSource;

  // Flag to track if the EPUB viewer is currently open
  static bool _isViewerOpen = false;

  // Get the current state of the EPUB viewer
  static bool get isViewerOpen => _isViewerOpen;

  /// Configure the EPUB viewer
  static Future<void> configureViewer({
    required Color themeColor,
    String identifier = 'book',
    bool nightMode = false,
    DocScrollDirection scrollDirection = DocScrollDirection.allDirections,
    bool allowSharing = false,
    bool enableTts = false,
  }) async {
    try {
      // Initialize the controller if it doesn't exist
      _epubController ??= EpubController();

      // Store the flow for later use
      final flow = _convertToPackageFlow(scrollDirection);

      // Apply the flow configuration to the controller
      if (_epubController != null) {
        await _epubController!.setFlow(flow: flow);
      }

      // Add a small delay to ensure the configuration is applied
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('Error configuring EPUB viewer: $e');
      rethrow;
    }
  }

  /// Open an EPUB file from the device
  static Future<void> openFile(String filePath) async {
    try {
      if (!File(filePath).existsSync()) {
        throw Exception('File not found: $filePath');
      }

      // Initialize the controller if it doesn't exist
      _epubController ??= EpubController();

      // Create the source from file
      _epubSource = EpubSource.fromFile(File(filePath));

      // Mark as open
      _isViewerOpen = true;

      // Add a small delay to ensure the file is opened
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('Error opening EPUB file: $e');
      rethrow;
    }
  }

  /// Open an EPUB file from the assets
  static Future<void> openAsset(String assetPath) async {
    try {
      // Initialize the controller if it doesn't exist
      _epubController ??= EpubController();

      // Create the source from asset
      _epubSource = EpubSource.fromAsset(assetPath);

      // Mark as open
      _isViewerOpen = true;

      // Add a small delay to ensure the asset is opened
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('Error opening EPUB asset: $e');
      rethrow;
    }
  }

  /// Close the EPUB viewer if it's open
  static Future<void> closeViewer() async {
    try {
      if (_isViewerOpen) {
        // Reset the state
        _isViewerOpen = false;
      }
    } catch (e) {
      debugPrint('Error closing EPUB viewer: $e');
      rethrow;
    }
  }

  /// Check if the EPUB viewer is supported on the current platform
  static Future<bool> isSupported() async {
    try {
      // flutter_epub_viewer should work on all platforms
      return true;
    } catch (e) {
      debugPrint('Error checking EPUB viewer support: $e');
      return false;
    }
  }

  /// Get the EPUB controller
  static EpubController? getController() {
    return _epubController;
  }

  /// Get the EPUB source
  static EpubSource? getSource() {
    return _epubSource;
  }

  /// Get a new source for an asset path
  static EpubSource getSourceForAsset(String assetPath) {
    return EpubSource.fromAsset(assetPath);
  }

  /// Get a new source for a file path
  static EpubSource getSourceForFile(String filePath) {
    return EpubSource.fromFile(File(filePath));
  }
}
