import 'package:flutter_bloc/flutter_bloc.dart';

part 'landing_event.dart';
part 'landing_state.dart';

class IsmLandingBloc extends Bloc<LandingEvent, IsmLandingState> {
  IsmLandingBloc() : super(StartIsmLandingState(isLoading: false));
}
