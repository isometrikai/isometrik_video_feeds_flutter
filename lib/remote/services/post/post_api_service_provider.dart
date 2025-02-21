import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/remote/remote.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class PostApiServiceProvider extends PostApiService {
  PostApiServiceProvider({
    required this.networkClient,
  });

  final NetworkClient networkClient;

  @override
  Future<ResponseModel> createPost({
    required bool isLoading,
    required Header header,
    Map<String, dynamic>? createPostRequest,
  }) async =>
      await networkClient.makeRequest(
        PostApiEndPoints.postCreatePost,
        NetworkRequestType.post,
        createPostRequest?.removeEmptyValues(),
        {},
        {
          'Accept': AppConstants.headerAccept,
          'Content-Type': AppConstants.headerContentType,
          'Authorization': header.accessToken,
          'language': header.language,
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.toString(),
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
        },
        isLoading,
      );

  @override
  Future<ResponseModel> getFollowingPosts({
    required bool isLoading,
    required Header header,
    required int page,
    required int pageLimit,
  }) async =>
      await networkClient.makeRequest(
        PostApiEndPoints.getFollowingPosts,
        NetworkRequestType.get,
        {},
        {
          'page': page.toString(),
          'limit': pageLimit.toString(),
        },
        {
          'Accept': AppConstants.headerAccept,
          'Content-Type': AppConstants.headerContentType,
          'Authorization': header.accessToken,
          'language': header.language,
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.toString(),
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
        },
        isLoading,
      );

  @override
  Future<ResponseModel> getTrendingPosts({
    required bool isLoading,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        PostApiEndPoints.getTrendingPosts,
        NetworkRequestType.get,
        {},
        {},
        {
          'Accept': AppConstants.headerAccept,
          'Content-Type': AppConstants.headerContentType,
          'Authorization': header.accessToken,
          'language': header.language,
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.toString(),
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
        },
        isLoading,
      );
}
