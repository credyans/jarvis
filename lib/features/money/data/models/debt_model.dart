import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jarvis/features/money/domain/entities/debt.dart';
import 'package:jarvis/features/money/data/models/debt_payment_model.dart';

class DebtModel extends Debt {
  const DebtModel({
    required super.id,
    required super.person,
    required super.category,
    required super.amount,
    super.frequency = 'monthly',
    required super.startDate,
    required super.endDate,
    required super.type,
    List<DebtPaymentModel> super.payments = const [],
    required super.createdAt,
  });

  @override
  List<DebtPaymentModel> get payments => super.payments.cast<DebtPaymentModel>();

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedStartDate;
    final rawStartDate = json['startDate'];
    if (rawStartDate is Timestamp) {
      parsedStartDate = rawStartDate.toDate();
    } else if (rawStartDate is String) {
      parsedStartDate = DateTime.tryParse(rawStartDate) ?? DateTime.now();
    } else {
      parsedStartDate = DateTime.now();
    }

    DateTime parsedEndDate;
    final rawEndDate = json['endDate'];
    if (rawEndDate is Timestamp) {
      parsedEndDate = rawEndDate.toDate();
    } else if (rawEndDate is String) {
      parsedEndDate = DateTime.tryParse(rawEndDate) ?? DateTime.now();
    } else {
      parsedEndDate = DateTime.now();
    }

    DateTime parsedCreatedAt;
    final rawCreatedAt = json['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    final rawPayments = json['payments'] as List<dynamic>?;
    final parsedPayments = rawPayments
            ?.map((e) => DebtPaymentModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        <DebtPaymentModel>[];

    return DebtModel(
      id: json['id'] as String? ?? '',
      person: json['person'] as String? ?? '',
      category: json['category'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      frequency: json['frequency'] as String? ?? 'monthly',
      startDate: parsedStartDate,
      endDate: parsedEndDate,
      type: json['type'] as String? ?? 'owedToMe',
      payments: parsedPayments,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'person': person,
      'category': category,
      'amount': amount,
      'frequency': frequency,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'type': type,
      'payments': payments.map((e) => e.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
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
        .fold(0.0, (total, p) => total + p.amount);
  }

  /// Total remaining amount.
  double get totalRemaining {
    final total = amount;
    return (total - totalPaid).clamp(0.0, double.infinity);
  }
}
