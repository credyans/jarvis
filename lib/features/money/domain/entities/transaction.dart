class Transaction {
  final String id;
  final String type;
  final double amount;
  final String category;
  final String? description;
  final String emoji;
  final DateTime date;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    this.emoji = '💰',
    required this.date,
    required this.createdAt,
  });
}
