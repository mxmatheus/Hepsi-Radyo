class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final int sortOrder;
  final int radioCount;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon = 'radio',
    this.color = '#0B3D2E',
    this.sortOrder = 0,
    this.radioCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? json['name'],
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'radio',
      color: json['color'] ?? '#0B3D2E',
      sortOrder: json['sort_order'] ?? 0,
      radioCount: json['radio_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
      'radio_count': radioCount,
    };
  }
}
