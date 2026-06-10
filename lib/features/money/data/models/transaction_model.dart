import 'package:jarvis/features/money/domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.type,
    required super.amount,
    required super.category,
    super.description,
    super.emoji = '💰',
    required super.date,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['date'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate != null) {
      try { parsedDate = (rawDate as dynamic).toDate() as DateTime; } catch (_) { parsedDate = DateTime.now(); }
    } else {
      parsedDate = DateTime.now();
    }

    DateTime parsedCreatedAt;
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];
    if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else if (rawCreatedAt != null) {
      try { parsedCreatedAt = (rawCreatedAt as dynamic).toDate() as DateTime; } catch (_) { parsedCreatedAt = DateTime.now(); }
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return TransactionModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'expense',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? '',
      description: json['description'] as String?,
      emoji: json['emoji'] as String? ?? '💰',
      date: parsedDate,
      createdAt: parsedCreatedAt,
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
      'date': date.toUtc().toIso8601String(),
      'createdAt': createdAt.toUtc().toIso8601String(),
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
}
