class PersonModel {
  final String id;
  final String name;
  final DateTime? birthday;
  final DateTime? anniversary;
  final String? relationshipNotes;
  final List<String> tags;
  final DateTime createdAt;

  const PersonModel({
    required this.id,
    required this.name,
    this.birthday,
    this.anniversary,
    this.relationshipNotes,
    this.tags = const [],
    required this.createdAt,
  });

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      birthday: json['birthday'] != null ? DateTime.tryParse(json['birthday'] as String) : null,
      anniversary: json['anniversary'] != null ? DateTime.tryParse(json['anniversary'] as String) : null,
      relationshipNotes: json['relationshipNotes'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'birthday': birthday?.toIso8601String(),
      'anniversary': anniversary?.toIso8601String(),
      'relationshipNotes': relationshipNotes,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PersonModel copyWith({
    String? id,
    String? name,
    DateTime? Function()? birthday,
    DateTime? Function()? anniversary,
    String? Function()? relationshipNotes,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return PersonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      birthday: birthday != null ? birthday() : this.birthday,
      anniversary: anniversary != null ? anniversary() : this.anniversary,
      relationshipNotes: relationshipNotes != null ? relationshipNotes() : this.relationshipNotes,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
