class LoginUser {
  const LoginUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.height,
    required this.currentWeight,
    required this.targetWeight,
  });

  final dynamic id;
  final String username;
  final String? fullName;
  final String? email;
  final num? height;
  final num? currentWeight;
  final num? targetWeight;

  factory LoginUser.fromMap(Map<String, dynamic> map) {
    return LoginUser(
      id: map['user_id'] ?? map['id'],
      username: (map['username'] ?? '').toString(),
      fullName: _toNullableString(map['full_name']),
      email: _toNullableString(map['email']),
      height: _toNullableNum(map['height']),
      currentWeight: _toNullableNum(map['current_weight']),
      targetWeight: _toNullableNum(map['target_weight']),
    );
  }

  static String? _toNullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static num? _toNullableNum(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value;
    }
    return num.tryParse(value.toString());
  }
}
