import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart' as reels_sdk;
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
    await reels_sdk.IsrVideoReelConfig.initializeSdk(
      baseUrl: AppUrl.appBaseUrl,
      postInfo: reels_sdk.PostInfoClass(
        accessToken: accessToken,
        userInformation: reels_sdk.UserInfoClass(
          userId: '37483783493',
          userName: 'asjad',
          firstName: 'Asjad',
          lastName: 'Ibrahim',
        ),
      ),
    );
  }
}
