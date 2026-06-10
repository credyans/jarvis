class BillReminderModel {
  final String id;
  final String title;
  final double amount;
  final int dueDay;
  final DateTime? dueDate;
  final String category;
  final bool isRecurring;
  final bool isPaid;
  final DateTime? lastPaidDate;
  final DateTime createdAt;

  const BillReminderModel({
    required this.id,
    required this.title,
    required this.amount,
    this.dueDay = 1,
    this.dueDate,
    required this.category,
    this.isRecurring = true,
    this.isPaid = false,
    this.lastPaidDate,
    required this.createdAt,
  });

  factory BillReminderModel.fromJson(Map<String, dynamic> json) {
    return BillReminderModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDay: json['dueDay'] as int? ?? 1,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      category: json['category'] as String? ?? 'Other',
      isRecurring: json['isRecurring'] as bool? ?? true,
      isPaid: json['isPaid'] as bool? ?? false,
      lastPaidDate: json['lastPaidDate'] != null ? DateTime.parse(json['lastPaidDate'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDay': dueDay,
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
      'isRecurring': isRecurring,
      'isPaid': isPaid,
      'lastPaidDate': lastPaidDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  BillReminderModel copyWith({
    String? id,
    String? title,
    double? amount,
    int? dueDay,
    DateTime? Function()? dueDate,
    String? category,
    bool? isRecurring,
    bool? isPaid,
    DateTime? Function()? lastPaidDate,
    DateTime? createdAt,
  }) {
    return BillReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDay: dueDay ?? this.dueDay,
      dueDate: dueDate != null ? dueDate() : this.dueDate,
      category: category ?? this.category,
      isRecurring: isRecurring ?? this.isRecurring,
      isPaid: isPaid ?? this.isPaid,
      lastPaidDate: lastPaidDate != null ? lastPaidDate() : this.lastPaidDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
