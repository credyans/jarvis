import 'package:jarvis/features/tasks/domain/entities/tag.dart';

class TagModel extends Tag {
  const TagModel({
    required super.id,
    required super.name,
    required super.color,
    super.emoji,
    super.sortOrder = 0,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      color: json['color'] as String? ?? '#CCCCCC',
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
}
