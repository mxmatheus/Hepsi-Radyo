class BadgeModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String requiredMetric;
  final int requiredValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredMetric,
    required this.requiredValue,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json, {bool isUnlocked = false, DateTime? unlockedAt}) {
    return BadgeModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'star',
      requiredMetric: json['required_metric'] ?? '',
      requiredValue: json['required_value'] ?? 1,
      isUnlocked: isUnlocked,
      unlockedAt: unlockedAt,
    );
  }

  BadgeModel copyWith({bool? isUnlocked, DateTime? unlockedAt}) {
    return BadgeModel(
      id: id,
      title: title,
      description: description,
      icon: icon,
      requiredMetric: requiredMetric,
      requiredValue: requiredValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
