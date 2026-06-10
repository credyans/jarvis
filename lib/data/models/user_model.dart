class UserModel {
  final String id;
  final String name;
  final DateTime joinDate;
  final String currency;
  final bool onboardingComplete;
  final String? wakeTime;
  final List<String> focusAreas;

  const UserModel({
    required this.id,
    required this.name,
    required this.joinDate,
    this.currency = '₹',
    this.onboardingComplete = false,
    this.wakeTime,
    this.focusAreas = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      joinDate: DateTime.parse(json['joinDate'] as String),
      currency: json['currency'] as String? ?? '₹',
      onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      wakeTime: json['wakeTime'] as String?,
      focusAreas: (json['focusAreas'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'joinDate': joinDate.toIso8601String(),
      'currency': currency,
      'onboardingComplete': onboardingComplete,
      'wakeTime': wakeTime,
      'focusAreas': focusAreas,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    DateTime? joinDate,
    String? currency,
    bool? onboardingComplete,
    String? Function()? wakeTime,
    List<String>? focusAreas,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      joinDate: joinDate ?? this.joinDate,
      currency: currency ?? this.currency,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      wakeTime: wakeTime != null ? wakeTime() : this.wakeTime,
      focusAreas: focusAreas ?? this.focusAreas,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, joinDate: $joinDate, '
        'currency: $currency, onboardingComplete: $onboardingComplete, '
        'wakeTime: $wakeTime, focusAreas: $focusAreas)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserModel) return false;
    return id == other.id &&
        name == other.name &&
        joinDate == other.joinDate &&
        currency == other.currency &&
        onboardingComplete == other.onboardingComplete &&
        wakeTime == other.wakeTime &&
        _listEquals(focusAreas, other.focusAreas);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      joinDate,
      currency,
      onboardingComplete,
      wakeTime,
      Object.hashAll(focusAreas),
    );
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
