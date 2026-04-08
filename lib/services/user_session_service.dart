import 'package:shared_preferences/shared_preferences.dart';

class SimpleSessionService {
  static const String _loginKey = 'is_logged_in';
  static const String _usernameKey = 'saved_username';

  // Save the login status when they successfully log in
  Future<void> setLoggedIn(bool status, String username) async {
    // 1. Get the SharedPreferences instance
    final prefs = await SharedPreferences.getInstance();

    // 2. Write the data (Notice how simple the API is!)
    await prefs.setBool(_loginKey, status);
    await prefs.setString(_usernameKey, username);
  }

  // Check the status when the app opens
  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // Read the boolean. If it doesn't exist yet (first install), it returns false.
    return prefs.getBool(_loginKey) ?? false;
  }

  // Get the saved username to say "Welcome back, [Name]"
  Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Clear everything when they log out
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    // You can delete specific keys...
    await prefs.remove(_loginKey);
    await prefs.remove(_usernameKey);

    // ...or completely wipe all preferences for the app
    // await prefs.clear();
  }
}