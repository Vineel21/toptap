class StickerModel {
  final String id;
  final String title;
  final String? username;
  final String imageUrl;
  final String? previewUrl;
  final int width;
  final int height;
  final bool isAnimated;

  StickerModel({
    required this.id,
    required this.title,
    this.username,
    required this.imageUrl,
    this.previewUrl,
    required this.width,
    required this.height,
    this.isAnimated = false,
  });

  /// Create from Giphy API response
  factory StickerModel.fromGiphy(
      Map<String, dynamic> json) {
    try {
      final images = json['images'] ?? {};
      final fixedHeight = images['fixed_height'] ?? {};
      final fixedHeightStill =
          images['fixed_height_still'] ??
              {}; // Static image
      final original = images['original'] ?? {};

      return StickerModel(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Sticker',
        username: json['username'],
        // Use 'fixed_height_still' for static image (first frame only)
        imageUrl: fixedHeightStill['url'] ??
            fixedHeight['url'] ??
            original['url'] ??
            '',
        previewUrl:
            fixedHeightStill['url'] ?? fixedHeight['webp'],
        width: int.tryParse(
                fixedHeightStill['width']?.toString() ??
                    fixedHeight['width']?.toString() ??
                    '200') ??
            200,
        height: int.tryParse(
                fixedHeightStill['height']?.toString() ??
                    fixedHeight['height']?.toString() ??
                    '200') ??
            200,
        isAnimated:
            false, // Always false since we're using still images
      );
    } catch (e) {
      // Fallback sticker
      return StickerModel(
        id: 'error',
        title: 'Error loading sticker',
        imageUrl: '',
        width: 200,
        height: 200,
      );
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'username': username,
        'imageUrl': imageUrl,
        'previewUrl': previewUrl,
        'width': width,
        'height': height,
        'isAnimated': isAnimated,
      };

  factory StickerModel.fromJson(
          Map<String, dynamic> json) =>
      StickerModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        username: json['username'],
        imageUrl: json['imageUrl'] ?? '',
        previewUrl: json['previewUrl'],
        width: json['width'] ?? 200,
        height: json['height'] ?? 200,
        isAnimated: json['isAnimated'] ?? false,
      );
}
