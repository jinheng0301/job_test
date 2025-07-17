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
      id: json['uid'] ?? json['id'] ?? '',
      username: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePic: json['profilePic'] ?? '',
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
      id: map['uid'] ?? map['id'] ?? '',
      username: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePic: map['profilePic'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': username,
      'email': email,
      'profilePic': profilePic,
    };
  }
}
