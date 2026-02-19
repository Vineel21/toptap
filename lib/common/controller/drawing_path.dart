import 'package:flutter/material.dart';

/// Represents a single drawing stroke with path points and styling
class DrawingPath {
  /// List of points that make up this drawing path
  final List<Offset> points;

  /// Color of the drawing stroke
  final Color color;

  /// Width of the drawing stroke
  final double strokeWidth;

  /// Whether this path is an eraser stroke
  final bool isEraser;

  /// Unique identifier for this path
  final String id;

  DrawingPath({
    required this.points,
    required this.color,
    this.strokeWidth = 3.0,
    this.isEraser = false,
    String? id,
  }) : id = id ??
            DateTime.now()
                .millisecondsSinceEpoch
                .toString();

  /// Create a copy of this path with updated properties
  DrawingPath copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    bool? isEraser,
    String? id,
  }) {
    return DrawingPath(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isEraser: isEraser ?? this.isEraser,
      id: id ?? this.id,
    );
  }

  /// Add a point to this drawing path
  DrawingPath addPoint(Offset point) {
    final newPoints = List<Offset>.from(points)..add(point);
    return copyWith(points: newPoints);
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'points': points
          .map((p) => {'x': p.dx, 'y': p.dy})
          .toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'isEraser': isEraser,
      'id': id,
    };
  }

  /// Create from JSON
  factory DrawingPath.fromJson(Map<String, dynamic> json) {
    final pointsData = json['points'] as List;
    final points = pointsData
        .map((p) =>
            Offset(p['x'] as double, p['y'] as double))
        .toList();

    return DrawingPath(
      points: points,
      color: Color(json['color'] as int),
      strokeWidth: json['strokeWidth'] as double? ?? 3.0,
      isEraser: json['isEraser'] as bool? ?? false,
      id: json['id'] as String,
    );
  }

  @override
  String toString() {
    return 'DrawingPath(id: $id, points: ${points.length}, color: $color, isEraser: $isEraser)';
  }
}
