part of 'auth_bloc.dart';

abstract class AuthEvent {}

class StartLoginEvent extends AuthEvent {}

class LoginEvent extends AuthEvent {
  LoginEvent({
    required this.isLoading,
    required this.mobileNumber,
    required this.countryCode,
  });

  final bool isLoading;
  final String mobileNumber;
  final String countryCode;
}

class SendOtpEvent extends AuthEvent {
  SendOtpEvent({
    required this.isLoading,
    required this.mobileNumber,
  });

  final bool isLoading;
  final String mobileNumber;
}

class VerifyOtpEvent extends AuthEvent {
  VerifyOtpEvent({
    required this.isLoading,
    required this.otpId,
    required this.otp,
    required this.mobileNumber,
  });

  final bool isLoading;
  final String otpId;
  final String otp;
  final String mobileNumber;
}
