class TransactionModel {
  final String id;
  final String type;
  final double amount;
  final String category;
  final String? description;
  final String emoji;
  final DateTime date;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    this.emoji = '💰',
    required this.date,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String?,
      emoji: json['emoji'] as String? ?? '💰',
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'emoji': emoji,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? type,
    double? amount,
    String? category,
    String? Function()? description,
    String? emoji,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description != null ? description() : this.description,
      emoji: emoji ?? this.emoji,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: $type, amount: $amount, '
        'category: $category, description: $description, emoji: $emoji, '
        'date: $date, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TransactionModel) return false;
    return id == other.id &&
        type == other.type &&
        amount == other.amount &&
        category == other.category &&
        description == other.description &&
        emoji == other.emoji &&
        date == other.date &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      amount,
      category,
      description,
      emoji,
      date,
      createdAt,
    );
  }
}
