part of 'profile_bloc.dart';

abstract class ProfileEvent {}

class InitializeProfileEvent extends ProfileEvent {}

class LogoutEvent extends ProfileEvent {}
