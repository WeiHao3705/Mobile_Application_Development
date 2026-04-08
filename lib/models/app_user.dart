class AppUser {
  AppUser({required this.data});

  final Map<String, dynamic> data;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(data: Map<String, dynamic>.from(map));
  }

  Iterable<MapEntry<String, dynamic>> get fields => data.entries;

  String get title {
    final name = data['name'];
    final email = data['email'];
    final id = data['id'];

    if (name != null && name.toString().isNotEmpty) {
      return name.toString();
    }
    if (email != null && email.toString().isNotEmpty) {
      return email.toString();
    }
    return id?.toString() ?? 'User';
  }
}

class SignUpProfileData {
  const SignUpProfileData({
    required this.gender,
    required this.dateOfBirth,
    required this.height,
    required this.currentWeight,
    required this.targetWeight,
    required this.username,
    required this.password,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.isAdmin = false,
  });

  final String gender;
  final DateTime dateOfBirth;
  final double height;
  final double currentWeight;
  final double targetWeight;
  final String username;
  final String password;
  final String email;
  final String fullName;
  final String phoneNumber;
  final bool isAdmin;

  Map<String, dynamic> toInsertMap({bool includePhoneNumber = true}) {
    final payload = <String, dynamic>{
      'gender': gender,
      'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      'height': height,
      'current_weight': currentWeight,
      'target_weight': targetWeight,
      'username': username,
      'password': password,
      'email': email,
      'full_name': fullName,
      'is_admin': isAdmin,
    };

    if (includePhoneNumber && phoneNumber.isNotEmpty) {
      payload['phone_number'] = phoneNumber;
    }

    return payload;
  }
}
