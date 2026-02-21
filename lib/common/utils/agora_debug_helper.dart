import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

/// Comprehensive debugging helper for Agora implementation
class AgoraDebugHelper {
  static bool _debugEnabled = true;

  /// Enable/disable debug logging
  static void enableDebug(bool enabled) {
    _debugEnabled = enabled;
  }

  /// Debug print with timestamp and emoji
  static void debugPrint(String message,
      {String emoji = "🔍"}) {
    if (_debugEnabled && kDebugMode) {
      String timestamp =
          DateTime.now().toString().substring(11, 23);
      print('[$timestamp] $emoji $message');
    }
  }

  /// Log engine state
  static void logEngineState(
      RtcEngine? engine, bool isInitialized) {
    debugPrint('=== AGORA ENGINE STATE ===', emoji: '🔧');
    debugPrint(
        'Engine Instance: ${engine != null ? "Created" : "NULL"}');
    debugPrint('Is Initialized: $isInitialized');
    debugPrint('========================');
  }

  /// Log call state
  static void logCallState({
    required bool isInCall,
    required bool isVideoCall,
    required bool isMuted,
    required bool isVideoEnabled,
    required bool isSpeakerEnabled,
    int? remoteUid,
    String? channelId,
  }) {
    debugPrint('=== CALL STATE ===', emoji: '📞');
    debugPrint('In Call: $isInCall');
    debugPrint('Video Call: $isVideoCall');
    debugPrint('Muted: $isMuted');
    debugPrint('Video Enabled: $isVideoEnabled');
    debugPrint('Speaker Enabled: $isSpeakerEnabled');
    debugPrint('Remote UID: ${remoteUid ?? "None"}');
    debugPrint('Channel ID: ${channelId ?? "None"}');
    debugPrint('==================');
  }

  /// Log permission status
  static Future<void> logPermissionStatus(
      {bool isVideoCall = false}) async {
    debugPrint('=== PERMISSION STATUS ===', emoji: '🔐');

    try {
      PermissionStatus micStatus =
          await Permission.microphone.status;
      debugPrint('Microphone: ${micStatus.name}');

      if (isVideoCall) {
        PermissionStatus cameraStatus =
            await Permission.camera.status;
        debugPrint('Camera: ${cameraStatus.name}');
      }

      debugPrint('========================');
    } catch (e) {
      debugPrint('Error checking permissions: $e',
          emoji: '❌');
    }
  }

  /// Validate App ID format
  static bool validateAppId(String appId) {
    debugPrint('=== APP ID VALIDATION ===', emoji: '🔑');
    debugPrint('App ID: $appId');
    debugPrint('Length: ${appId.length}');

    bool isValid = true;
    List<String> issues = [];

    if (appId.isEmpty) {
      issues.add('App ID is empty');
      isValid = false;
    }

    if (appId == "YOUR_AGORA_APP_ID") {
      issues.add('App ID is placeholder');
      isValid = false;
    }

    if (appId.length < 10) {
      issues.add(
          'App ID too short (should be 32 characters)');
      isValid = false;
    }

    if (appId.length != 32) {
      issues.add(
          'App ID wrong length (should be 32 characters)');
      isValid = false;
    }

    if (!RegExp(r'^[a-fA-F0-9]+$').hasMatch(appId)) {
      issues.add(
          'App ID should only contain hexadecimal characters');
      isValid = false;
    }

    if (issues.isNotEmpty) {
      debugPrint('❌ VALIDATION FAILED:', emoji: '❌');
      for (String issue in issues) {
        debugPrint('  - $issue', emoji: '❌');
      }
    } else {
      debugPrint('✅ App ID validation passed', emoji: '✅');
    }

    debugPrint('========================');
    return isValid;
  }

  /// Log network information
  static void logNetworkInfo(String networkType,
      bool hasInternet, bool canReachAgora) {
    debugPrint('=== NETWORK INFO ===', emoji: '🌐');
    debugPrint('Network Type: $networkType');
    debugPrint('Has Internet: $hasInternet');
    debugPrint('Can Reach Agora: $canReachAgora');
    debugPrint('===================');
  }

  /// Log error with context
  static void logError(dynamic error, String context,
      {StackTrace? stackTrace}) {
    debugPrint('=== ERROR OCCURRED ===', emoji: '💥');
    debugPrint('Context: $context');
    debugPrint('Error: $error');
    debugPrint('Error Type: ${error.runtimeType}');
    if (stackTrace != null) {
      debugPrint(
          'Stack Trace: ${stackTrace.toString().split('\n').take(5).join('\n')}');
    }
    debugPrint('=====================');
  }

  /// Check if all requirements are met for calling
  static Future<Map<String, bool>> checkCallRequirements({
    required String appId,
    required String channelId,
    required bool isVideoCall,
    String? token,
  }) async {
    debugPrint('=== CALL REQUIREMENTS CHECK ===',
        emoji: '📋');

    Map<String, bool> requirements = {};

    // 1. App ID validation
    requirements['valid_app_id'] = validateAppId(appId);

    // 2. Channel ID validation
    requirements['valid_channel_id'] =
        channelId.isNotEmpty && channelId.length <= 64;
    debugPrint(
        'Channel ID Valid: ${requirements['valid_channel_id']} ($channelId)');

    // 3. Permission check
    try {
      PermissionStatus micStatus =
          await Permission.microphone.status;
      requirements['microphone_permission'] =
          micStatus == PermissionStatus.granted;

      if (isVideoCall) {
        PermissionStatus cameraStatus =
            await Permission.camera.status;
        requirements['camera_permission'] =
            cameraStatus == PermissionStatus.granted;
      } else {
        requirements['camera_permission'] =
            true; // Not needed for audio call
      }
    } catch (e) {
      debugPrint('Permission check error: $e', emoji: '❌');
      requirements['microphone_permission'] = false;
      requirements['camera_permission'] = false;
    }

    // 4. Token validation (if provided)
    if (token != null && token.isNotEmpty) {
      requirements['valid_token'] =
          token.length > 10; // Basic check
      debugPrint(
          'Token Valid: ${requirements['valid_token']} (Length: ${token.length})');
    } else {
      requirements['valid_token'] =
          true; // Valid only when Agora project allows app-id-only auth
      debugPrint(
          'No token provided (OK only if Primary Certificate is disabled in Agora Console)');
    }

    debugPrint('=== REQUIREMENTS SUMMARY ===');
    requirements.forEach((key, value) {
      debugPrint('${value ? "✅" : "❌"} $key: $value');
    });

    bool allMet = requirements.values.every((v) => v);
    debugPrint('🎯 All Requirements Met: $allMet');
    debugPrint('==============================');

    return requirements;
  }

  /// Log channel join attempt
  static void logJoinChannelAttempt({
    required String channelId,
    String? token,
    required int uid,
    required bool isVideoCall,
  }) {
    debugPrint('=== JOIN CHANNEL ATTEMPT ===', emoji: '🚀');
    debugPrint('Channel ID: $channelId');
    debugPrint(
        'Token: ${token?.isEmpty ?? true ? "None" : "Provided"}');
    debugPrint('UID: $uid');
    debugPrint(
        'Call Type: ${isVideoCall ? "Video" : "Audio"}');
    debugPrint('===========================');
  }

  /// Log video views state
  static void logVideoViewsState(bool hasLocalView,
      bool hasRemoteView, int? remoteUid) {
    debugPrint('=== VIDEO VIEWS STATE ===', emoji: '📹');
    debugPrint('Has Local View: $hasLocalView');
    debugPrint('Has Remote View: $hasRemoteView');
    debugPrint('Remote UID: ${remoteUid ?? "None"}');
    debugPrint('========================');
  }
}
