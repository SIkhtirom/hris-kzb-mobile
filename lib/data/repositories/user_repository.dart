import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../mock/mock_user_data.dart';

class UserRepository {
  static const Duration _latency = Duration(milliseconds: 500);
  static const Duration _storageTimeout = Duration(seconds: 1);
  static const String profilePhotoKey = 'user_profile_photo';
  static const String dateOfBirthKey = 'user_date_of_birth';

  User? _cache;

  User get cachedUser => _cache ??= MockUserData.currentUser;

  Future<User> fetchCurrentUser() async {
    await Future<void>.delayed(_latency);
    final stored = await _readStoredOverrides();
    _cache = stored ?? MockUserData.currentUser;
    MockUserData.currentUser = _cache!;
    return _cache!;
  }

  Future<User> updateUser(User user) async {
    await Future<void>.delayed(_latency);
    MockUserData.currentUser = user;
    _cache = user;
    await _persistOverrides(user);
    return user;
  }

  Future<User?> _readStoredOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        _storageTimeout,
      );
      final photo = prefs.getString(profilePhotoKey);
      final birthRaw = prefs.getString(dateOfBirthKey);
      if (photo == null && birthRaw == null) {
        return null;
      }
      final base = MockUserData.currentUser;
      return base.copyWith(
        profilePicturePath: photo ?? base.profilePicturePath,
        dateOfBirth: birthRaw == null
            ? base.dateOfBirth
            : DateTime.tryParse(birthRaw) ?? base.dateOfBirth,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistOverrides(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        _storageTimeout,
      );
      final photo = user.profilePicturePath;
      if (photo == null) {
        await prefs.remove(profilePhotoKey);
      } else {
        await prefs.setString(profilePhotoKey, photo);
      }
      final birth = user.dateOfBirth;
      if (birth == null) {
        await prefs.remove(dateOfBirthKey);
      } else {
        await prefs.setString(dateOfBirthKey, birth.toIso8601String());
      }
    } catch (_) {}
  }
}
