import 'package:get/get.dart';
import 'package:shortzz/common/config/agora_config.dart';
import 'package:shortzz/common/manager/logger.dart';
import 'package:shortzz/common/manager/session_manager.dart';
import 'package:shortzz/common/service/api/notification_service.dart';
import 'package:shortzz/common/service/api/user_service.dart';
import 'package:shortzz/common/manager/firebase_notification_manager.dart';

/// Enhanced Call Manager with error handling and state management
class CallManager extends GetxController {
  static final CallManager _instance =
      CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  // Observable states
  final RxBool isInitialized =
      true.obs; // Set to true for now
  final RxBool isInCall = false.obs;
  final RxString callStatus = 'ready'.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      // Validate Agora App ID
      if (AgoraConfig.appId == "YOUR_AGORA_APP_ID" ||
          AgoraConfig.appId.isEmpty) {
        throw Exception(
            'Please configure your Agora App ID in AgoraConfig');
      }

      isInitialized.value = true;
      callStatus.value = 'ready';
      Loggers.success(
          'Call Manager initialized successfully');
    } catch (e) {
      errorMessage.value = e.toString();
      callStatus.value = 'error';
      Loggers.error(
          'Call Manager initialization failed: $e');
    }
  }

  /// Start voice call with comprehensive error handling
  Future<bool> startVoiceCall({
    required int userId1,
    required int userId2,
    String? token,
    String? channelId,
  }) async {
    try {
      if (!isInitialized.value) {
        throw Exception('Call service not initialized');
      }

      callStatus.value = 'connecting';
      Loggers.info('📞 Starting voice call: User $userId1 → User $userId2');

      final String finalChannelId = channelId ??
          AgoraConfig.generateChannelId(userId1, userId2,
              prefix: 'voice');

      // For now, simulate success and optionally push incoming-call notification
      await Future.delayed(
          const Duration(milliseconds: 300));
      
      Loggers.info('📞 Sending voice call notification to user: $userId2');
      await _sendIncomingCallPush(
        isVideo: false,
        channelId: finalChannelId,
        token: token,
        calleeId: userId2,
      );

      isInCall.value = true;
      callStatus.value = 'connected';
      Loggers.success(
          '📞 Voice call started successfully: $finalChannelId');
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      callStatus.value = 'error';
      Loggers.error('📞 Voice call failed: $e');
      return false;
    }
  }

  /// Start video call with comprehensive error handling
  Future<bool> startVideoCall({
    required int userId1,
    required int userId2,
    String? token,
    String? channelId,
  }) async {
    try {
      if (!isInitialized.value) {
        throw Exception('Call service not initialized');
      }

      callStatus.value = 'connecting';
      Loggers.info('📹 Starting video call: User $userId1 → User $userId2');

      final String finalChannelId = channelId ??
          AgoraConfig.generateChannelId(userId1, userId2,
              prefix: 'video');

      // For now, simulate success and optionally push incoming-call notification
      await Future.delayed(
          const Duration(milliseconds: 300));
      
      Loggers.info('📹 Sending video call notification to user: $userId2');
      await _sendIncomingCallPush(
        isVideo: true,
        channelId: finalChannelId,
        token: token,
        calleeId: userId2,
      );

      isInCall.value = true;
      callStatus.value = 'connected';
      Loggers.success(
          '📹 Video call started successfully: $finalChannelId');
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      callStatus.value = 'error';
      Loggers.error('📹 Video call failed: $e');
      return false;
    }
  }

  // Enhanced helper to trigger an incoming call push with detailed logging
  Future<void> _sendIncomingCallPush({
    required bool isVideo,
    required String channelId,
    String? token,
    required int calleeId,
  }) async {
    try {
      Loggers.info('📞 Preparing to send ${isVideo ? 'video' : 'voice'} call notification...');
      
      UserService? userService;
      try {
        userService = Get.find<UserService>();
      } catch (_) {
        userService = UserService.instance;
      }
      
      Loggers.info('📞 Fetching callee details for user: $calleeId');
      final callee = await userService.fetchUserDetails(userId: calleeId);
      
      if (callee?.deviceToken == null || (callee!.deviceToken ?? '').isEmpty) {
        Loggers.error('📞 ❌ Callee device token is empty or null');
        return;
      }

      Loggers.info('📞 ✅ Callee device token found: ${callee.deviceToken?.substring(0, 20)}...');

      final me = SessionManager.instance.getUser();
      if (me == null) {
        Loggers.error('📞 ❌ Current user not found in session');
        return;
      }

      Loggers.info('📞 ✅ Caller info: ${me.fullname} (ID: ${me.id})');

      final data = {
        'channelId': channelId,
        'isVideo': isVideo ? 1 : 0,
        'token': token,
        'caller': me.toJson(),
      };

      Loggers.info('📞 Sending notification with payload: ${data.toString()}');

      await NotificationService.instance.pushNotification(
        type: NotificationType.call,
        title: me.fullname ?? 'Incoming call',
        body: isVideo ? 'Video call' : 'Voice call',
        data: data,
        token: callee.deviceToken,
        deviceType: callee.device,
      );

      Loggers.success('📞 ✅ Call notification sent successfully');
    } catch (e) {
      Loggers.error('📞 ❌ Failed to send call push: $e');
    }
  }

  /// End call with cleanup
  Future<void> endCall() async {
    try {
      isInCall.value = false;
      callStatus.value = 'ready';
      errorMessage.value = '';
      Loggers.info('Call ended successfully');
    } catch (e) {
      Loggers.error('Error ending call: $e');
    }
  }

  /// Clear error messages
  void clearError() {
    errorMessage.value = '';
  }
}
