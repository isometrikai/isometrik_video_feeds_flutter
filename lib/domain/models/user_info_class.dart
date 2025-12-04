import 'dart:convert';

class UserInfoClass {
  factory UserInfoClass.fromJson(Map<String, dynamic> json) => UserInfoClass(
        userName: json['userName'] as String?,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        userId: json['userId'] as String?,
        profilePic: json['profilePic'] as String?,
        email: json['email'] as String?,
        dialCode: json['dialCode'] as String?,
        mobileNumber: json['mobileNumber'] as String?,
      );

  UserInfoClass({
    this.userName,
    this.firstName,
    this.lastName,
    this.userId,
    this.profilePic,
    this.email,
    this.dialCode,
    this.mobileNumber,
  });

  final String? userName;
  final String? firstName;
  final String? lastName;
  final String? userId;
  final String? profilePic;
  final String? email;
  final String? dialCode;
  final String? mobileNumber;

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'firstName': firstName,
        'lastName': lastName,
        'userId': userId,
        'profilePic': profilePic,
        'email': email,
        'dialCode': dialCode,
        'mobileNumber': mobileNumber,
      };

  @override
  String toString() => jsonEncode(toJson());
}
