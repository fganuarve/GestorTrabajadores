import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  final SharedPreferences prefs;
  Map<String, dynamic>? _user;

  UserProvider({required this.prefs}) {
    _loadUserFromPrefs();
  }

  Map<String, dynamic>? get user => _user;

  Future<void> setUser(Map<String, dynamic> userData) async {
    _user = userData;
    await prefs.setString('user_data', jsonEncode(userData));
    notifyListeners();
  }

  Future<void> _loadUserFromPrefs() async {
    try {
      final userData = prefs.getString('user_data');
      if (userData != null) {
        _user = Map<String, dynamic>.from(jsonDecode(userData));
      }
    } catch (e) {
      debugPrint('Error loading user from prefs: $e');
      _user = null;
    }
    notifyListeners();
  }

  Future<void> clearUser() async {
    _user = null;
    await prefs.remove('user_data');
    notifyListeners();
  }
}
