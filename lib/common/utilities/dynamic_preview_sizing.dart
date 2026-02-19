import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dynamic preview sizing utility that calculates optimal camera preview dimensions
/// and aspect ratios based on actual device screen size and camera capabilities.
///
/// This ensures overlay positioning works correctly across all device screen sizes
/// and orientations by providing device-responsive calculations.
class DynamicPreviewSizing {
  static const String _tag = 'DynamicPreviewSizing';

  /// Calculate optimal camera preview dimensions based on device screen and camera preview size
  static CameraPreviewDimensions
      calculateOptimalPreviewDimensions({
    required Size deviceScreenSize,
    required Size cameraPreviewSize,
    required Orientation deviceOrientation,
    bool considerSafeArea = true,
  }) {
    print('$_tag: Calculating optimal preview dimensions');
    print(
        '   - Device screen: ${deviceScreenSize.width}x${deviceScreenSize.height}');
    print(
        '   - Camera preview: ${cameraPreviewSize.width}x${cameraPreviewSize.height}');
    print('   - Device orientation: $deviceOrientation');

    // Calculate actual usable screen dimensions
    final usableScreenSize = _calculateUsableScreenSize(
      deviceScreenSize: deviceScreenSize,
      considerSafeArea: considerSafeArea,
    );

    // Calculate camera and screen aspect ratios
    final cameraAspectRatio =
        cameraPreviewSize.width / cameraPreviewSize.height;
    final screenAspectRatio =
        usableScreenSize.width / usableScreenSize.height;

    print(
        '   - Camera aspect ratio: ${cameraAspectRatio.toStringAsFixed(3)}');
    print(
        '   - Screen aspect ratio: ${screenAspectRatio.toStringAsFixed(3)}');

    // Determine optimal preview display size that maintains aspect ratio
    Size optimalPreviewSize;
    PreviewScaleMode scaleMode;

    if ((cameraAspectRatio - screenAspectRatio).abs() <
        0.05) {
      // Aspect ratios are very close - use full screen
      optimalPreviewSize = usableScreenSize;
      scaleMode = PreviewScaleMode.fillScreen;
      print(
          '   - Using fill screen mode (aspect ratios match)');
    } else if (cameraAspectRatio > screenAspectRatio) {
      // Camera is wider than screen - fit to screen width
      optimalPreviewSize = Size(
        usableScreenSize.width,
        usableScreenSize.width / cameraAspectRatio,
      );
      scaleMode = PreviewScaleMode.fitWidth;
      print(
          '   - Using fit width mode (camera wider than screen)');
    } else {
      // Camera is taller than screen - fit to screen height
      optimalPreviewSize = Size(
        usableScreenSize.height * cameraAspectRatio,
        usableScreenSize.height,
      );
      scaleMode = PreviewScaleMode.fitHeight;
      print(
          '   - Using fit height mode (camera taller than screen)');
    }

    // Calculate scaling factors for coordinate transformation
    final horizontalScale =
        optimalPreviewSize.width / cameraPreviewSize.width;
    final verticalScale = optimalPreviewSize.height /
        cameraPreviewSize.height;

    // Calculate offsets for centering preview on screen
    final horizontalOffset = (usableScreenSize.width -
            optimalPreviewSize.width) /
        2;
    final verticalOffset = (usableScreenSize.height -
            optimalPreviewSize.height) /
        2;

    final dimensions = CameraPreviewDimensions(
      deviceScreenSize: deviceScreenSize,
      usableScreenSize: usableScreenSize,
      cameraPreviewSize: cameraPreviewSize,
      optimalPreviewSize: optimalPreviewSize,
      cameraAspectRatio: cameraAspectRatio,
      screenAspectRatio: screenAspectRatio,
      horizontalScale: horizontalScale,
      verticalScale: verticalScale,
      horizontalOffset: horizontalOffset,
      verticalOffset: verticalOffset,
      scaleMode: scaleMode,
      deviceOrientation: deviceOrientation,
    );

    print('$_tag: Calculated dimensions:');
    print(
        '   - Optimal preview size: ${optimalPreviewSize.width.toStringAsFixed(1)}x${optimalPreviewSize.height.toStringAsFixed(1)}');
    print(
        '   - Scale factors: H=${horizontalScale.toStringAsFixed(3)}, V=${verticalScale.toStringAsFixed(3)}');
    print(
        '   - Offsets: H=${horizontalOffset.toStringAsFixed(1)}, V=${verticalOffset.toStringAsFixed(1)}');

    return dimensions;
  }

  /// Calculate dynamic UI canvas size for consistent overlay positioning
  static Size calculateUICanvasSize({
    required Size deviceScreenSize,
    Orientation? deviceOrientation,
    bool forVideoEditing = false,
  }) {
    print('$_tag: Calculating UI canvas size');
    print(
        '   - Device screen: ${deviceScreenSize.width}x${deviceScreenSize.height}');
    print('   - For video editing: $forVideoEditing');

    if (forVideoEditing) {
      // For video editing, use actual screen dimensions for accurate touch coordinates
      final canvasSize = Size(
          deviceScreenSize.width, deviceScreenSize.height);
      print(
          '   - Video editing canvas: ${canvasSize.width}x${canvasSize.height}');
      return canvasSize;
    } else {
      // For general preview, consider safe areas and navigation
      final usableSize = _calculateUsableScreenSize(
        deviceScreenSize: deviceScreenSize,
        considerSafeArea: true,
      );
      print(
          '   - General canvas: ${usableSize.width}x${usableSize.height}');
      return usableSize;
    }
  }

  /// Calculate video dimensions for processing based on camera capabilities
  static Size calculateVideoDimensions({
    required Size cameraPreviewSize,
    required Orientation deviceOrientation,
    VideoQualityPreference quality =
        VideoQualityPreference.balanced,
  }) {
    print('$_tag: Calculating video dimensions');
    print(
        '   - Camera preview: ${cameraPreviewSize.width}x${cameraPreviewSize.height}');
    print('   - Quality preference: $quality');

    Size videoDimensions;

    switch (quality) {
      case VideoQualityPreference.highQuality:
        // Use camera's full resolution or scale down to reasonable maximum
        if (cameraPreviewSize.width *
                cameraPreviewSize.height >
            1920 * 1080) {
          // Scale down to Full HD while maintaining aspect ratio
          final aspectRatio = cameraPreviewSize.width /
              cameraPreviewSize.height;
          if (aspectRatio > 1.0) {
            videoDimensions =
                Size(1920, 1920 / aspectRatio);
          } else {
            videoDimensions =
                Size(1080 * aspectRatio, 1080);
          }
        } else {
          videoDimensions = cameraPreviewSize;
        }
        break;

      case VideoQualityPreference.balanced:
        // Use HD resolution with proper aspect ratio
        final aspectRatio = cameraPreviewSize.width /
            cameraPreviewSize.height;
        if (aspectRatio > 1.0) {
          videoDimensions = Size(1280, 1280 / aspectRatio);
        } else {
          videoDimensions = Size(720 * aspectRatio, 720);
        }
        break;

      case VideoQualityPreference.performance:
        // Use lower resolution for smooth performance
        final aspectRatio = cameraPreviewSize.width /
            cameraPreviewSize.height;
        if (aspectRatio > 1.0) {
          videoDimensions = Size(960, 960 / aspectRatio);
        } else {
          videoDimensions = Size(540 * aspectRatio, 540);
        }
        break;
    }

    print(
        '   - Calculated video dimensions: ${videoDimensions.width.toStringAsFixed(0)}x${videoDimensions.height.toStringAsFixed(0)}');
    return videoDimensions;
  }

  /// Transform UI coordinates to video coordinates for overlay processing
  static Offset transformUICoordinateToVideo({
    required Offset uiCoordinate,
    required CameraPreviewDimensions previewDimensions,
    required Size videoDimensions,
  }) {
    // Account for preview offset and scale to get actual preview-relative coordinate
    final previewRelativeX = (uiCoordinate.dx -
            previewDimensions.horizontalOffset) /
        previewDimensions.horizontalScale;
    final previewRelativeY = (uiCoordinate.dy -
            previewDimensions.verticalOffset) /
        previewDimensions.verticalScale;

    // Scale to video dimensions
    final videoX = (previewRelativeX /
            previewDimensions.cameraPreviewSize.width) *
        videoDimensions.width;
    final videoY = (previewRelativeY /
            previewDimensions.cameraPreviewSize.height) *
        videoDimensions.height;

    return Offset(videoX, videoY);
  }

  /// Transform video coordinates back to UI coordinates for display
  static Offset transformVideoCoordinateToUI({
    required Offset videoCoordinate,
    required CameraPreviewDimensions previewDimensions,
    required Size videoDimensions,
  }) {
    // Scale from video dimensions to preview dimensions
    final previewRelativeX =
        (videoCoordinate.dx / videoDimensions.width) *
            previewDimensions.cameraPreviewSize.width;
    final previewRelativeY =
        (videoCoordinate.dy / videoDimensions.height) *
            previewDimensions.cameraPreviewSize.height;

    // Account for preview scale and offset to get UI coordinate
    final uiX = (previewRelativeX *
            previewDimensions.horizontalScale) +
        previewDimensions.horizontalOffset;
    final uiY = (previewRelativeY *
            previewDimensions.verticalScale) +
        previewDimensions.verticalOffset;

    return Offset(uiX, uiY);
  }

  /// Calculate usable screen size considering safe areas and system UI
  static Size _calculateUsableScreenSize({
    required Size deviceScreenSize,
    bool considerSafeArea = true,
  }) {
    if (!considerSafeArea) {
      return deviceScreenSize;
    }

    // Get safe area insets from MediaQuery if available
    try {
      final context = Get.context;
      if (context != null) {
        final mediaQuery = MediaQuery.of(context);
        final padding = mediaQuery.padding;
        final viewInsets = mediaQuery.viewInsets;

        final usableWidth = deviceScreenSize.width -
            padding.left -
            padding.right;
        final usableHeight = deviceScreenSize.height -
            padding.top -
            padding.bottom -
            viewInsets.bottom;

        return Size(usableWidth, usableHeight);
      }
    } catch (e) {
      print(
          '$_tag: Could not get MediaQuery, using device screen size: $e');
    }

    // Fallback: estimate common safe area insets
    final estimatedSafeAreaTop = deviceScreenSize.height *
        0.05; // ~5% for status bar
    final estimatedSafeAreaBottom =
        deviceScreenSize.height *
            0.03; // ~3% for navigation
    final usableHeight = deviceScreenSize.height -
        estimatedSafeAreaTop -
        estimatedSafeAreaBottom;

    return Size(deviceScreenSize.width, usableHeight);
  }

  /// Get current device screen dimensions and orientation
  static DeviceDisplayInfo getCurrentDeviceDisplayInfo() {
    final window =
        ui.PlatformDispatcher.instance.views.first;
    final size =
        window.physicalSize / window.devicePixelRatio;
    final orientation = size.width > size.height
        ? Orientation.landscape
        : Orientation.portrait;

    return DeviceDisplayInfo(
      screenSize: size,
      orientation: orientation,
      devicePixelRatio: window.devicePixelRatio,
      physicalSize: window.physicalSize,
    );
  }
}

/// Data class containing all calculated camera preview dimensions and scaling factors
class CameraPreviewDimensions {
  final Size deviceScreenSize;
  final Size usableScreenSize;
  final Size cameraPreviewSize;
  final Size optimalPreviewSize;
  final double cameraAspectRatio;
  final double screenAspectRatio;
  final double horizontalScale;
  final double verticalScale;
  final double horizontalOffset;
  final double verticalOffset;
  final PreviewScaleMode scaleMode;
  final Orientation deviceOrientation;

  const CameraPreviewDimensions({
    required this.deviceScreenSize,
    required this.usableScreenSize,
    required this.cameraPreviewSize,
    required this.optimalPreviewSize,
    required this.cameraAspectRatio,
    required this.screenAspectRatio,
    required this.horizontalScale,
    required this.verticalScale,
    required this.horizontalOffset,
    required this.verticalOffset,
    required this.scaleMode,
    required this.deviceOrientation,
  });

  /// Get a summary of the preview dimensions for debugging
  String get debugSummary {
    return '''
CameraPreviewDimensions:
  Device Screen: ${deviceScreenSize.width.toStringAsFixed(0)}x${deviceScreenSize.height.toStringAsFixed(0)}
  Usable Screen: ${usableScreenSize.width.toStringAsFixed(0)}x${usableScreenSize.height.toStringAsFixed(0)}
  Camera Preview: ${cameraPreviewSize.width.toStringAsFixed(0)}x${cameraPreviewSize.height.toStringAsFixed(0)}
  Optimal Preview: ${optimalPreviewSize.width.toStringAsFixed(0)}x${optimalPreviewSize.height.toStringAsFixed(0)}
  Aspect Ratios: Camera=${cameraAspectRatio.toStringAsFixed(3)}, Screen=${screenAspectRatio.toStringAsFixed(3)}
  Scale Factors: H=${horizontalScale.toStringAsFixed(3)}, V=${verticalScale.toStringAsFixed(3)}
  Offsets: H=${horizontalOffset.toStringAsFixed(1)}, V=${verticalOffset.toStringAsFixed(1)}
  Scale Mode: $scaleMode
  Orientation: $deviceOrientation''';
  }
}

/// Device display information
class DeviceDisplayInfo {
  final Size screenSize;
  final Orientation orientation;
  final double devicePixelRatio;
  final Size physicalSize;

  const DeviceDisplayInfo({
    required this.screenSize,
    required this.orientation,
    required this.devicePixelRatio,
    required this.physicalSize,
  });
}

/// Preview scaling modes for different aspect ratio scenarios
enum PreviewScaleMode {
  fillScreen, // Preview fills entire screen (aspect ratios match)
  fitWidth, // Preview fits to screen width (camera wider than screen)
  fitHeight, // Preview fits to screen height (camera taller than screen)
}

/// Video quality preferences for dimension calculation
enum VideoQualityPreference {
  highQuality, // Maximum quality, larger file sizes
  balanced, // Good quality with reasonable file sizes
  performance, // Lower quality for smooth performance
}
