class DebtPaymentModel {
  final String id;
  final DateTime date;
  final double amount;
  final String status;
  final DateTime? paidAt;

  const DebtPaymentModel({
    required this.id,
    required this.date,
    required this.amount,
    this.status = 'paid',
    this.paidAt,
  });

  factory DebtPaymentModel.fromJson(Map<String, dynamic> json) {
    return DebtPaymentModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String? ?? 'paid',
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'status': status,
      'paidAt': paidAt?.toIso8601String(),
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

  @override
  String toString() {
    return 'DebtPaymentModel(id: $id, date: $date, amount: $amount, '
        'status: $status, paidAt: $paidAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DebtPaymentModel) return false;
    return id == other.id &&
        date == other.date &&
        amount == other.amount &&
        status == other.status &&
        paidAt == other.paidAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, date, amount, status, paidAt);
  }
}
