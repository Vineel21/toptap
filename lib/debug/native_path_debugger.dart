import 'dart:io';
import 'package:flutter/services.dart';

/// Helper class to debug native Android video path communication
/// Add this to your camera controller to monitor path passing
class NativePathDebugger {
  /// Debug method to analyze stopRecording response
  static void debugStopRecordingResponse(
      dynamic result, String context) {
    print('\n🔧 NATIVE PATH DEBUGGER - $context');
    print('=' * 50);

    // Basic response info
    print('📦 Raw response: $result');
    print('📦 Response type: ${result.runtimeType}');

    if (result == null) {
      print('❌ CRITICAL: Response is null!');
      return;
    }

    // Analyze Map response
    if (result is Map) {
      final map = Map<String, dynamic>.from(result);
      print('✅ Response is a Map with ${map.length} keys');

      _debugMapContent(map);
    } else {
      print(
          '⚠️ Response is not a Map: ${result.runtimeType}');
      print('   Raw value: $result');
    }

    print('=' * 50);
  }

  /// Debug PlatformException errors
  static void debugPlatformException(
      PlatformException e, String context) {
    print('\n❌ PLATFORM EXCEPTION DEBUGGER - $context');
    print('=' * 50);

    print('🚨 Exception Code: ${e.code}');
    print('🚨 Exception Message: ${e.message}');
    print(
        '🚨 Exception Details Type: ${e.details?.runtimeType}');

    if (e.details is Map) {
      print('📦 Exception Details Map:');
      final details = Map<String, dynamic>.from(e.details);
      _debugMapContent(details);

      // Check for recovery information
      if (details.containsKey('fallbackPath')) {
        final fallbackPath = details['fallbackPath'];
        print('\n🔧 FALLBACK PATH ANALYSIS:');
        print('   Path: $fallbackPath');
        print('   Type: ${fallbackPath.runtimeType}');

        if (fallbackPath is String &&
            fallbackPath.isNotEmpty) {
          _debugFilePath(fallbackPath);
        }
      }

      if (details.containsKey('canAttemptRecovery')) {
        print(
            '🔧 Recovery possible: ${details['canAttemptRecovery']}');
      }
    } else {
      print('📦 Exception Details: ${e.details}');
    }

    print('=' * 50);
  }

  /// Debug Map content in detail
  static void _debugMapContent(Map<String, dynamic> map) {
    print('\n📋 MAP CONTENT ANALYSIS:');

    // Critical path-related fields
    final pathFields = [
      'path',
      'filePath',
      'videoPath',
      'fallbackPath'
    ];
    final statusFields = [
      'success',
      'fileExists',
      'mediaRecorderStopped'
    ];
    final sizeFields = [
      'fileSize',
      'durationMs',
      'width',
      'height'
    ];
    final debugFields = [
      'verificationAttempts',
      'canAttemptRecovery'
    ];

    print('\n🛤️ PATH FIELDS:');
    for (final field in pathFields) {
      if (map.containsKey(field)) {
        final value = map[field];
        print('   ✅ $field: $value (${value.runtimeType})');
        if (value is String && value.isNotEmpty) {
          _debugFilePath(value);
        }
      } else {
        print('   ❌ Missing: $field');
      }
    }

    print('\n📊 STATUS FIELDS:');
    for (final field in statusFields) {
      if (map.containsKey(field)) {
        final value = map[field];
        print('   ✅ $field: $value (${value.runtimeType})');
      } else {
        print('   ❌ Missing: $field');
      }
    }

    print('\n📏 SIZE/DURATION FIELDS:');
    for (final field in sizeFields) {
      if (map.containsKey(field)) {
        final value = map[field];
        print('   ✅ $field: $value (${value.runtimeType})');

        // Convert fileSize to readable format
        if (field == 'fileSize' && value is num) {
          final kb = (value / 1024).round();
          final mb =
              (value / (1024 * 1024)).toStringAsFixed(2);
          print('      📊 Size: $kb KB / $mb MB');
        }
      } else {
        print('   ❌ Missing: $field');
      }
    }

    print('\n🐛 DEBUG FIELDS:');
    for (final field in debugFields) {
      if (map.containsKey(field)) {
        final value = map[field];
        print('   ✅ $field: $value (${value.runtimeType})');
      } else {
        print('   ❌ Missing: $field');
      }
    }

    // Show any unexpected fields
    final allKnownFields = [
      ...pathFields,
      ...statusFields,
      ...sizeFields,
      ...debugFields
    ];
    final unknownFields = map.keys
        .where((key) => !allKnownFields.contains(key))
        .toList();

    if (unknownFields.isNotEmpty) {
      print('\n❓ UNKNOWN FIELDS:');
      for (final field in unknownFields) {
        print(
            '   🔍 $field: ${map[field]} (${map[field].runtimeType})');
      }
    }
  }

  /// Debug file path in detail
  static void _debugFilePath(String path) {
    print('      🔍 PATH DETAILS:');
    print('         📍 Full: $path');
    print(
        '         📂 Dir: ${path.substring(0, path.lastIndexOf('/'))}');
    print(
        '         📄 File: ${path.substring(path.lastIndexOf('/') + 1)}');

    try {
      final file = File(path);
      final exists = file.existsSync();
      print('         📁 Exists: $exists');

      if (exists) {
        final size = file.lengthSync();
        final kb = (size / 1024).round();
        final lastModified = file.lastModifiedSync();
        final age = DateTime.now().difference(lastModified);

        print('         📊 Size: $size bytes ($kb KB)');
        print(
            '         🕒 Modified: ${age.inSeconds}s ago');

        if (size > 1024) {
          print('         ✅ Size valid for video');
        } else {
          print('         ⚠️ Size too small for video');
        }
      }
    } catch (e) {
      print('         ❌ File check error: $e');
    }
  }

  /// Comprehensive method to debug the entire path extraction flow
  static void debugPathExtractionFlow(
    dynamic originalResult,
    String? extractedPath,
    String? validatedPath,
    String? fallbackPath,
  ) {
    print('\n🔄 PATH EXTRACTION FLOW DEBUGGER');
    print('=' * 60);

    print('1️⃣ ORIGINAL NATIVE RESULT:');
    debugStopRecordingResponse(
        originalResult, 'Path Extraction Input');

    print('\n2️⃣ EXTRACTED PATH:');
    if (extractedPath != null) {
      print('   ✅ Extracted: $extractedPath');
      _debugFilePath(extractedPath);
    } else {
      print('   ❌ Extraction failed - null result');
    }

    print('\n3️⃣ VALIDATED PATH:');
    if (validatedPath != null) {
      print('   ✅ Validated: $validatedPath');
      if (validatedPath != extractedPath) {
        print('   🔄 Path changed during validation');
        _debugFilePath(validatedPath);
      } else {
        print('   ✅ Path unchanged during validation');
      }
    } else {
      print('   ❌ Validation failed - null result');
    }

    print('\n4️⃣ FALLBACK PATH:');
    if (fallbackPath != null) {
      print('   🔄 Fallback used: $fallbackPath');
      _debugFilePath(fallbackPath);
    } else {
      print('   ✅ No fallback needed');
    }

    print('\n🎯 FINAL ANALYSIS:');
    if (validatedPath != null && validatedPath.isNotEmpty) {
      print('   ✅ SUCCESS: Valid path obtained');
      print('   📍 Final path: $validatedPath');
    } else if (fallbackPath != null &&
        fallbackPath.isNotEmpty) {
      print('   🔄 PARTIAL: Fallback path used');
      print('   📍 Fallback path: $fallbackPath');
    } else {
      print('   ❌ FAILURE: No valid path obtained');
    }

    print('=' * 60);
  }
}

/// Extension to add debugging to existing camera controller methods
extension CameraControllerDebugger on dynamic {
  void debugNativeResponse(String context) {
    NativePathDebugger.debugStopRecordingResponse(
        this, context);
  }
}
