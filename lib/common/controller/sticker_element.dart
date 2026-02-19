import 'package:flutter/material.dart';

/// Represents a sticker element that can be placed and manipulated on media
class StickerElement {
  /// Asset path for the sticker image
  final String assetPath;

  /// Position on the screen (center point)
  final Offset position;

  /// Scale factor for the sticker size
  final double scale;

  /// Rotation angle in radians
  final double rotation;

  /// Unique identifier
  final String id;

  /// Whether this element is currently selected
  final bool isSelected;

  /// Optional sticker category for organization
  final String? category;

  /// Whether this is a network image URL instead of asset
  final bool isNetworkImage;

  const StickerElement({
    required this.assetPath,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    String? id,
    this.isSelected = false,
    this.category,
    this.isNetworkImage = false,
  }) : id = id ?? '';

  /// Create a copy with updated properties
  StickerElement copyWith({
    String? assetPath,
    Offset? position,
    double? scale,
    double? rotation,
    String? id,
    bool? isSelected,
    String? category,
    bool? isNetworkImage,
  }) {
    return StickerElement(
      assetPath: assetPath ?? this.assetPath,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      id: id ?? this.id,
      isSelected: isSelected ?? this.isSelected,
      category: category ?? this.category,
      isNetworkImage: isNetworkImage ?? this.isNetworkImage,
    );
  }

  /// Get the appropriate image widget for this sticker
  Widget getImageWidget({double? width, double? height}) {
    if (isNetworkImage) {
      return Image.network(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.broken_image,
            size: width ?? 50,
            color: Colors.grey,
          );
        },
      );
    } else {
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.image_not_supported,
            size: width ?? 50,
            color: Colors.grey,
          );
        },
      );
    }
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'assetPath': assetPath,
      'position': {'x': position.dx, 'y': position.dy},
      'scale': scale,
      'rotation': rotation,
      'id': id,
      'isSelected': isSelected,
      'category': category,
      'isNetworkImage': isNetworkImage,
    };
  }

  /// Create from JSON
  factory StickerElement.fromJson(
      Map<String, dynamic> json) {
    final positionData =
        json['position'] as Map<String, dynamic>;

    return StickerElement(
      assetPath: json['assetPath'] as String,
      position: Offset(
        positionData['x'] as double,
        positionData['y'] as double,
      ),
      scale: json['scale'] as double? ?? 1.0,
      rotation: json['rotation'] as double? ?? 0.0,
      id: json['id'] as String? ?? '',
      isSelected: json['isSelected'] as bool? ?? false,
      category: json['category'] as String?,
      isNetworkImage:
          json['isNetworkImage'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'StickerElement(id: $id, asset: "$assetPath", position: $position, selected: $isSelected)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StickerElement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
