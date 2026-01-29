import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotify_clone/auth/auth_service.dart';

import '../models/user.dart';

class Auth extends ChangeNotifier {
  bool _isLoggedIn = false;
  User _user = User(name: '', email: '', token: '');
  String _token = '';

  bool get authenticated => _isLoggedIn;
  User get authedUser => _user;
  String get userToken => _token;

  // Keep a secure storage instance available if needed in future
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<void> register(User user) async {
    final authService = AuthService();
    final (token, stCode) = await authService.registerUser(user);

    if (stCode == 201) {
      _isLoggedIn = true;
      _token = token;
      _user = user..token = token;
      await storeToken(token);
      notifyListeners();
    }
  }

  Future<void> tryToken(String token) async {
    final authService = AuthService();
    final authedUser = await authService.loginWithToken(token);

    if (authedUser != null) {
      _user = authedUser..token = token;
      _isLoggedIn = true;
      _token = token;
      notifyListeners();
    }
  }

  Future<void> storeToken(String tokenValue) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString('token', tokenValue);
    } catch (e) {
      debugPrint('failed to store token: $e');
    }
  }

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}
