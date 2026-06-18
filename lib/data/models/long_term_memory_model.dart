class LongTermMemoryModel {
  final String id;
  final String title;
  final String body;
  final String type; // e.g. milestone, travel, career, purchase, health, financial, people_shared
  final List<String> tags;
  final List<String> connectedPeopleIds;
  final String? place;
  final DateTime date;
  final DateTime createdAt;

  const LongTermMemoryModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.tags = const [],
    this.connectedPeopleIds = const [],
    this.place,
    required this.date,
    required this.createdAt,
  });

  factory LongTermMemoryModel.fromJson(Map<String, dynamic> json) {
    return LongTermMemoryModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      connectedPeopleIds: (json['connectedPeopleIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      place: json['place'] as String?,
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) ?? DateTime.now() : DateTime.now(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'tags': tags,
      'connectedPeopleIds': connectedPeopleIds,
      'place': place,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  LongTermMemoryModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    List<String>? tags,
    List<String>? connectedPeopleIds,
    String? Function()? place,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return LongTermMemoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      connectedPeopleIds: connectedPeopleIds ?? this.connectedPeopleIds,
      place: place != null ? place() : this.place,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
