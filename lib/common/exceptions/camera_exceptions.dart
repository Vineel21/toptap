/// Custom exceptions for camera operations
/// Provides specific error types for better error handling and recovery strategies

/// Base exception for all camera-related errors
abstract class CameraException implements Exception {
  final String message;
  final String? details;
  final Object? originalError;

  const CameraException(this.message,
      {this.details, this.originalError});

  @override
  String toString() {
    if (details != null) {
      return 'CameraException: $message\nDetails: $details';
    }
    return 'CameraException: $message';
  }
}

/// Exception thrown when video processing fails
class VideoProcessingException extends CameraException {
  final String? videoPath;
  final String processingStep;

  const VideoProcessingException(
    String message, {
    this.videoPath,
    required this.processingStep,
    String? details,
    Object? originalError,
  }) : super(message,
            details: details, originalError: originalError);

  @override
  String toString() {
    final buffer =
        StringBuffer('VideoProcessingException: $message');
    if (videoPath != null)
      buffer.write('\nVideo Path: $videoPath');
    buffer.write('\nProcessing Step: $processingStep');
    if (details != null)
      buffer.write('\nDetails: $details');
    return buffer.toString();
  }
}

/// Exception thrown when camera permissions are denied
class PermissionDeniedException extends CameraException {
  final String permissionType;
  final bool isPermanentlyDenied;

  const PermissionDeniedException(
    String message, {
    required this.permissionType,
    this.isPermanentlyDenied = false,
    String? details,
  }) : super(message, details: details);

  @override
  String toString() {
    final buffer =
        StringBuffer('PermissionDeniedException: $message');
    buffer.write('\nPermission Type: $permissionType');
    if (isPermanentlyDenied) {
      buffer.write(
          '\nStatus: Permanently denied - requires settings change');
    }
    if (details != null)
      buffer.write('\nDetails: $details');
    return buffer.toString();
  }
}

/// Exception thrown when native channel communication fails
class NativeChannelException extends CameraException {
  final String channelName;
  final String methodName;
  final Map<String, dynamic>? arguments;

  const NativeChannelException(
    String message, {
    required this.channelName,
    required this.methodName,
    this.arguments,
    String? details,
    Object? originalError,
  }) : super(message,
            details: details, originalError: originalError);

  @override
  String toString() {
    final buffer =
        StringBuffer('NativeChannelException: $message');
    buffer.write('\nChannel: $channelName');
    buffer.write('\nMethod: $methodName');
    if (arguments != null) {
      buffer.write('\nArguments: $arguments');
    }
    if (details != null)
      buffer.write('\nDetails: $details');
    return buffer.toString();
  }
}

/// Exception thrown when camera initialization fails
class CameraInitializationException
    extends CameraException {
  final String initializationStep;
  final bool isRecoverable;

  const CameraInitializationException(
    String message, {
    required this.initializationStep,
    this.isRecoverable = true,
    String? details,
    Object? originalError,
  }) : super(message,
            details: details, originalError: originalError);

  @override
  String toString() {
    final buffer = StringBuffer(
        'CameraInitializationException: $message');
    buffer.write(
        '\nInitialization Step: $initializationStep');
    buffer.write('\nRecoverable: $isRecoverable');
    if (details != null)
      buffer.write('\nDetails: $details');
    return buffer.toString();
  }
}

/// Exception thrown when file operations fail
class FileOperationException extends CameraException {
  final String filePath;
  final String operation;

  const FileOperationException(
    String message, {
    required this.filePath,
    required this.operation,
    String? details,
    Object? originalError,
  }) : super(message,
            details: details, originalError: originalError);

  @override
  String toString() {
    final buffer =
        StringBuffer('FileOperationException: $message');
    buffer.write('\nFile Path: $filePath');
    buffer.write('\nOperation: $operation');
    if (details != null)
      buffer.write('\nDetails: $details');
    return buffer.toString();
  }
}

/// Exception thrown when recording operations fail
class RecordingException extends CameraException {
  final String recordingState;
  final Duration? duration;

  const RecordingException(
    String message, {
    required this.recordingState,
    this.duration,
    String? details,
    Object? originalError,
  }) : super(message,
            details: details, originalError: originalError);

  @override
  String toString() {
    final buffer =
        StringBuffer('RecordingException: $message');
    buffer.write('\nRecording State: $recordingState');
    if (duration != null) {
      buffer.write('\nDuration: ${duration!.inSeconds}s');
    }
    if (details != null)
      buffer.write('\nDetails: $details');
    return buffer.toString();
  }
}

/// Exception thrown when overlay/editing operations fail
class OverlayException extends CameraException {
  final String overlayType;
  final int elementCount;

  const OverlayException(
    String message, {
    required this.overlayType,
    this.elementCount = 0,
    String? details,
    Object? originalError,
  }) : super(message,
            details: details, originalError: originalError);

  @override
  String toString() {
    final buffer =
        StringBuffer('OverlayException: $message');
    buffer.write('\nOverlay Type: $overlayType');
    buffer.write('\nElement Count: $elementCount');
    if (details != null)
      buffer.write('\nDetails: $details');
    return buffer.toString();
  }
}

/// Exception thrown when data extraction/type casting fails
class DataExtractionException extends CameraException {
  final String fieldName;
  final String actualType;
  final String expectedType;

  const DataExtractionException(
    String message, {
    required this.fieldName,
    required this.actualType,
    required this.expectedType,
    String? details,
    Object? originalError,
  }) : super(message,
            details: details, originalError: originalError);

  @override
  String toString() {
    final buffer =
        StringBuffer('DataExtractionException: $message');
    buffer.write('\nField Name: $fieldName');
    buffer.write('\nExpected Type: $expectedType');
    buffer.write('\nActual Type: $actualType');
    if (details != null)
      buffer.write('\nDetails: $details');
    return buffer.toString();
  }
}
