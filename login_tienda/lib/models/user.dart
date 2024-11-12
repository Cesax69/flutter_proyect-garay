class User {
  int? id;
  String username;
  String email;
  String password;
  bool isAdmin;

  User({
    this.id,
    required  this.username,
    required this.email,
    required this.password,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'is_admin': isAdmin ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      password: map['password'],
      isAdmin: map['is_admin'] == 1,
    );
  }
}