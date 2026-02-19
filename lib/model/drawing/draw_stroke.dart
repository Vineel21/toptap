import 'dart:ui';

/// Represents a single drawing stroke with points and style
class DrawStroke {
  final String id;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final double opacity;
  final bool isEraser;

  DrawStroke({
    required this.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.opacity = 1.0,
    this.isEraser = false,
  });

  /// Create from JSON
  factory DrawStroke.fromJson(Map<String, dynamic> json) {
    return DrawStroke(
      id: json['id'] ?? '',
      points: (json['points'] as List?)
              ?.map((p) => Offset(
                    (p['x'] as num).toDouble(),
                    (p['y'] as num).toDouble(),
                  ))
              .toList() ??
          [],
      color: Color(json['color'] ?? 0xFFFFFFFF),
      strokeWidth:
          (json['strokeWidth'] as num?)?.toDouble() ?? 5.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      isEraser: json['isEraser'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points
          .map((p) => {
                'x': p.dx,
                'y': p.dy,
              })
          .toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'opacity': opacity,
      'isEraser': isEraser,
    };
  }

  /// Create a copy with modified properties
  DrawStroke copyWith({
    String? id,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    double? opacity,
    bool? isEraser,
  }) {
    return DrawStroke(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
      isEraser: isEraser ?? this.isEraser,
    );
  }

  /// Add a point to the stroke
  DrawStroke addPoint(Offset point) {
    return copyWith(
      points: [...points, point],
    );
  }
}
