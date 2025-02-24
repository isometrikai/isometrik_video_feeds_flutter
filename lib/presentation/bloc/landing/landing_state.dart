part of 'ism_landing_bloc.dart';

abstract class IsmLandingState {}

class StartIsmLandingState extends IsmLandingState {
  StartIsmLandingState({required this.isLoading});

  final bool isLoading;
}
