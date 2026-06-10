import 'package:jarvis/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.joinDate,
    super.currency = '₹',
    super.onboardingComplete = false,
    super.wakeTime,
    super.focusAreas = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedJoinDate;
    final rawJoinDate = json['joinDate'] ?? json['join_date'];
    if (rawJoinDate is String) {
      parsedJoinDate = DateTime.tryParse(rawJoinDate) ?? DateTime.now();
    } else {
      // Fallback: handle Firestore Timestamp via dynamic invocation if Firebase path
      try {
        parsedJoinDate = (rawJoinDate as dynamic).toDate() as DateTime;
      } catch (_) {
        parsedJoinDate = DateTime.now();
      }
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      joinDate: parsedJoinDate,
      currency: json['currency'] as String? ?? '₹',
      onboardingComplete:
          (json['onboardingComplete'] ?? json['onboarding_complete']) as bool? ??
              false,
      wakeTime: (json['wakeTime'] ?? json['wake_time']) as String?,
      focusAreas: List<String>.from(
          (json['focusAreas'] ?? json['focus_areas'] ?? []) as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'joinDate': joinDate.toUtc().toIso8601String(),
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
}
