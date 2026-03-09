import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/auth_user.dart';
import '../services/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  LoginUser? _currentUser;
  LoginUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _repository.login(
        username: username.trim(),
        password: password.trim(),
      );

      if (user == null) {
        _errorMessage =
            'Login failed. Check your credentials or table access policy and try again.';
        return false;
      }

      _currentUser = user;
      return true;
    } on PostgrestException catch (e) {
      _errorMessage = 'Database error: ${e.message}';
      return false;
    } catch (_) {
      _errorMessage = 'Unable to login right now. Please retry.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    _errorMessage = '';
    notifyListeners();
  }
}
