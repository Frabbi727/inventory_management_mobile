import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/models/user_model.dart';

class UserStorage {
  static const _userKey = 'session_user';

  Future<void> saveUser(UserModel user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    final preferences = await SharedPreferences.getInstance();
    final rawUser = preferences.getString(_userKey);
    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    return UserModel.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
  }

  Future<void> clearUser() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_userKey);
  }
}
