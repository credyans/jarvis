import 'package:jarvis/features/money/domain/entities/financial_goal.dart';

class FinancialGoalModel extends FinancialGoal {
  const FinancialGoalModel({
    required super.id,
    required super.name,
    super.icon = '🎯',
    required super.targetAmount,
    super.currentAmount = 0.0,
    super.deadline,
    required super.createdAt,
  });

  factory FinancialGoalModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDeadline;
    final rawDeadline = json['deadline'];
    if (rawDeadline is String) {
      parsedDeadline = DateTime.tryParse(rawDeadline);
    } else if (rawDeadline != null) {
      try { parsedDeadline = (rawDeadline as dynamic).toDate() as DateTime; } catch (_) {}
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

    return FinancialGoalModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '🎯',
      targetAmount: (json['targetAmount'] ?? json['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['currentAmount'] ?? json['current_amount'] as num?)?.toDouble() ?? 0.0,
      deadline: parsedDeadline,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline?.toUtc().toIso8601String(),
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  FinancialGoalModel copyWith({
    String? id,
    String? name,
    String? icon,
    double? targetAmount,
    double? currentAmount,
    DateTime? Function()? deadline,
    DateTime? createdAt,
  }) {
    return FinancialGoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline != null ? deadline() : this.deadline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Returns the progress as a value between 0.0 and 1.0.
  double get progress {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// Returns true if the goal has been reached.
  bool get isCompleted => currentAmount >= targetAmount;
}
