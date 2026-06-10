class SavingsPlanModel {
  final String id;
  final String name;
  final double monthlyAmount;
  final int? durationMonths; // Null for unlimited
  final String? linkedGoalId;
  final List<String> paidMonths; // Format: 'yyyy-MM'
  final List<String> skippedMonths; // Format: 'yyyy-MM'
  final DateTime createdAt;
  final bool isActive;

  const SavingsPlanModel({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    this.durationMonths,
    this.linkedGoalId,
    this.paidMonths = const [],
    this.skippedMonths = const [],
    required this.createdAt,
    this.isActive = true,
  });

  factory SavingsPlanModel.fromJson(Map<String, dynamic> json) {
    return SavingsPlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      monthlyAmount: (json['monthlyAmount'] as num).toDouble(),
      durationMonths: json['durationMonths'] as int?,
      linkedGoalId: json['linkedGoalId'] as String?,
      paidMonths: List<String>.from(json['paidMonths'] ?? []),
      skippedMonths: List<String>.from(json['skippedMonths'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'monthlyAmount': monthlyAmount,
      'durationMonths': durationMonths,
      'linkedGoalId': linkedGoalId,
      'paidMonths': paidMonths,
      'skippedMonths': skippedMonths,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  double get totalSaved => paidMonths.length * monthlyAmount;

  SavingsPlanModel copyWith({
    String? id,
    String? name,
    double? monthlyAmount,
    int? Function()? durationMonths,
    String? Function()? linkedGoalId,
    List<String>? paidMonths,
    List<String>? skippedMonths,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return SavingsPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      durationMonths: durationMonths != null ? durationMonths() : this.durationMonths,
      linkedGoalId: linkedGoalId != null ? linkedGoalId() : this.linkedGoalId,
      paidMonths: paidMonths ?? this.paidMonths,
      skippedMonths: skippedMonths ?? this.skippedMonths,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
