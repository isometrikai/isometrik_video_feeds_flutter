part of 'ism_landing_bloc.dart';

abstract class LandingEvent {}

class StartLandingEvent extends LandingEvent {
  StartLandingEvent({required this.isLoading});

  final bool isLoading;
}
