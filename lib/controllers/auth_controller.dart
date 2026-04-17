import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/auth_user.dart';
import '../repository/auth_repository.dart';
import '../repository/user_repository.dart';
import '../services/auth_session_storage.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    AuthRepository? repository,
    UserRepository? userRepository,
    AuthSessionStorage? sessionStorage,
  })  : _repository = repository ?? AuthRepository(),
        _userRepository = userRepository ?? UserRepository(),
        _sessionStorage = sessionStorage ?? AuthSessionStorage();

  final AuthRepository _repository;
  final UserRepository _userRepository;
  final AuthSessionStorage _sessionStorage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  LoginUser? _currentUser;
  LoginUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser?.id != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  Future<void> restoreSession() async {
    final restoredUser = await _sessionStorage.read();
    if (restoredUser?.id == null) {
      _currentUser = null;
      await _sessionStorage.clear();
    } else {
      _currentUser = restoredUser;
    }
    notifyListeners();
  }

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
      await _sessionStorage.save(user);
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

  Future<bool> signUp({required SignUpProfileData profile}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _userRepository.createUserProfile(profile);
      await _repository.ensureAuthIdentity(
        email: profile.email,
        password: profile.password,
      );

      // Reuse login query so we always keep the same user shape as normal login.
      final signedUpUser = await _repository.login(
        username: profile.username.trim(),
        password: profile.password.trim(),
      );

      if (signedUpUser == null || signedUpUser.id == null) {
        _errorMessage =
        'Account created but unable to start session. Please login manually.';
        _currentUser = null;
        return false;
      }

      _currentUser = signedUpUser;
      await _sessionStorage.save(signedUpUser);
      return true;
    } on PostgrestException catch (e) {
      if (_isRlsInsertError(e)) {
        _errorMessage =
        'Sign up is blocked by Supabase Row Level Security policy. Please update INSERT policy for table "User".';
      } else {
        _errorMessage = 'Sign up failed: ${e.message}';
      }
      return false;
    } on AuthException catch (e) {
      _errorMessage = 'Auth error: ${e.message}';
      return false;
    } catch (e) {
      _errorMessage = 'Sign up error: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _errorMessage = '';
    await _sessionStorage.clear();
    notifyListeners();
  }

  Future<bool> sendPasswordResetEmail({
    required String email,
    required String redirectTo,
  }) async {
    // Keep forgot-password flow isolated from page-level rebuilds.
    _errorMessage = '';

    try {
      await _repository.sendPasswordResetEmail(
        email: email,
        redirectTo: redirectTo,
      );
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to send reset email right now. Please retry.';
      return false;
    }
  }

  Future<bool> completePasswordReset({required String newPassword}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _repository.completePasswordReset(newPassword: newPassword);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to reset password right now. Please retry.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isRlsInsertError(PostgrestException error) {
    final message = error.message.toLowerCase();
    return message.contains('row-level security') ||
        message.contains('violates row-level security');
  }
}
