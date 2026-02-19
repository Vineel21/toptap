import 'dart:async';
import 'package:flutter/material.dart';

/// Mixin to optimize dragging performance for camera overlays
/// Prevents black screen issues during element dragging by throttling updates
mixin DragOptimizationMixin<T extends StatefulWidget>
    on State<T> {
  // Throttling configuration
  Timer? _updateTimer;
  static const Duration _updateDelay =
      Duration(milliseconds: 16); // 60fps max

  // Pending updates queue
  final Map<String, VoidCallback> _pendingUpdates = {};

  @override
  void dispose() {
    // Clean up timer when widget is disposed
    _updateTimer?.cancel();
    _pendingUpdates.clear();
    super.dispose();
  }

  /// Schedule a throttled update for an element
  /// [elementId] - unique identifier for the element being updated
  /// [updateCallback] - the function that performs the actual update
  void scheduleElementUpdate(
      String elementId, VoidCallback updateCallback) {
    // Store the latest update for this element
    _pendingUpdates[elementId] = updateCallback;

    // Cancel existing timer
    _updateTimer?.cancel();

    // Schedule batch update with throttling
    _updateTimer = Timer(_updateDelay, () {
      _executePendingUpdates();
    });
  }

  /// Force immediate update for all pending elements (used for gesture end)
  void forceElementUpdates() {
    _updateTimer?.cancel();
    _executePendingUpdates();
  }

  /// Execute all pending updates in a batch
  void _executePendingUpdates() {
    if (_pendingUpdates.isNotEmpty) {
      // Execute all pending updates
      for (final updateCallback in _pendingUpdates.values) {
        updateCallback();
      }

      // Clear the queue
      _pendingUpdates.clear();
    }
  }

  /// Create optimized pan update handler for any draggable element
  /// [elementId] - unique identifier for the element
  /// [currentPosition] - current position of the element
  /// [onPositionUpdate] - callback to update element position
  /// [bounds] - optional screen bounds for clamping
  void Function(DragUpdateDetails)
      createOptimizedPanUpdate({
    required String elementId,
    required Offset currentPosition,
    required void Function(Offset newPosition)
        onPositionUpdate,
    Rect? bounds,
  }) {
    return (DragUpdateDetails details) {
      // Calculate new position
      final newPosition = Offset(
        currentPosition.dx + details.delta.dx,
        currentPosition.dy + details.delta.dy,
      );

      // Apply bounds clamping if provided
      final clampedPosition = bounds != null
          ? Offset(
              newPosition.dx
                  .clamp(bounds.left, bounds.right),
              newPosition.dy
                  .clamp(bounds.top, bounds.bottom),
            )
          : newPosition;

      // Schedule throttled update
      scheduleElementUpdate(elementId, () {
        onPositionUpdate(clampedPosition);
      });
    };
  }

  /// Create optimized pan end handler
  void Function(DragEndDetails) createOptimizedPanEnd() {
    return (DragEndDetails details) {
      // Force immediate update when gesture ends
      forceElementUpdates();
    };
  }
}
