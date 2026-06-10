import 'package:jarvis/data/models/debt_payment_model.dart';

class DebtModel {
  final String id;
  final String person;
  final String category;
  final double amount;
  final String frequency;
  final DateTime startDate;
  final DateTime endDate;
  final String type;
  final List<DebtPaymentModel> payments;
  final DateTime createdAt;

  const DebtModel({
    required this.id,
    required this.person,
    required this.category,
    required this.amount,
    this.frequency = 'monthly',
    required this.startDate,
    required this.endDate,
    required this.type,
    this.payments = const [],
    required this.createdAt,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as String,
      person: json['person'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      frequency: json['frequency'] as String? ?? 'monthly',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      type: json['type'] as String,
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) =>
                  DebtPaymentModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'person': person,
      'category': category,
      'amount': amount,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'type': type,
      'payments': payments.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  DebtModel copyWith({
    String? id,
    String? person,
    String? category,
    double? amount,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    List<DebtPaymentModel>? payments,
    DateTime? createdAt,
  }) {
    return DebtModel(
      id: id ?? this.id,
      person: person ?? this.person,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Total amount paid across all completed payments.
  double get totalPaid {
    return payments
        .where((p) => p.status == 'paid')
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  /// Total remaining amount.
  double get totalRemaining {
    final total = amount;
    return (total - totalPaid).clamp(0.0, double.infinity);
  }

  @override
  String toString() {
    return 'DebtModel(id: $id, person: $person, category: $category, '
        'amount: $amount, frequency: $frequency, type: $type, '
        'payments: ${payments.length} entries, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DebtModel) return false;
    return id == other.id &&
        person == other.person &&
        category == other.category &&
        amount == other.amount &&
        frequency == other.frequency &&
        startDate == other.startDate &&
        endDate == other.endDate &&
        type == other.type &&
        _listEquals(payments, other.payments) &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      person,
      category,
      amount,
      frequency,
      startDate,
      endDate,
      type,
      Object.hashAll(payments),
      createdAt,
    );
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
