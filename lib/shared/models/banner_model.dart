class BannerModel {
  final String id;
  final String title;
  final String imageUrl;
  final String actionType; // 'radio' | 'url' | 'category'
  final String? targetValue;
  final bool isActive;
  final int sortOrder;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.actionType = 'radio',
    this.targetValue,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? '',
      actionType: json['action_type'] ?? 'radio',
      targetValue: json['target_value'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'action_type': actionType,
      'target_value': targetValue,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}
