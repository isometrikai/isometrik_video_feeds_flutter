import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'landing_event.dart';
part 'landing_state.dart';

@lazySingleton
class IsmLandingBloc extends Bloc<LandingEvent, LandingState> {
  IsmLandingBloc() : super(StartLandingState(isLoading: false));
}
