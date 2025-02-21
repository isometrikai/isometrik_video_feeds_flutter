part of 'auth_bloc.dart';

abstract class AuthState {}

class AuthInitialState extends AuthState {}

class AuthError extends AuthState {
  AuthError(this.message);

  final String message;
}
