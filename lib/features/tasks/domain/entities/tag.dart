class Tag {
  final String id;
  final String name;
  final String color;
  final String? emoji;
  final int sortOrder;

  const Tag({
    required this.id,
    required this.name,
    required this.color,
    this.emoji,
    required this.sortOrder,
  });
}
