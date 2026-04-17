import 'dart:convert';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  const PasswordHasher._();

  static String hash(String plainTextPassword) {
    final normalized = plainTextPassword.trim();
    return sha256.convert(utf8.encode(normalized)).toString();
  }
}

