import 'dart:convert';

class UserInfoClass {
  factory UserInfoClass.fromJson(Map<String, dynamic> json) => UserInfoClass(
        userName: json['userName'] as String?,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        userId: json['userId'] as String?,
        profilePic: json['profilePic'] as String?,
      );

  UserInfoClass({
    this.userName,
    this.firstName,
    this.lastName,
    this.userId,
    this.profilePic,
  });

  final String? userName;
  final String? firstName;
  final String? lastName;
  final String? userId;
  final String? profilePic;

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'firstName': firstName,
        'lastName': lastName,
        'userId': userId,
        'profilePic': profilePic,
      };

  @override
  String toString() => jsonEncode(toJson());
}
