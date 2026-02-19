import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'platform_strings.dart';
import 'resolution_preset.dart';

enum VideoResponse { videoStarted, videoCompleted, videoError }

enum ScreenshotResponse { screenshotTaken }

class CameraHealthEvent {
  final String reason;
  final String message;
  final Map<String, dynamic> raw;

  const CameraHealthEvent({
    required this.reason,
    required this.message,
    required this.raw,
  });

  factory CameraHealthEvent.fromMap(Map<dynamic, dynamic> data) {
    final normalized = <String, dynamic>{};
    data.forEach((key, value) {
      normalized[key.toString()] = value;
    });
    return CameraHealthEvent(
      reason: (normalized['reason'] ?? '').toString(),
      message: (normalized['message'] ?? '').toString(),
      raw: normalized,
    );
  }
}

class DeepArPlatformHandler {
  static const MethodChannel _channel =
      MethodChannel(PlatformStrings.generalChannel);
  static const MethodChannel _cameraXChannel =
      MethodChannel(PlatformStrings.cameraXChannel);
  MethodChannel _avCameraChannel(int view) =>
      MethodChannel('${PlatformStrings.avCameraChannel}/$view');
  static VideoResponse? _videoResponse;
  static String? _videoFilePath;
  static ScreenshotResponse? _screenshotResponse;
  static String? _screenshotFilePath;
  static final StreamController<CameraHealthEvent> _cameraHealthController =
      StreamController<CameraHealthEvent>.broadcast();

  DeepArPlatformHandler() {
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler(listenFromNativeMethodHandler);
    }
  }

  void setListenerIos(int view) {
    _avCameraChannel(view).setMethodCallHandler(listenFromNativeMethodHandler);
  }

  Stream<CameraHealthEvent> get cameraHealthStream =>
      _cameraHealthController.stream;

  Future<void> listenFromNativeMethodHandler(MethodCall call) async {
    final rawArgs = call.arguments;
    if (rawArgs is! Map) return;
    final Map<dynamic, dynamic> data = rawArgs;
    switch (call.method) {
      case "on_video_result":
        final caller = data['caller'];
        final String? filePath = data['file_path'];
        if (caller == null) return;
        _videoResponse = VideoResponse.values.byName(caller.toString());

        if (_videoResponse == VideoResponse.videoCompleted) {
          _videoFilePath = filePath;
        } else {
          _videoFilePath = null;
        }

        break;
      case "on_screenshot_result":
        final caller = data['caller'];
        final String? filePath = data['file_path'];
        if (caller == null) return;
        _screenshotResponse =
            ScreenshotResponse.values.byName(caller.toString());

        if (_screenshotResponse == ScreenshotResponse.screenshotTaken) {
          _screenshotFilePath = filePath;
        } else {
          _screenshotFilePath = null;
        }

        break;
      case "on_camera_health":
        _cameraHealthController.add(
          CameraHealthEvent.fromMap(data),
        );
        break;
      default:
        debugPrint('no method handler for method ${call.method}');
    }
  }

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<String?> initialize(String licenseKey, Resolution resolution) {
    return _channel.invokeMethod<String?>(PlatformStrings.initialize, {
      PlatformStrings.licenseKey: licenseKey,
      "resolution": resolution.stringValue,
    });
  }

  Future<int> startCameraAndroid() async {
    int texturedId =
        await _cameraXChannel.invokeMethod(PlatformStrings.startCamera);
    return texturedId;
  }

  Future<String?> switchEffectAndroid(String? effect) {
    return _channel.invokeMethod<String>(PlatformStrings.switchEffect, {
      PlatformStrings.effect: effect,
    });
  }

  Future<String?> switchCameraIos(String? effect, int view) {
    debugPrint("Switching effect on iOS: $effect");
    return _avCameraChannel(view)
        .invokeMethod<String>(PlatformStrings.switchEffect, {
      PlatformStrings.effect: effect,
    });
  }

  Future<String?> switchFaceMaskAndroid(String? mask) {
    return _channel.invokeMethod<String>('switch_face_mask', {
      PlatformStrings.effect: mask,
    });
  }

  Future<String?> switchFaceMaskIos(String? mask, int view) {
    return _avCameraChannel(view).invokeMethod<String>('switch_face_mask', {
      PlatformStrings.effect: mask,
    });
  }

  Future<String?> switchFilterAndroid(String? mask) {
    return _channel.invokeMethod<String>('switch_filter', {
      PlatformStrings.effect: mask,
    });
  }

  Future<String?> switchFilterIos(String? mask, int view) {
    return _avCameraChannel(view).invokeMethod<String>('switch_filter', {
      PlatformStrings.effect: mask,
    });
  }

  Future<void> startRecordingVideoAndroid() async {
    await _channel.invokeMethod(PlatformStrings.startRecordingVideo);
  }

  Future<String?> stopRecordingVideoAndroid() async {
    await _channel.invokeMethod(PlatformStrings.stopRecordingVideo);
    final Completer completer = Completer<String>();
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (timer.tick > 20) {
        completer.complete("ENDED_WITH_ERROR");
        _videoFilePath = null;
        _videoResponse = null;
        timer.cancel();
      } else if (_videoResponse == VideoResponse.videoCompleted) {
        completer.complete(_videoFilePath);
        _videoFilePath = null;
        _videoResponse = null;
        timer.cancel();
      } else if (_videoResponse == VideoResponse.videoError) {
        completer.complete("ENDED_WITH_ERROR");
        _videoFilePath = null;
        _videoResponse = null;
        timer.cancel();
      }
    });
    return completer.future.then((value) => value);
  }

  Future<void> startRecordingVideoIos(int view) async {
    await _avCameraChannel(view)
        .invokeMethod<String>(PlatformStrings.startRecordingVideo);
  }

  Future<String?> stopRecordingVideoIos(int view) async {
    await _avCameraChannel(view)
        .invokeMethod<String>(PlatformStrings.stopRecordingVideo);
    final Completer completer = Completer<String>();
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (timer.tick > 20) {
        completer.complete("ENDED_WITH_ERROR");
        _videoFilePath = null;
        _videoResponse = null;
        timer.cancel();
      } else if (_videoResponse == VideoResponse.videoCompleted) {
        completer.complete(_videoFilePath);
        _videoFilePath = null;
        _videoResponse = null;
        timer.cancel();
      } else if (_videoResponse == VideoResponse.videoError) {
        completer.complete("ENDED_WITH_ERROR");
        _videoFilePath = null;
        _videoResponse = null;
        timer.cancel();
      }
    });
    return completer.future.then((value) => value);
  }

  Future<String?> getResolutionDimensions(int view) async {
    final dimensions = await _avCameraChannel(view)
        .invokeMethod<String?>(PlatformStrings.getResolution);
    return dimensions;
  }

  Future<bool?> flipCamera() {
    return _cameraXChannel.invokeMethod<bool>("flip_camera");
  }

  Future<bool?> flipCameraIos(int view) {
    return _avCameraChannel(view).invokeMethod<bool>("flip_camera");
  }

  Future<String?> takeScreenShot() async {
    await _channel.invokeMethod("take_screenshot");
    final Completer<String> completer = Completer<String>();
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (timer.tick > 20) {
        completer.complete("ENDED_WITH_ERROR");
        _screenshotFilePath = null;
        _screenshotResponse = null;
        timer.cancel();
      } else if (_screenshotResponse == ScreenshotResponse.screenshotTaken) {
        completer.complete(_screenshotFilePath);
        _screenshotFilePath = null;
        _screenshotResponse = null;
        timer.cancel();
      }
    });
    return completer.future.then((value) => value);
  }

  Future<String?> takeScreenShotIos(int view) async {
    await _avCameraChannel(view).invokeMethod<String>("take_screenshot");
    final Completer<String> completer = Completer<String>();
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (timer.tick > 20) {
        completer.complete("ENDED_WITH_ERROR");
        _screenshotFilePath = null;
        _screenshotResponse = null;
        timer.cancel();
      } else if (_screenshotResponse == ScreenshotResponse.screenshotTaken) {
        completer.complete(_screenshotFilePath);
        _screenshotFilePath = null;
        _screenshotResponse = null;
        timer.cancel();
      }
    });
    return completer.future.then((value) => value);
  }

  Future<bool> toggleFlash() async {
    return await _cameraXChannel.invokeMethod<bool>("toggle_flash") ?? false;
  }

  Future<bool> toggleFlashIos(int view) async {
    return await _avCameraChannel(view).invokeMethod<bool>("toggle_flash") ??
        false;
  }

  Future<String?> destroy() async {
    return await _cameraXChannel.invokeMethod<String?>("destroy");
  }

  Future<void> destroyIos(int view) {
    return _avCameraChannel(view).invokeMethod<String?>("destroy");
  }

  Future<void> switchEffectWithSlot(
      {required String slot,
      required String path,
      String targetGameObject = '',
      int face = 0}) {
    return _channel.invokeMethod("switchEffectWithSlot", {
      "slot": slot,
      "path": path,
      "face": face,
      "targetGameObject": targetGameObject,
    });
  }

  Future<void> switchEffectWithSlotIos(int view,
      {required String slot,
      required String path,
      String targetGameObject = '',
      int face = 0}) {
    return _avCameraChannel(view).invokeMethod("switchEffectWithSlot", {
      "slot": slot,
      "path": path,
      "face": face,
      "targetGameObject": targetGameObject,
    });
  }

  Future<void> fireTrigger(String trigger) {
    return _channel.invokeMethod("fireTrigger", {"trigger": trigger});
  }

  Future<void> fireTriggerIos(int view, String trigger) {
    return _avCameraChannel(view)
        .invokeMethod("fireTrigger", {"trigger": trigger});
  }

  Future<void> showStats(bool enabled) {
    return _channel.invokeMethod("showStats", {"enabled": enabled});
  }

  Future<void> showStatsIos(int view, bool enabled) {
    return _avCameraChannel(view)
        .invokeMethod("showStats", {"enabled": enabled});
  }

  Future<void> simulatePhysics(bool enabled) {
    return _channel.invokeMethod("simulatePhysics", {"enabled": enabled});
  }

  Future<void> simulatePhysicsIos(int view, bool enabled) {
    return _avCameraChannel(view)
        .invokeMethod("simulatePhysics", {"enabled": enabled});
  }

  Future<void> showColliders(bool enabled) {
    return _channel.invokeMethod("showColliders", {"enabled": enabled});
  }

  Future<void> showCollidersIos(int view, bool enabled) {
    return _avCameraChannel(view)
        .invokeMethod("showColliders", {"enabled": enabled});
  }

  Future<void> moveGameObject(
      String selectedGameObjectName, String targetGameObjectName) {
    return _channel.invokeMethod("fireTrigger", {
      "selectedGameObjectName": selectedGameObjectName,
      "targetGameObjectName": targetGameObjectName
    });
  }

  Future<void> moveGameObjectIos(
      int view, String selectedGameObjectName, String targetGameObjectName) {
    return _avCameraChannel(view).invokeMethod("fireTrigger", {
      "selectedGameObjectName": selectedGameObjectName,
      "targetGameObjectName": targetGameObjectName
    });
  }

  Future<void> changeParameter(Map<String, dynamic> arguments) {
    return _channel.invokeMethod("changeParameter", arguments);
  }

  Future<void> changeParameterIos(int view, Map<String, dynamic> arguments) {
    return _avCameraChannel(view).invokeMethod("changeParameter", arguments);
  }
}
