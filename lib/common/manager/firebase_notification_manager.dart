import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shortzz/common/controller/base_controller.dart';
import 'package:shortzz/common/manager/call_notification_manager.dart';
import 'package:shortzz/common/manager/logger.dart';
import 'package:shortzz/common/manager/session_manager.dart'
    show SessionManager;
import 'package:shortzz/common/service/api/notification_service.dart';
import 'package:shortzz/common/service/api/post_service.dart';
import 'package:shortzz/common/service/api/user_service.dart';
import 'package:shortzz/common/service/navigation/navigate_with_controller.dart';
import 'package:shortzz/languages/dynamic_translations.dart';
import 'package:shortzz/languages/languages_keys.dart';
import 'package:shortzz/model/chat/chat_thread.dart';
import 'package:shortzz/model/livestream/livestream.dart';
import 'package:shortzz/model/post_story/post_model.dart';
import 'package:shortzz/screen/chat_screen/chat_screen.dart';
import 'package:shortzz/model/user_model/user_model.dart';
import 'package:shortzz/screen/call_screen/incoming_call_screen.dart';
import 'package:shortzz/screen/chat_screen/chat_screen_controller.dart';
import 'package:shortzz/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:shortzz/screen/live_stream/livestream_screen/audience/live_stream_audience_screen.dart';
import 'package:shortzz/screen/live_stream/livestream_screen/host/livestream_host_screen.dart';
import 'package:shortzz/screen/post_screen/single_post_screen.dart';
import 'package:shortzz/screen/reels_screen/reels_screen.dart';
import 'package:shortzz/utilities/const_res.dart';
import 'package:shortzz/utilities/firebase_const.dart';

@pragma('vm:entry-point')
void notificationTapBackground(
    NotificationResponse notificationResponse) {
  print('NOTIFICATION TAP ON BACKGROUND');
  if (notificationResponse.payload != null) {
    // Handle call actions from background notifications
    if (notificationResponse.actionId == 'ACCEPT_CALL') {
      FirebaseNotificationManager.instance
          ._handleCallAction(notificationResponse.payload!,
              accept: true);
      return;
    }
    if (notificationResponse.actionId == 'DECLINE_CALL') {
      FirebaseNotificationManager.instance
          ._handleCallAction(notificationResponse.payload!,
              accept: false);
      return;
    }

    // Regular notification handling
    FirebaseNotificationManager.instance
        .handleNotification(notificationResponse.payload!);
  }
}

class FirebaseNotificationManager {
  FirebaseNotificationManager._() {
    init();
  }

  static final instance = FirebaseNotificationManager._();

  FirebaseMessaging firebaseMessaging =
      FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin
      flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  RxString notificationPayload = ''.obs;
  AndroidNotificationChannel channel =
      const AndroidNotificationChannel(
          'TopTap', // id
          'TopTap', // title
          playSound: true,
          enableLights: true,
          enableVibration: true,
          showBadge: false,
          importance: Importance.max);

  String? notificationId;

  void init() async {
    Loggers.info(
        '🔔 Initializing Firebase Notification Manager...');

    // Request permissions with detailed logging
    if (Platform.isAndroid) {
      Loggers.info(
          '🔔 Requesting Android notification permissions...');
      final granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      Loggers.info(
          '🔔 Android notification permission: ${(granted == true) ? "✅ GRANTED" : "❌ DENIED"}');
    } else {
      Loggers.info(
          '🔔 Requesting iOS notification permissions...');
      final iosGranted =
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(
                  alert: true, sound: true);
      Loggers.info(
          '🔔 iOS notification permission: ${(iosGranted == true) ? "✅ GRANTED" : "❌ DENIED"}');

      final firebaseSettings =
          await firebaseMessaging.requestPermission(
              alert: true, badge: false, sound: true);
      Loggers.info(
          '🔔 Firebase permission status: ${firebaseSettings.authorizationStatus}');
    }

    await subscribeToTopic();

    var initializationSettingsAndroid =
        const AndroidInitializationSettings(
            '@mipmap/ic_launcher');

    var initializationSettingsIOS =
        const DarwinInitializationSettings(
            defaultPresentAlert: true,
            defaultPresentSound: true,
            defaultPresentBadge: false);

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS);

    // Handling notification taps
    flutterLocalNotificationsPlugin
        .initialize(initializationSettings,
            onDidReceiveNotificationResponse:
                (NotificationResponse response) {
      Loggers.info(
          '🔔 Notification tapped: ${response.payload}');

      final payload = response.payload;
      if (payload == null) return;

      // Handle accept/decline actions for call notifications
      if (response.actionId == 'ACCEPT_CALL') {
        Loggers.info('📞 Call ACCEPTED from notification');
        _handleCallAction(payload, accept: true);
        return;
      }
      if (response.actionId == 'DECLINE_CALL') {
        Loggers.info('📞 Call DECLINED from notification');
        _handleCallAction(payload, accept: false);
        return;
      }

      // Regular notification handling
      notificationPayload.value = payload;
      handleNotification(payload);
    },
            onDidReceiveBackgroundNotificationResponse:
                notificationTapBackground);

    FirebaseMessaging.onMessage
        .listen((RemoteMessage message) async {
      Loggers.info(
          '🔔 Received foreground message: ${message.messageId}');
      Loggers.info('🔔 Message data: ${message.data}');
      Loggers.info(
          '🔔 Notification type: ${message.data['type']}');

      // If Notification has gone twice
      if (notificationId == message.messageId) {
        Loggers.warning(
            '🔔 Duplicate notification ignored: ${message.messageId}');
        return;
      }
      notificationId = message.messageId;

      String data = message.data['notification_data'] ?? '';

      // Handle incoming calls with enhanced notification manager
      if (message.data['type'] ==
          NotificationType.call.type) {
        Loggers.info(
            '📞 Incoming call notification received in foreground');
        await _handleEnhancedIncomingCall(message);
        return; // Don't show regular notification for calls
      }

      if (message.data['type'] ==
          NotificationType.chat.type) {
        Loggers.info('💬 Chat notification received');
        ChatThread conversationUser =
            ChatThread.fromJson(jsonDecode(data));
        if (conversationUser.conversationId ==
            ChatScreenController.chatId) {
          Loggers.info(
              '💬 Chat notification ignored - already in conversation');
          return;
        }
      } else {
        SessionManager.instance.setNotifyCount(1);
      }

      Loggers.info(
          '🔔 Showing notification: ${message.notification?.title}');
      showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp
        .listen((RemoteMessage message) {
      Loggers.info(
          'User tapped the notification: ${message.data}');
      print('FirebaseMessaging.onMessageOpenedApp');
      if (message.data.isNotEmpty) {
        handleNotification(jsonEncode(message.toMap()));
      }
    });

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void unsubscribeToTopic({String? topic}) async {
    Loggers.success(
        '🔔 Topic UnSubscribe : ${topic ?? notificationTopic}_${Platform.isAndroid ? 'android' : 'ios'}');
    await firebaseMessaging.unsubscribeFromTopic(
        '${topic ?? notificationTopic}_${Platform.isAndroid ? 'android' : 'ios'}');
  }

  Future<void> subscribeToTopic({String? topic}) async {
    Loggers.success(
        '🔔 Topic Subscribe : ${topic ?? notificationTopic}_${Platform.isAndroid ? 'android' : 'ios'}');
    await firebaseMessaging.subscribeToTopic(
        '${topic ?? notificationTopic}_${Platform.isAndroid ? 'android' : 'ios'}');
  }

  void showNotification(RemoteMessage message) {
    print('SHOW MESSAGE : ${message.toMap()}');
    int notificationId = DateTime.now()
        .millisecondsSinceEpoch
        .remainder(100000);

    flutterLocalNotificationsPlugin.show(
        notificationId,
        (message.data['title']) ??
            message.notification?.title,
        (message.data['body'] as String?) ??
            message.notification?.body,
        NotificationDetails(
            iOS: const DarwinNotificationDetails(
                presentSound: true,
                presentAlert: true,
                presentBadge: false),
            android: AndroidNotificationDetails(
                channel.id, channel.name)),
        payload: jsonEncode(message.toMap()));
  }

  void showIncomingCallNotification(RemoteMessage message) {
    Loggers.info('📞 showIncomingCallNotification called');
    final map = message.data;
    final String data = map['notification_data'] ?? '';
    String title = map['title'] ?? 'Incoming call';
    String body = map['body'] ?? 'Tap to answer';

    Loggers.info('📞 Call notification data: $data');
    Loggers.info('📞 Default title: $title, body: $body');

    try {
      final parsed =
          jsonDecode(data) as Map<String, dynamic>;
      final caller =
          parsed['caller'] as Map<String, dynamic>?;
      final isVideo = (parsed['isVideo'] ?? 0) == 1 ||
          parsed['isVideo'] == true;
      title =
          'Incoming ${isVideo ? 'video' : 'voice'} call';
      if (caller != null &&
          (caller['fullname'] ?? '')
              .toString()
              .isNotEmpty) {
        body = 'From ${caller['fullname']}';
      }
      Loggers.info(
          '📞 Parsed call data - isVideo: $isVideo, caller: ${caller?['fullname']}');
      Loggers.info('📞 Final title: $title, body: $body');
    } catch (e) {
      Loggers.error(
          '📞 Error parsing call notification data: $e');
    }

    final payload = jsonEncode(message.toMap());
    Loggers.info(
        '📞 Payload created, showing notification...');

    try {
      flutterLocalNotificationsPlugin.show(
        DateTime.now()
            .millisecondsSinceEpoch
            .remainder(100000),
        title,
        body,
        NotificationDetails(
          iOS: const DarwinNotificationDetails(
            presentSound: true,
            presentAlert: true,
            presentBadge: false,
            categoryIdentifier: 'incoming_call',
          ),
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.call,
            ongoing: true,
            autoCancel: false,
            actions: <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'ACCEPT_CALL',
                'Accept',
                showsUserInterface: true,
                cancelNotification: true,
              ),
              const AndroidNotificationAction(
                'DECLINE_CALL',
                'Decline',
                cancelNotification: true,
              ),
            ],
          ),
        ),
        payload: payload,
      );
      Loggers.info(
          '📞 Call notification displayed successfully');
    } catch (e) {
      Loggers.error(
          '📞 Error showing call notification: $e');
    }
  }

  Future<void> _handleCallAction(String payload,
      {required bool accept}) async {
    final message =
        RemoteMessage.fromMap(jsonDecode(payload));
    final dataString =
        message.data['notification_data'] as String?;
    if (dataString == null || dataString.isEmpty) return;

    if (!accept) {
      // Optional: call API to mark call as declined
      print('📞 Call declined from notification');
      return;
    }

    print('📞 Call accepted from notification');
    await _handleIncomingCallNotification(dataString);
  }

  Future<void> handleNotification(String payload) async {
    final RemoteMessage message =
        RemoteMessage.fromMap(jsonDecode(payload));
    final dataType = message.data['type'];
    final dataString = message.data['notification_data'];
    print('DATA TYPE : $dataType');
    print('DATA STRING : $dataString');
    if (dataType == null ||
        dataString == null ||
        dataString.isEmpty) {
      return;
    }
    final controller = Get.put(DashboardScreenController());
    switch (dataType) {
      case 'chat':
        controller.selectedPageIndex.value = 4;
        await _handleChatNotification(dataString);
        break;
      case 'call':
        await _handleIncomingCallNotification(dataString);
        break;
      case 'post':
        await _handlePostNotification(
            dataString, controller);
        break;
      case 'user':
        controller.selectedPageIndex.value = 5;
        await _handleUserNotification(dataString);
        break;
      case 'live_stream':
        controller.selectedPageIndex.value = 2;
        await _handleLivestreamNotification(dataString);
        break;
      default:
        Loggers.warning(
            'Unknown notification type: $dataType');
    }
  }

  Future<void> _handleIncomingCallNotification(
      String data) async {
    try {
      final map = jsonDecode(data) as Map<String, dynamic>;
      final String channelId = map['channelId'] ?? '';
      final bool isVideo = (map['isVideo'] ?? 0) == 1 ||
          map['isVideo'] == true;
      final String? token = map['token'];
      final callerMap =
          map['caller'] as Map<String, dynamic>?;

      if (channelId.isEmpty || callerMap == null) return;

      final caller = User.fromJson(callerMap);

      await Get.to(() => IncomingCallScreen(
            channelId: channelId,
            isVideoCall: isVideo,
            token: token,
            caller: caller,
          ));
    } catch (e) {
      Loggers.error(
          'Failed to handle call notification: $e');
    }
  }

  /// Enhanced call handling using CallNotificationManager
  Future<void> _handleEnhancedIncomingCall(
      RemoteMessage message) async {
    try {
      Loggers.info(
          '📞 Processing enhanced incoming call notification');

      final String data =
          message.data['notification_data'] ?? '';
      if (data.isEmpty) {
        Loggers.error('📞 Empty call notification data');
        return;
      }

      // Parse call data
      final map = jsonDecode(data) as Map<String, dynamic>;
      final String channelId = map['channelId'] ?? '';
      final bool isVideo = (map['isVideo'] ?? 0) == 1 ||
          map['isVideo'] == true;
      final String? token = map['token'];
      final callerMap =
          map['caller'] as Map<String, dynamic>?;

      if (channelId.isEmpty || callerMap == null) {
        Loggers.error(
            '📞 Invalid call notification data: missing channelId or caller');
        return;
      }

      final caller = User.fromJson(callerMap);
      final callId = message.messageId ??
          '${DateTime.now().millisecondsSinceEpoch}';

      Loggers.info(
          '📞 Showing enhanced incoming call - Caller: ${caller.fullname}, Video: $isVideo');

      // Initialize enhanced call notification manager if needed
      if (!CallNotificationManager.instance.isInitialized) {
        await CallNotificationManager.instance.initialize();
      }

      // Show enhanced incoming call notification
      await CallNotificationManager.instance
          .showIncomingCall(
        callId: callId,
        caller: caller,
        channelId: channelId,
        isVideoCall: isVideo,
        token: token,
        timeout: const Duration(seconds: 45),
      );
    } catch (e) {
      Loggers.error(
          '📞 ❌ Failed to handle enhanced incoming call: $e');
      // Fallback to original method
      final data = message.data['notification_data'] ?? '';
      if (data.isNotEmpty) {
        await _handleIncomingCallNotification(data);
      }
    }
  }

  Future<void> _handleChatNotification(String data) async {
    try {
      final conversationUser =
          ChatThread.fromJson(jsonDecode(data));
      Loggers.info(
          'Navigating to chat: ${conversationUser.toJson()}');
      await Get.to(() =>
          ChatScreen(conversationUser: conversationUser));
    } catch (e) {
      Loggers.error(
          'Failed to handle chat notification: $e');
    }
  }

  Future<void> _handlePostNotification(String data,
      DashboardScreenController controller) async {
    try {
      NotificationInfo notificationInfo =
          NotificationInfo.fromJson(jsonDecode(data));
      final int postId = notificationInfo.id ?? -1;
      final int? commentId = notificationInfo.commentId;
      final int? replyId = notificationInfo.replyCommentId;
      final result = await PostService.instance
          .fetchPostById(
              postId: postId,
              commentId: commentId,
              replyId: replyId);

      if (result.status == true && result.data != null) {
        final Post? post = result.data?.post;
        if (post == null) return;

        if (post.postType == PostType.reel) {
          controller.selectedPageIndex.value = 5;
          Get.to(() => ReelsScreen(
              reels: [post].obs,
              position: 0,
              postByIdData: result.data));
        } else if ([
          PostType.text,
          PostType.image,
          PostType.video
        ].contains(post.postType)) {
          controller.selectedPageIndex.value = 1;
          await Get.to(() => SinglePostScreen(
              post: post,
              postByIdData: result.data,
              isFromNotification: true));
        }
      }
    } catch (e) {
      Loggers.error(
          'Failed to handle post notification: $e');
    }
  }

  Future<void> _handleUserNotification(String data) async {
    try {
      final map = jsonDecode(data);
      final int id = map['id'];
      final user = await UserService.instance
          .fetchUserDetails(userId: id);

      if (user != null) {
        Loggers.success('Navigating to user: ${user.id}');
        NavigationService.shared.openProfileScreen(user);
      }
    } catch (e) {
      Loggers.error(
          'Failed to handle user notification: $e');
    }
  }

  Future<String?> getNotificationToken() async {
    try {
      String? token =
          await FirebaseMessaging.instance.getToken();
      Loggers.info('DeviceToken $token');
      return token;
    } catch (e) {
      Loggers.error('DeviceToken Exception $e');
      return null;
    }
  }

  Future<void> sendLocalisationNotification(
    String key, {
    Map<String, String> keyParams = const {},
    String? deviceToken = '',
    int? deviceType = 0,
    String? languageCode = 'en',
    required NotificationInfo body,
    required NotificationType type,
  }) async {
    // Early return if no device token provided
    if ((deviceToken ?? '').isEmpty) {
      Loggers.error(
          'Device Token Empty - Notification not sent for key: $key');
      return;
    }

    // Get user data once
    final user = SessionManager.instance.getUser();
    final title = user?.fullname ?? '';

    // Get translations efficiently
    final translations = Get.find<DynamicTranslations>();
    final languageData =
        translations.keys[languageCode] ?? {};

    // Get description with fallback
    final description =
        languageData[key]?.trParams(keyParams) ??
            key.trParams(keyParams);

    // Log relevant information
    Loggers.info('''
      [Notification Details]
      Language: $languageCode
      Key: $key
      Description: $description
      Recipient: ${user?.id ?? 'Unknown'}
      Device Type: $deviceType
      Device Token: $deviceToken
    ''');

    // Send notification
    await NotificationService.instance.pushNotification(
        title: title,
        body: description,
        data: body.toJson(),
        deviceType: deviceType,
        token: deviceToken,
        type: type);
  }

  Future<void> _handleLivestreamNotification(
      String dataString) async {
    final incomingStream =
        Livestream.fromJson(jsonDecode(dataString));

    // If controller not registered, fetch from Firestore
    final snapshot = await FirebaseFirestore.instance
        .collection(FirebaseConst.liveStreams)
        .withConverter<Livestream>(
          fromFirestore: (snapshot, _) =>
              Livestream.fromJson(snapshot.data()!),
          toFirestore: (livestream, _) =>
              livestream.toJson(),
        )
        .get();

    final matchedDoc = snapshot.docs.firstWhereOrNull(
        (doc) =>
            doc.data().roomID == incomingStream.roomID);

    if (matchedDoc == null) {
      BaseController.share
          .showSnackBar(LKey.livestreamHasEnded.tr);
      return;
    }

    final stream = matchedDoc.data();
    final myUser = SessionManager.instance.getUser();

    if (stream.hostId == myUser?.id) {
      Get.to(() => LivestreamHostScreen(
          isHost: true, livestream: stream));
    } else {
      Get.to(() => LiveStreamAudienceScreen(
          isHost: false, livestream: stream));
    }
  }
}

enum NotificationType {
  call('call'),
  chat('chat'),
  post('post'),
  user('user'),
  liveStream('live_stream'),
  other('other');

  final String type;

  const NotificationType(this.type);
}

class NotificationInfo {
  int? id;
  int? commentId;
  int? replyCommentId;

  NotificationInfo({
    this.id,
    this.commentId,
    this.replyCommentId,
  });

  factory NotificationInfo.fromJson(
          Map<String, dynamic> json) =>
      NotificationInfo(
        id: json["id"],
        commentId: json["comment_id"],
        replyCommentId: json["reply_comment_id"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "comment_id": commentId,
        "reply_comment_id": replyCommentId,
      };
}
