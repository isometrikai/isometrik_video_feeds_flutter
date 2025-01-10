import 'package:ism_video_reel_player/export.dart';

class ServiceProvider extends Services {
  @override
  PostApiService postApiService() {
    final postApiService = PostApiServiceProvider(
      apiWrapper: NetworkClient(baseUrl: 'https://api.soldlive.eu'),
    );
    return postApiService;
  }
}
