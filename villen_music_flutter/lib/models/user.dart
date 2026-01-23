/// User Model
/// 
/// Represents a generic user in the app.
library;

class User {
  final String username;
  final String? email;

  User({
    required this.username,
    this.email,
  });
  
  // Since the backend doesn't explicitly return a user object on login (just tokens),
  // we might decode this from the JWT or construct it manually.
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      email: json['email'],
    );
  }
}
