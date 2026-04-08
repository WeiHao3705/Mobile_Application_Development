import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_application_development/models/app_user.dart';
import 'package:mobile_application_development/models/auth_user.dart';

void main() {
  test('SignUpProfileData includes is_admin with default false', () {
    final profile = SignUpProfileData(
      gender: 'male',
      dateOfBirth: DateTime(2000, 1, 1),
      height: 175,
      currentWeight: 80,
      targetWeight: 75,
      username: 'testuser',
      password: 'secret123',
      email: 'test@example.com',
      fullName: 'Test User',
      phoneNumber: '0123456789',
    );

    final payload = profile.toInsertMap();

    expect(payload['is_admin'], isFalse);
  });

  test('SignUpProfileData allows explicit admin payload', () {
    final profile = SignUpProfileData(
      gender: 'female',
      dateOfBirth: DateTime(1998, 5, 10),
      height: 165,
      currentWeight: 60,
      targetWeight: 58,
      username: 'adminuser',
      password: 'secret123',
      email: 'admin@example.com',
      fullName: 'Admin User',
      phoneNumber: '0987654321',
      isAdmin: true,
    );

    final payload = profile.toInsertMap();

    expect(payload['is_admin'], isTrue);
  });

  test('LoginUser.fromMap parses is_admin across value formats', () {
    final boolUser = LoginUser.fromMap({
      'user_id': 1,
      'username': 'alpha',
      'is_admin': true,
    });
    final numericUser = LoginUser.fromMap({
      'user_id': 2,
      'username': 'beta',
      'is_admin': 1,
    });
    final stringUser = LoginUser.fromMap({
      'user_id': 3,
      'username': 'gamma',
      'is_admin': 'true',
    });
    final defaultUser = LoginUser.fromMap({
      'user_id': 4,
      'username': 'delta',
    });

    expect(boolUser.isAdmin, isTrue);
    expect(numericUser.isAdmin, isTrue);
    expect(stringUser.isAdmin, isTrue);
    expect(defaultUser.isAdmin, isFalse);
  });
}

