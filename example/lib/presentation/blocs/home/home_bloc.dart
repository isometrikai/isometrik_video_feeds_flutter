import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart' as isr;
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/res/res.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._localDataUseCase) : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
  }

  final LocalDataUseCase _localDataUseCase;

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(HomeLoading());
      await _initializeReelsSdk();
      emit(HomeLoaded());
    } catch (error) {
      emit(HomeError(error.toString()));
    }
  }

  Future<void> _initializeReelsSdk() async {
    final accessToken = await _localDataUseCase.getAccessToken();
    await isr.IsrVideoReelConfig.initializeSdk(
      baseUrl: AppUrl.appBaseUrl,
      postInfo: isr.PostInfoClass(
        accessToken: accessToken,
        userInformation: isr.UserInfoClass(
          userId: '37483783493',
          userName: 'asjad',
          firstName: 'Asjad',
          lastName: 'Ibrahim',
        ),
      ),
    );
  }
}
