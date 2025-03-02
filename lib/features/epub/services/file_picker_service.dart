import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Service for picking files from the device
class FilePickerService {
  // Flag to track initialization attempts
  static bool _hasAttemptedInit = false;
  static Completer<void>? _initCompleter;
  static bool _isPickerWorking =
      false; // Default to false until proven otherwise

  /// Initialize the FilePicker
  static Future<void> _ensureInitialized() async {
    // If we're already initializing, wait for that to complete
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    // If we've already attempted initialization, don't try again
    if (_hasAttemptedInit) {
      return;
    }

    _initCompleter = Completer<void>();
    _hasAttemptedInit = true;

    try {
      // We won't actually initialize here, we'll just set the flag
      // and let the actual file picking operation handle initialization
      _isPickerWorking = true;
      debugPrint(
        'FilePicker initialization skipped, will initialize on first use',
      );
    } catch (e) {
      debugPrint('FilePicker initialization attempt failed: $e');
      _isPickerWorking = false;

      // Log specific error types for debugging
      if (e.toString().contains('MissingPluginException')) {
        debugPrint(
          'FilePicker plugin is not properly registered. This may require a full app restart.',
        );
      } else if (e.toString().contains('LateInitializationError')) {
        debugPrint(
          'FilePicker not properly initialized. This is a common issue on first run.',
        );
      }
    } finally {
      _initCompleter!.complete();
      _initCompleter = null;
    }
  }

  /// Check if the FilePicker is working properly
  static Future<bool> isPickerWorking() async {
    await _ensureInitialized();
    return _isPickerWorking;
  }

  /// Pick an EPUB file from the device
  static Future<String?> pickEpubFile() async {
    // Ensure FilePicker is initialized before use
    await _ensureInitialized();

    // If we know the picker isn't working, don't even try
    if (!_isPickerWorking) {
      debugPrint(
        'FilePicker is known to be not working, using fallback mechanism',
      );
      throw Exception('FilePicker is not properly initialized on this device');
    }

    try {
      // Use a more robust approach with better error handling
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
        dialogTitle: 'Select an EPUB book',
        allowMultiple: false,
      );

      // Check if a file was selected and has a valid path
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // For web, we don't have a path
        if (kIsWeb) {
          // Handle web case if needed
          return null;
        }

        // For mobile platforms, return the path
        return file.path;
      }
    } catch (e) {
      debugPrint('Error picking EPUB file: $e');
      // If we get an error, mark the picker as not working for future calls
      _isPickerWorking = false;
      rethrow; // Use rethrow instead of throw e
    }

    return null; // Return null if no file was selected or an error occurred
  }

  /// Check if a file path is an asset path
  static bool isAssetPath(String? path) {
    if (path == null) return false;
    return path.startsWith('assets/');
  }
}
