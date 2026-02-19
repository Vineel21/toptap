/// Enum to define different editing modes for media editing
enum EditingMode {
  /// No editing tool selected
  none,

  /// Text editing tool for adding text overlays
  text,

  /// Sticker tool for adding sticker elements
  sticker,

  /// Drawing tool for freehand drawing
  drawing,
}

/// Extension to provide convenient methods for EditingMode
extension EditingModeExtension on EditingMode {
  /// Get a human-readable name for the editing mode
  String get displayName {
    switch (this) {
      case EditingMode.none:
        return 'None';
      case EditingMode.text:
        return 'Text';
      case EditingMode.sticker:
        return 'Sticker';
      case EditingMode.drawing:
        return 'Draw';
    }
  }

  /// Check if this mode requires user interaction
  bool get requiresInteraction {
    return this != EditingMode.none;
  }
}
