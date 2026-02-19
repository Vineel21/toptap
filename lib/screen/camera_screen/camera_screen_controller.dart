import 'dart:async';
import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:deepar_flutter_plus/deepar_flutter_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:retrytech_plugin/retrytech_plugin.dart';
import 'package:shortzz/common/controller/base_controller.dart';
import 'package:shortzz/common/extensions/string_extension.dart';
import 'package:shortzz/common/functions/media_picker_helper.dart';
import 'package:shortzz/common/manager/logger.dart';
import 'package:shortzz/common/manager/session_manager.dart';
import 'package:shortzz/common/widget/confirmation_dialog.dart';
import 'package:shortzz/languages/languages_keys.dart';
import 'package:shortzz/model/general/settings_model.dart';
import 'package:shortzz/config/deepar/local_deepar_filters.dart';
import 'package:shortzz/screen/camera_edit_screen/camera_edit_screen.dart';
import 'package:shortzz/screen/camera_screen/camera_types.dart';
import 'package:shortzz/screen/music_sheet/music_sheet.dart';
import 'package:shortzz/screen/selected_music_sheet/selected_music_sheet.dart';
import 'package:shortzz/screen/selected_music_sheet/selected_music_sheet_controller.dart';
import 'package:shortzz/utilities/app_res.dart';

class CameraScreenController extends BaseController
    with GetSingleTickerProviderStateMixin {
  // Constants
  static const _progressUpdateInterval = 10; // milliseconds
  static const _maxDeepArRecoveryAttempts = 1;
  RxList<int> secondsList = AppRes.secondList.obs;

  // Dependencies
  final CameraScreenType cameraType;
  final PlayerController audioPlayer = PlayerController();
  final Rx<DeepArControllerPlus> deepArControllerPlus =
      DeepArControllerPlus().obs;
  RxBool isSecondListShow = true.obs;

  // State variables

  RxInt selectedSecond = AppRes.secondList.first.obs;
  RxBool isTorchOn = false.obs;
  RxBool isRecording = false.obs;
  RxBool isStartingRecording = false.obs;
  RxBool isEffectShow = false.obs;
  Rx<SelectedMusic?> selectedMusic = Rx(null);
  RxDouble progress = 0.0.obs;
  RxBool isDeepARInitialized = false.obs;
  RxBool useFallbackCamera = false.obs;
  bool _isDisposingCamera = false;
  bool _isDeepArBlockedDevice = false;
  String _deepArBlockReason = '';
  String _deepArDeviceKey = 'unknown_android_device';
  int _deepArRecoveryAttempts = 0;
  bool _isRecoveringDeepAr = false;
  StreamSubscription<dynamic>? _deepArHealthSubscription;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  Setting? get appSetting => SessionManager.instance.getSettings();
  late Rx<DeepARFilters> selectedEffect;

  bool get isDeepAr => appSetting?.isDeepAr == 1;
  bool get _shouldUseDeepAr => isDeepAr && !_isDeepArBlockedDevice;
  bool get isUsingDeepAr =>
      _shouldUseDeepAr && useFallbackCamera.value == false;

  List<DeepARFilters> get availableDeepArFilters {
    final Map<String, DeepARFilters> uniqueMap = {};

    void addFilter(DeepARFilters filter) {
      final key = (filter.filterFile?.isNotEmpty == true)
          ? filter.filterFile!
          : '${filter.id}_${filter.title}';
      if (uniqueMap.containsKey(key)) return;
      uniqueMap[key] = filter;
    }

    addFilter(deepArNoneEffect);

    final remoteFilters = appSetting?.deepARFilters ?? [];
    for (final filter in remoteFilters) {
      addFilter(filter);
    }

    for (final filter in localDeepArBeautyFilters) {
      if (filter.id == deepArNoneEffect.id &&
          filter.filterFile == deepArNoneEffect.filterFile) {
        continue;
      }
      addFilter(filter);
    }

    return uniqueMap.values.toList(growable: false);
  }

  // Private variables
  Timer? _progressTimer;
  Completer<void>? _cameraOperationCompleter;

  CameraScreenController(this.cameraType, this.selectedMusic);

  @override
  void onInit() {
    super.onInit();
    unawaited(_initialize());
    selectedEffect = Rx(deepArNoneEffect);
    if (availableDeepArFilters.length > 1) {
      isEffectShow.value = true;
    }
  }

  @override
  void onClose() {
    _cleanUpResources();
    super.onClose();
  }

  // Initialization methods
  Future<void> _initialize() async {
    await _detectDeepArCompatibility();
    await _initData();
    await _initCamera();
  }

  Future<void> _detectDeepArCompatibility() async {
    if (!isDeepAr || !Platform.isAndroid) return;

    try {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      _deepArDeviceKey =
          '${androidInfo.manufacturer}|${androidInfo.model}|sdk${androidInfo.version.sdkInt}'
              .toLowerCase();

      final isLowSdk = androidInfo.version.sdkInt < 26;
      _isDeepArBlockedDevice = isLowSdk;

      if (isLowSdk) {
        _deepArBlockReason = 'sdk_lt_26';
      } else {
        _deepArBlockReason = 'none';
      }

      Loggers.info(
          'DeepAR compatibility -> model: ${androidInfo.model}, manufacturer: ${androidInfo.manufacturer}, sdk: ${androidInfo.version.sdkInt}, key: $_deepArDeviceKey, blocked: $_isDeepArBlockedDevice, reason: $_deepArBlockReason');
    } catch (e) {
      Loggers.warning('Unable to detect device compatibility for DeepAR: $e');
      _isDeepArBlockedDevice = false;
      _deepArBlockReason = 'device_info_error';
    }
  }

  Future<void> _initData() async {
    if (cameraType == CameraScreenType.story) {
      selectedSecond.value = AppRes.storyVideoDuration;
    }
    await _initializeAudioIfNeeded();
  }

  Future<void> _initializeAudioIfNeeded() async {
    if (selectedMusic.value == null) return;

    try {
      await audioPlayer.preparePlayer(
          path: selectedMusic.value?.downloadedURL ?? '');
      final audioTotalDurationInMs = await audioPlayer.getDuration();
      Loggers.info('Audio Total Duration $audioTotalDurationInMs');
      List<int> newSecondList = [];
      int audioSecond = (audioTotalDurationInMs / 1000).toInt();
      for (var element in secondsList) {
        if (element <= audioSecond) {
          newSecondList.add(element);
        }
      }

      if (newSecondList.isNotEmpty) {
        secondsList.value = newSecondList;
        selectedSecond.value = secondsList.first;
      } else {
        showSnackBar(
            LKey.recordUpToSeconds.trParams({'second': '$audioSecond'}));
        selectedSecond.value = audioSecond;
        isSecondListShow.value = false;
      }
      Loggers.info('Recording Second ${selectedSecond.value}');
      int startAudioMs = selectedMusic.value?.audioStartMS ?? 0;
      if (isStartingRecording.value) {
        await audioPlayer
            .seekTo(startAudioMs + (progress.value * 1000).toInt());
      } else {
        await audioPlayer.seekTo(startAudioMs);
      }
      Loggers.success('Audio Duration: $startAudioMs');
    } catch (e) {
      Loggers.error('Audio initialization error: $e');
    }
  }

  Future<void> _initCamera() async {
    Loggers.info('Initialize camera');
    _deepArRecoveryAttempts = 0;
    _isRecoveringDeepAr = false;
    if (_shouldUseDeepAr) {
      useFallbackCamera.value = false;
      await _initDeepArCamera();
    } else {
      if (isDeepAr) {
        Loggers.warning(
            'DeepAR disabled on this device for rendering stability. Falling back to standard camera.');
      }
      isDeepARInitialized.value = false;
      useFallbackCamera.value = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        RetrytechPlugin.shared.initCamera();
      });
    }
  }

  Future<void> _initDeepArCamera() async {
    try {
      // Initialize DeepAR
      final initializeResult = await deepArControllerPlus.value.initialize(
          androidLicenseKey: appSetting?.deeparAndroidKey,
          iosLicenseKey: appSetting?.deeparIOSKey,
          resolution: Resolution.high);
      if (!initializeResult.success) {
        Loggers.error(
            'DeepAR initialization failed: ${initializeResult.message}');
        await _switchToFallbackCamera(
          reason: 'deepar_init_failed',
        );
        return;
      }
      _listenDeepArHealthEvents();
      await deepArControllerPlus.value
          .switchEffectWithSlot(slot: 'effect', path: 'none');
      isDeepARInitialized.value = true;
      Loggers.info(
          'DeepAR session started successfully for key $_deepArDeviceKey');
    } catch (e) {
      Loggers.error('Error initializing AR: $e');
      await _switchToFallbackCamera(
        reason: 'deepar_init_exception',
      );
    }
  }

  void _listenDeepArHealthEvents() {
    _deepArHealthSubscription?.cancel();
    _deepArHealthSubscription =
        deepArControllerPlus.value.cameraHealthStream.listen((event) {
      final reason = event.reason.toString();
      final message = event.message.toString();
      Loggers.warning(
          'DeepAR health event -> reason: $reason, message: $message, key: $_deepArDeviceKey');
      unawaited(
        _handleDeepArHealthEvent(
          reason: reason,
          message: message,
        ),
      );
    });
  }

  Future<void> _handleDeepArHealthEvent({
    required String reason,
    required String message,
  }) async {
    if (!isUsingDeepAr || isClosed || useFallbackCamera.value) return;
    if (_isRecoveringDeepAr) return;

    if (_deepArRecoveryAttempts >= _maxDeepArRecoveryAttempts) {
      await _switchToFallbackCamera(
        reason: 'deepar_health_$reason',
      );
      return;
    }

    _isRecoveringDeepAr = true;
    _deepArRecoveryAttempts += 1;

    Loggers.warning(
        'Attempting DeepAR recovery ($_deepArRecoveryAttempts/$_maxDeepArRecoveryAttempts) for reason: $reason, message: $message');

    try {
      isDeepARInitialized.value = false;
      await deepArControllerPlus.value.destroy();
      await _initDeepArCamera();
    } catch (e) {
      Loggers.error('DeepAR recovery failed: $e');
      await _switchToFallbackCamera(
        reason: 'deepar_recovery_exception',
      );
    } finally {
      _isRecoveringDeepAr = false;
    }

    if (!isClosed &&
        !useFallbackCamera.value &&
        isDeepARInitialized.value == false) {
      await _switchToFallbackCamera(
        reason: 'deepar_recovery_failed',
      );
    }
  }

  Future<void> _switchToFallbackCamera({
    required String reason,
  }) async {
    if (useFallbackCamera.value) return;

    _deepArHealthSubscription?.cancel();
    _deepArHealthSubscription = null;
    _isRecoveringDeepAr = false;
    useFallbackCamera.value = true;
    isDeepARInitialized.value = false;

    try {
      await deepArControllerPlus.value.destroy();
    } catch (e) {
      Loggers.warning('DeepAR destroy warning before fallback: $e');
    }

    if (isClosed) return;

    Loggers.warning('Switching to stable camera fallback (reason: $reason)');
    RetrytechPlugin.shared.initCamera();
  }

  // Cleanup methods
  void _cleanUpResources() {
    _progressTimer?.cancel();
    _cameraOperationCompleter?.complete();
    _deepArHealthSubscription?.cancel();
    _deepArHealthSubscription = null;
    unawaited(disposeCamera());

    audioPlayer.release();
    audioPlayer.dispose();
  }

  Future<void> disposeCamera() async {
    if (_isDisposingCamera) return;
    _isDisposingCamera = true;
    Loggers.info('Dispose camera');
    _deepArHealthSubscription?.cancel();
    _deepArHealthSubscription = null;
    if (isUsingDeepAr) {
      isDeepARInitialized.value = false;
      try {
        await deepArControllerPlus.value.destroy();
      } catch (e) {
        Loggers.warning('DeepAR destroy warning: $e');
      }
    } else {
      try {
        RetrytechPlugin.shared.disposeCamera;
      } catch (e) {
        Loggers.warning('Fallback camera dispose warning: $e');
      }
    }
    _isDisposingCamera = false;
  }

  // Permission handling
  void showPermissionDeniedSheet() {
    Get.bottomSheet(
      ConfirmationSheet(
        title: LKey.cameraMicrophonePermissionTitle.tr,
        description: LKey.cameraMicrophonePermissionDescription
            .trParams({'app_name': AppRes.appName}),
        onTap: openAppSettings,
        onClose: () => Get.back(),
        positiveText: LKey.openSetting.tr,
        isDismissible: true,
      ),
      enableDrag: false,
      isDismissible: false,
    );
  }

  // Media handling methods
  Future<void> onMediaTap() async {
    try {
      switch (cameraType) {
        case CameraScreenType.post:
          final mediaFile = await MediaPickerHelper.shared
              .pickVideo(source: ImageSource.gallery);
          if (mediaFile != null) {
            await _handleReel(mediaFile);
          }
          break;

        case CameraScreenType.story:
          final mediaFile = await MediaPickerHelper.shared.pickMedia();
          if (mediaFile != null) {
            await (mediaFile.type == MediaType.image
                ? handleImageStory(mediaFile)
                : handleVideoStory(mediaFile));
          }
          break;
      }
    } catch (e) {
      Loggers.error('Media selection error: $e');
    }
  }

  Future<void> handleImageStory(MediaFile file) async {
    String imagePath = file.file.path;
    try {
      final bgColor = await imagePath.getGradientFromImage;

      await _navigateToEditScreen(
          PostStoryContentType.storyImage, imagePath, imagePath, bgColor);
    } catch (e) {
      Loggers.error('Gradient Error $e');
    }
  }

  Future<void> handleVideoStory(MediaFile file) async {
    String thumbnailPath = file.thumbNail.path;
    String videoPath = file.file.path;
    final bgColor = await thumbnailPath.getGradientFromImage;
    await _navigateToEditScreen(
        PostStoryContentType.storyVideo, videoPath, thumbnailPath, bgColor);
  }

  Future<void> _navigateToEditScreen(
    PostStoryContentType type,
    String contentPath,
    String thumbnailPath,
    LinearGradient bgColor,
  ) async {
    final content = PostStoryContent(
      type: type,
      content: contentPath,
      thumbNail: thumbnailPath,
      duration: AppRes.storyImageAndTextDuration,
      bgGradient: bgColor,
      sound: selectedMusic.value,
    );

    navigateCameraEditScreen(content);
  }

  // Camera control methods
  void onToggleFlash() {
    if (isUsingDeepAr) {
      deepArControllerPlus.value.toggleFlash();
    } else {
      RetrytechPlugin.shared.flashOnOff;
      isTorchOn.toggle();
    }
  }

  Future<void> onToggleCamera() async {
    if (isUsingDeepAr) {
      deepArControllerPlus.value.flipCamera();
    } else {
      if (isTorchOn.value) {
        isTorchOn.value = false;
        RetrytechPlugin.shared.flashOnOff;
      }
      RetrytechPlugin.shared.toggleCamera;
    }
  }

  // Video recording methods
  Future<void> onVideoRecordingStart() async {
    if (isUsingDeepAr) {
      if (isDeepARInitialized.value == false) {
        return;
      }
    }
    if (isRecording.value) return;

    try {
      if (isUsingDeepAr) {
        await deepArControllerPlus.value.startVideoRecording();
      } else {
        RetrytechPlugin.shared.startRecording;
      }
      _startAudioPlayback();
      isRecording.value = true;
      isStartingRecording.value = true;
      _startProgressTimer();
    } catch (e) {
      Loggers.error("Video recording start error: $e");
    }
  }

  Future<void> onVideoRecordingPause() async {
    if (!isRecording.value) return;

    RetrytechPlugin.shared.pauseRecording;
    _pauseAudioPlayback();
    isRecording.value = false;
    _progressTimer?.cancel();
  }

  Future<void> onVideoRecordingResume() async {
    if (isRecording.value) return;

    RetrytechPlugin.shared.resumeRecording;
    _resumeAudioPlayback();
    isRecording.value = true;
    _startProgressTimer();
  }

  Future<void> onVideoRecordingStop() async {
    if (isUsingDeepAr) {
      if (isDeepARInitialized.value == false) {
        return;
      }
    }

    if (!isStartingRecording.value) return;

    try {
      XFile file;

      _stopAudioPlayback();
      _progressTimer?.cancel();
      isRecording.value = false;
      isStartingRecording.value = false;
      progress.value = 0;

      showLoader();
      if (isUsingDeepAr) {
        final File _file =
            await deepArControllerPlus.value.stopVideoRecording();
        file = XFile(_file.path);
      } else {
        final String? videoPath = await RetrytechPlugin.shared.stopRecording;
        if (videoPath == null) {
          return showSnackBar('Capture File not found');
        }
        file = XFile(videoPath);
      }
      final XFile thumbnailPath =
          await MediaPickerHelper.shared.extractThumbnail(videoPath: file.path);
      MediaFile mediaFile = MediaFile(
          file: file, type: MediaType.video, thumbNail: thumbnailPath);

      stopLoader();

      switch (cameraType) {
        case CameraScreenType.post:
          await _handleReel(mediaFile, isCameraFile: true);
          break;
        case CameraScreenType.story:
          await handleVideoStory(mediaFile);
          break;
      }

      selectedMusic.value = null;
    } catch (e) {
      Loggers.error("Video recording stop error: $e");
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();

    final totalSteps = selectedSecond.value * (1000 ~/ _progressUpdateInterval);
    final increment = selectedSecond.value / totalSteps;

    _progressTimer = Timer.periodic(
      const Duration(milliseconds: _progressUpdateInterval),
      (timer) {
        if (progress.value < selectedSecond.value) {
          Loggers.info('Video Recording Second ${progress.value}');
          progress.value = (progress.value + increment)
              .clamp(0.0, selectedSecond.value.toDouble());
        } else {
          timer.cancel();
          onVideoRecordingStop();
        }
      },
    );
  }

  // Audio control methods
  void _startAudioPlayback() {
    if (selectedMusic.value == null) return;
    audioPlayer.seekTo(selectedMusic.value?.audioStartMS ?? 0);
    audioPlayer.startPlayer();
  }

  void _pauseAudioPlayback() => audioPlayer.pausePlayer();

  void _resumeAudioPlayback() => audioPlayer.startPlayer();

  void _stopAudioPlayback() => audioPlayer.stopPlayer();

  // UI interaction methods
  void onPlayPauseToggle({int? type}) {
    if (cameraType == CameraScreenType.post) {
      _toggleReelRecording();
    } else {
      if (type != null) {
        if (type == 1) {
          onVideoRecordingStart();
        } else {
          onVideoRecordingStop();
        }
      } else {
        capturePhoto();
      }
    }
  }

  void _toggleReelRecording() {
    if (!isStartingRecording.value) {
      onVideoRecordingStart();
    } else {
      if (isUsingDeepAr) {
        onVideoRecordingStop();
      } else {
        if (isRecording.value) {
          onVideoRecordingPause();
        } else {
          onVideoRecordingResume();
        }
      }
    }
  }

  Future<void> capturePhoto() async {
    if (isUsingDeepAr) {
      if (isDeepARInitialized.value == false) {
        return;
      }
    }
    if (isRecording.value) return;

    try {
      XFile file;
      if (isUsingDeepAr) {
        File photo = await deepArControllerPlus.value.takeScreenshot();
        print(photo.path);
        file = XFile(photo.path);
      } else {
        file = XFile(await RetrytechPlugin.shared.captureImage() ?? '');
      }
      await handleImageStory(
          MediaFile(file: file, type: MediaType.image, thumbNail: file));
    } catch (e) {
      Loggers.error("Photo capture error: $e");
    }
  }

  Future<void> _handleReel(MediaFile file, {bool isCameraFile = false}) async {
    showLoader();
    try {
      final content = PostStoryContent(
          type: PostStoryContentType.reel,
          content: file.file.path,
          thumbNail: file.thumbNail.path,
          sound: selectedMusic.value);
      stopLoader();
      navigateCameraEditScreen(content);
    } catch (e) {
      Loggers.error('Reel handling error: $e');
      stopLoader();
    }
  }

  Future<void> onMusicTap() async {
    final music = await Get.bottomSheet<SelectedMusic>(
        MusicSheet(videoDurationInSecond: selectedSecond.value),
        isScrollControlled: true);

    if (music != null) {
      selectedMusic.value = music;
      await _initializeAudioIfNeeded();
    }
  }

  void onSelectedMusicTap(SelectedMusic? music) async {
    if (music != null && !isStartingRecording.value) {
      final newMusic = await Get.bottomSheet<SelectedMusic>(
        SelectedMusicSheet(
            selectedMusic: music, totalVideoSecond: selectedSecond.value),
        isScrollControlled: true,
      );
      if (newMusic != null) {
        selectedMusic.value = newMusic;
        print('''
       New Music Value ${newMusic.toJson()}
        --------------------
        Selected Music Value ${selectedMusic.value?.toJson()}
        ''');
        await _initializeAudioIfNeeded();
      }
    }
  }

  void onDeleteMusic() {
    selectedMusic.value = null;
    audioPlayer.stopPlayer();
  }

  void onEffectToggle() {
    isEffectShow.toggle();
  }

  Future<void> onNavigateTextStory() async {
    final content = PostStoryContent(
      type: PostStoryContentType.storyText,
      content: '',
      thumbNail: '',
      duration: AppRes.storyImageAndTextDuration,
      sound: selectedMusic.value,
    );
    navigateCameraEditScreen(content);
  }

  Future<void> navigateCameraEditScreen(PostStoryContent content) async {
    await disposeCamera();
    if (isUsingDeepAr) {
      await Get.off(() => CameraEditScreen(content: content));
    } else {
      await Get.to(() => CameraEditScreen(content: content));
    }
    _resetAll();
  }

  void onBackFromScreen() {
    if (isStartingRecording.value || selectedMusic.value != null) {
      Get.bottomSheet(
        ConfirmationSheet(
            title: LKey.startAgainTitle.tr,
            description: LKey.startAgainMessage.tr,
            onTap: _resetAll,
            positiveText: LKey.startAgain.tr),
      );
    } else {
      Get.back();
    }
  }

  void _resetAll() {
    isEffectShow.value = false;
    _initCamera();
    progress.value = 0.0;
    selectedMusic.value = null;
    secondsList.value = AppRes.secondList;
    selectedSecond.value = secondsList.first;
    isSecondListShow.value = true;
    _progressTimer?.cancel();
    audioPlayer.release();
    isStartingRecording.value = false;
  }

  Future<void> applyARFilterEffect(DeepARFilters effect) async {
    selectedEffect.value = effect;

    bool loaderShown = false;
    try {
      final filterPath = effect.filterFile ?? '';

      if (effect.id == -1 || filterPath.isEmpty) {
        await deepArControllerPlus.value
            .switchEffectWithSlot(slot: 'effect', path: 'none');
        return;
      }

      if (_isAssetPath(filterPath) || filterPath.startsWith('packages/')) {
        await deepArControllerPlus.value.switchEffect(filterPath);
        return;
      }

      if (_isLocalFilePath(filterPath)) {
        await deepArControllerPlus.value.switchEffect(filterPath);
        return;
      }

      showLoader();
      loaderShown = true;

      final uri = Uri.tryParse(filterPath);
      final effectUrl =
          (uri != null && uri.hasScheme) ? filterPath : filterPath.addBaseURL();

      final fileInfo = await DefaultCacheManager().downloadFile(effectUrl);

      if (loaderShown) {
        stopLoader();
        loaderShown = false;
      }
      await deepArControllerPlus.value.switchEffect(fileInfo.file.path);
    } catch (e, stackTrace) {
      if (loaderShown) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          stopLoader();
        });
      }
      Loggers.error('Failed to apply AR filter: $e\n$stackTrace');
    }
  }

  bool _isAssetPath(String path) => path.startsWith('assets/');

  bool _isLocalFilePath(String path) {
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }
}
