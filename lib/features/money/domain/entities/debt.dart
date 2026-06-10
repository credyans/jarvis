import 'package:jarvis/features/money/domain/entities/debt_payment.dart';

class Debt {
  final String id;
  final String person;
  final String category;
  final double amount;
  final String frequency;
  final DateTime startDate;
  final DateTime endDate;
  final String type;
  final List<DebtPayment> payments;
  final DateTime createdAt;

  const Debt({
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
}
