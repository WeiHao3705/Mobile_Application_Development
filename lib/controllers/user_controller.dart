import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../repository/user_repository.dart';

class UserController extends ChangeNotifier {
  UserController({UserRepository? repository})
      : _repository = repository ?? UserRepository();

  final UserRepository _repository;

  final List<AppUser> _users = [];
  List<AppUser> get users => List.unmodifiable(_users);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String _statusMessage = 'Checking Supabase...';
  String get statusMessage => _statusMessage;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Future<void> initialize() async {
    await checkSupabaseConnection();
    if (_isConnected) {
      await fetchUsers();
    }
  }

  Future<void> checkSupabaseConnection() async {
    try {
      Supabase.instance.client;
      _isConnected = true;
      _statusMessage = 'Connected to Supabase';
      _errorMessage = '';
    } catch (e) {
      _isConnected = false;
      _statusMessage = 'Connection error';
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final items = await _repository.fetchUsers();
      _users
        ..clear()
        ..addAll(items);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

