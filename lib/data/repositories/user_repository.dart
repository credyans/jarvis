import 'package:hive_flutter/hive_flutter.dart';
import 'package:jarvis/data/models/user_model.dart';

class UserRepository {
  static const String _boxName = 'users';
  static const String _currentUserKey = 'current_user';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<UserModel?> getCurrentUser() async {
    final box = await _getBox();
    final data = box.get(_currentUserKey);
    if (data == null) return null;
    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> saveUser(UserModel user) async {
    final box = await _getBox();
    await box.put(_currentUserKey, user.toJson());
  }

  Future<void> updateUser(UserModel user) async {
    await saveUser(user);
  }

  Future<void> deleteUser() async {
    final box = await _getBox();
    await box.delete(_currentUserKey);
  }

  Future<bool> hasUser() async {
    final box = await _getBox();
    return box.containsKey(_currentUserKey);
  }
}
