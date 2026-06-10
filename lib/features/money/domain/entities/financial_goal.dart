class FinancialGoal {
  final String id;
  final String name;
  final String icon;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  const FinancialGoal({
    required this.id,
    required this.name,
    this.icon = '🎯',
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.deadline,
    required this.createdAt,
  });
}
