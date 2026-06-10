class FinancialGoalModel {
  final String id;
  final String name;
  final String icon;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  const FinancialGoalModel({
    required this.id,
    required this.name,
    this.icon = '🎯',
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.deadline,
    required this.createdAt,
  });

  factory FinancialGoalModel.fromJson(Map<String, dynamic> json) {
    return FinancialGoalModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '🎯',
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
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

  @override
  String toString() {
    return 'FinancialGoalModel(id: $id, name: $name, icon: $icon, '
        'targetAmount: $targetAmount, currentAmount: $currentAmount, '
        'deadline: $deadline, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FinancialGoalModel) return false;
    return id == other.id &&
        name == other.name &&
        icon == other.icon &&
        targetAmount == other.targetAmount &&
        currentAmount == other.currentAmount &&
        deadline == other.deadline &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      icon,
      targetAmount,
      currentAmount,
      deadline,
      createdAt,
    );
  }
}
