import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jarvis/features/money/domain/entities/debt_payment.dart';

class DebtPaymentModel extends DebtPayment {
  const DebtPaymentModel({
    required super.id,
    required super.date,
    required super.amount,
    super.status = 'paid',
    super.paidAt,
  });

  factory DebtPaymentModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['date'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    DateTime? parsedPaidAt;
    final rawPaidAt = json['paidAt'];
    if (rawPaidAt is Timestamp) {
      parsedPaidAt = rawPaidAt.toDate();
    } else if (rawPaidAt is String) {
      parsedPaidAt = DateTime.tryParse(rawPaidAt);
    }

    return DebtPaymentModel(
      id: json['id'] as String? ?? '',
      date: parsedDate,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'paid',
      paidAt: parsedPaidAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'amount': amount,
      'status': status,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  DebtPaymentModel copyWith({
    String? id,
    DateTime? date,
    double? amount,
    String? status,
    DateTime? Function()? paidAt,
  }) {
    return DebtPaymentModel(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paidAt: paidAt != null ? paidAt() : this.paidAt,
    );
  }
}
