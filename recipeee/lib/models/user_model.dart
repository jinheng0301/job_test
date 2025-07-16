class UserModel {
  final String id;
  final String username;
  final String email;
  final String profilePic;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.profilePic,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['name'] as String,
      email: json['email'] as String,
      profilePic: json['profilePic'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': username,
      'email': email,
      'profilePictureUrl': profilePic,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      username: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePic: map['profilePictureUrl'] ?? '',
    );
  }
}
