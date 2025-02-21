part of 'ism_landing_bloc.dart';

abstract class LandingState {}

class StartLandingState extends LandingState {
  StartLandingState({required this.isLoading});

  final bool isLoading;
}
