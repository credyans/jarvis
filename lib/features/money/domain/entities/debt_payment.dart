class DebtPayment {
  final String id;
  final DateTime date;
  final double amount;
  final String status;
  final DateTime? paidAt;

  const DebtPayment({
    required this.id,
    required this.date,
    required this.amount,
    this.status = 'paid',
    this.paidAt,
  });
}
