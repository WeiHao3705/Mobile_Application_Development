class LoginUser {
  const LoginUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.height,
    required this.currentWeight,
    required this.targetWeight,
    required this.isAdmin,
    required this.profilePhotoUrl,
  });

  final dynamic id;
  final String username;
  final String? fullName;
  final String? email;
  final num? height;
  final num? currentWeight;
  final num? targetWeight;
  final bool isAdmin;
  final String? profilePhotoUrl;

  factory LoginUser.fromMap(Map<String, dynamic> map) {
    return LoginUser(
      id: map['user_id'] ?? map['id'],
      username: (map['username'] ?? '').toString(),
      fullName: _toNullableString(map['full_name'] ?? map['fullName']),
      email: _toNullableString(map['email']),
      height: _toNullableNum(map['height']),
      currentWeight: _toNullableNum(map['current_weight'] ?? map['currentWeight']),
      targetWeight: _toNullableNum(map['target_weight'] ?? map['targetWeight']),
      isAdmin: _toBool(map['is_admin'] ?? map['isAdmin']),
      profilePhotoUrl: _toNullableString(
        map['profile_photo'] ?? map['profilePhotoUrl'],
      ),
    );
  }

  LoginUser copyWith({
    dynamic id,
    String? username,
    String? fullName,
    String? email,
    num? height,
    num? currentWeight,
    num? targetWeight,
    bool? isAdmin,
    String? profilePhotoUrl,
  }) {
    return LoginUser(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      height: height ?? this.height,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      isAdmin: isAdmin ?? this.isAdmin,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }

  Map<String, dynamic> toSessionMap() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'height': height,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'isAdmin': isAdmin,
      'profilePhotoUrl': profilePhotoUrl,
    };
  }

  factory LoginUser.fromSessionMap(Map<String, dynamic> map) {
    return LoginUser.fromMap(map);
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

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 't';
  }
}
