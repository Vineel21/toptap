/// Application configuration constants
/// Centralizes all hardcoded values for easier maintenance and feature updates

class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  /// Video recording durations
  static const int videoDuration15s = 15;
  static const int videoDuration60s = 60;
  static const int videoDuration10m = 600;

  /// Default video duration
  static const int defaultVideoDuration = videoDuration15s;

  /// Video recording settings
  static const int maxVideoRecordingDuration =
      videoDuration10m;
  static const int minVideoRecordingDuration = 1;
  static const int defaultVideoQuality = 720; // HD quality
  static const int videoFrameRate = 30;

  /// Photo settings
  static const int defaultPhotoQuality =
      95; // JPEG quality percentage
  static const int maxPhotoWidth = 1920;
  static const int maxPhotoHeight = 1080;

  /// Timer settings
  static const List<int> availableTimerDurations = [
    0,
    3,
    5,
    10
  ]; // seconds
  static const int defaultTimerDuration = 0; // no timer

  /// Zoom settings
  static const double minZoomLevel = 1.0;
  static const double maxZoomLevel = 10.0;
  static const double defaultZoomLevel = 1.0;
  static const double zoomSensitivity =
      0.05; // Minimum zoom change threshold

  /// Filter and effect settings
  static const double defaultFilterIntensity = 1.0;
  static const double defaultEffectIntensity = 1.0;
  static const double minFilterIntensity = 0.0;
  static const double maxFilterIntensity = 2.0;

  /// Recording progress settings
  static const int recordingProgressUpdateIntervalMs = 100;
  static const int recordingTimerTickIntervalMs = 1000;

  /// File management settings
  static const int tempFileCleanupThresholdHours = 1;
  static const int minValidVideoFileSizeBytes =
      100000; // 100KB
  static const int minValidPhotoFileSizeBytes =
      50000; // 50KB
  static const int maxRetainedTempFiles = 10;

  /// UI settings
  static const int snackbarDurationShort = 2; // seconds
  static const int snackbarDurationMedium = 3; // seconds
  static const int snackbarDurationLong = 5; // seconds
  static const int processingDialogTimeoutSeconds =
      15; // Further reduced for faster UX

  /// Camera initialization settings
  static const int cameraInitRetryCount = 10;
  static const int cameraInitRetryDelayMs =
      300; // Reduced from 500
  static const int cameraInitTimeoutSeconds = 5;

  /// Video processing settings
  static const int videoProcessingTimeoutSeconds =
      20; // Further reduced from 30
  static const int overlayProcessingTimeoutSeconds =
      10; // Further reduced from 15
  static const int fileValidationDelayMs =
      100; // Further reduced from 200
  static const int fallbackProcessingDelayMs =
      200; // Further reduced from 500

  /// Method channel names
  static const String cameraChannelName =
      'com.fourtech.toptap/camera';
  static const String videoProcessingChannelName =
      'com.fourtech.toptap/video_processing';
  static const String permissionsChannelName =
      'com.fourtech.toptap/permissions';

  /// File naming patterns
  static const String photoFilePrefix = 'IMG_';
  static const String videoFilePrefix = 'VID_';
  static const String processedVideoSuffix = '_processed';
  static const String overlayMetadataSuffix =
      '_overlay_metadata.json';

  /// File extensions
  static const String photoFileExtension = '.jpg';
  static const String videoFileExtension = '.mp4';
  static const String metadataFileExtension = '.json';

  /// Error retry settings
  static const int maxErrorRetryAttempts = 3;
  static const int errorRetryDelayMs = 1000;
  static const int networkErrorRetryDelayMs = 5000;

  /// Performance settings
  static const int maxConcurrentVideoProcessing = 1;
  static const int textureUpdateIntervalMs = 16; // ~60fps
  static const int uiUpdateDebounceMs = 100;

  /// Audio settings
  static const double defaultAudioVolume = 1.0;
  static const int audioSampleRate = 44100;
  static const int audioBitRate = 128000; // 128 kbps

  /// Preview settings
  static const double previewAspectRatio =
      16.0 / 9.0; // Default 16:9
  static const int previewTextureUpdateDelayMs =
      33; // ~30fps

  /// Debug settings
  static const bool enableDebugLogging = true;
  static const bool enablePerformanceLogging = false;
  static const bool enableCrashReporting = true;

  /// Available camera modes
  static const List<String> availableModes = [
    'Photo',
    '15s',
    '60s',
    '10m',
  ];

  /// Available filters
  static const List<String> availableFilters = [
    'none',
    'beauty',
    'sepia',
    'blackWhite',
    'vintage',
    'cool',
    'warm',
    'brightness',
    'contrast',
    'saturation',
    'blur',
  ];

  /// Available AR effects
  static const List<String> availableAREffects = [
    'none',
    'beauty_plus',
    'dog_mask',
    'cat_mask',
    'makeup',
  ];

  /// Flash modes
  static const List<String> availableFlashModes = [
    'off',
    'on',
    'auto',
  ];

  /// Helper methods for validation

  /// Check if video duration is valid
  static bool isValidVideoDuration(int duration) {
    return duration == videoDuration15s ||
        duration == videoDuration60s ||
        duration == videoDuration10m;
  }

  /// Check if zoom level is valid
  static bool isValidZoomLevel(double zoom) {
    return zoom >= minZoomLevel && zoom <= maxZoomLevel;
  }

  /// Check if timer duration is valid
  static bool isValidTimerDuration(int duration) {
    return availableTimerDurations.contains(duration);
  }

  /// Check if filter is available
  static bool isValidFilter(String filter) {
    return availableFilters.contains(filter);
  }

  /// Check if AR effect is available
  static bool isValidAREffect(String effect) {
    return availableAREffects.contains(effect);
  }

  /// Check if flash mode is available
  static bool isValidFlashMode(String mode) {
    return availableFlashModes.contains(mode);
  }

  /// Get mode display name
  static String getModeDisplayName(String mode) {
    switch (mode) {
      case '15s':
        return '15 seconds';
      case '60s':
        return '1 minute';
      case '10m':
        return '10 minutes';
      case 'Photo':
        return 'Photo';
      default:
        return mode;
    }
  }

  /// Get video duration from mode
  static int getVideoDurationFromMode(String mode) {
    switch (mode) {
      case '15s':
        return videoDuration15s;
      case '60s':
        return videoDuration60s;
      case '10m':
        return videoDuration10m;
      default:
        return 0; // Photo mode
    }
  }

  /// Get mode from video duration
  static String getModeFromVideoDuration(int duration) {
    switch (duration) {
      case videoDuration15s:
        return '15s';
      case videoDuration60s:
        return '60s';
      case videoDuration10m:
        return '10m';
      default:
        return 'Photo';
    }
  }
}
