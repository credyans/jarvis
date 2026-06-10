class TagModel {
  final String id;
  final String name;
  final String color;
  final String? emoji;
  final int sortOrder;

  const TagModel({
    required this.id,
    required this.name,
    required this.color,
    this.emoji,
    this.sortOrder = 0,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      emoji: json['emoji'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'emoji': emoji,
      'sortOrder': sortOrder,
    };
  }

  TagModel copyWith({
    String? id,
    String? name,
    String? color,
    String? Function()? emoji,
    int? sortOrder,
  }) {
    return TagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      emoji: emoji != null ? emoji() : this.emoji,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'TagModel(id: $id, name: $name, color: $color, '
        'emoji: $emoji, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TagModel) return false;
    return id == other.id &&
        name == other.name &&
        color == other.color &&
        emoji == other.emoji &&
        sortOrder == other.sortOrder;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, color, emoji, sortOrder);
  }
}
