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

