class UserEntity {
  final String id;
  final String name;
  final DateTime joinDate;
  final String currency;
  final bool onboardingComplete;
  final String? wakeTime;
  final List<String> focusAreas;

  const UserEntity({
    required this.id,
    required this.name,
    required this.joinDate,
    required this.currency,
    required this.onboardingComplete,
    this.wakeTime,
    required this.focusAreas,
  });
}
