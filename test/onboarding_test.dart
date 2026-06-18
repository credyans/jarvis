import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jarvis/features/auth/data/models/user_model.dart';
import 'package:jarvis/features/auth/data/repositories/local_auth_repository.dart';
import 'package:jarvis/data/seed_data.dart';

void main() {
  setUpAll(() async {
    // Initialize Hive in a temporary test directory
    final tempDir = Directory.systemTemp.createTempSync('jarvis_test_hive');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  test('Local Auth & Seeding Seeding Integration Test', () async {
    final localAuthRepo = LocalAuthRepository();

    // 1. Sign in anonymously
    final uid = await localAuthRepo.signInAnonymously();
    expect(uid, isNotEmpty);

    // 2. Create user model
    final user = UserModel(
      id: uid,
      name: 'Test Santhosh',
      joinDate: DateTime.now(),
      currency: '₹',
      onboardingComplete: true,
      wakeTime: '07:00 AM',
      focusAreas: const ['tasks', 'habits'],
    );

    // 3. Save user
    await localAuthRepo.saveUser(user);

    // 4. Verify user saved
    final hasUser = await localAuthRepo.hasUser();
    expect(hasUser, true);

    final savedUser = await localAuthRepo.getCurrentUser();
    expect(savedUser, isNotNull);
    expect(savedUser!.name, 'Test Santhosh');
    expect(savedUser.focusAreas, contains('tasks'));

    // 5. Seed Mock Data
    print('Seeding Hive databases...');
    await SeedData.seed(uid, force: true);
    print('Seeding completed successfully!');

    // 6. Verify Seeded Data
    final tasksBox = await Hive.openBox('tasks');
    expect(tasksBox.isNotEmpty, true);
    print('Tasks box has ${tasksBox.length} tasks.');

    final tagsBox = await Hive.openBox('tags');
    expect(tagsBox.isNotEmpty, true);
    print('Tags box has ${tagsBox.length} tags.');

    final habitsBox = await Hive.openBox('habits');
    expect(habitsBox.isNotEmpty, true);
    print('Habits box has ${habitsBox.length} habits.');
  });
}
