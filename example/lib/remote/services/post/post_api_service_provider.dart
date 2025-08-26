import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/remote/remote.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

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
          'authorization': header.accessToken,
          'lan': header.language,
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.platformText.toString(),
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
          'x-tenant-id': AppConstants.tenantId,
          'x-project-id': AppConstants.projectId,
        },
        isLoading,
      );

  @override
  Future<ResponseModel> editPost({
    required bool isLoading,
    required Header header,
    required String postId,
    Map<String, dynamic>? editPostRequest,
  }) async =>
      await networkClient.makeRequest(
        SocialApiEndPoints.putEditPost,
        NetworkRequestType.put,
        editPostRequest?.removeEmptyValues(),
        null,
        {
          'Accept': AppConstants.headerAccept,
          'Content-Type': AppConstants.headerContentType,
          'authorization': header.accessToken,
          'lan': header.language,
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.platformText.toString(),
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
          'x-tenant-id': AppConstants.tenantId,
          'x-project-id': AppConstants.projectId,
        },
        isLoading,
        pathSegments: [postId],
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
          'offset': page.toString(),
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
    required int page,
    required int pageLimit,
  }) async =>
      await networkClient.makeRequest(
        PostApiEndPoints.getTrendingPosts,
        NetworkRequestType.get,
        {},
        {
          'offset': page.toString(),
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
  Future<ResponseModel> followPost({
    required bool isLoading,
    required String followingId,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        PostApiEndPoints.postFollowPost,
        NetworkRequestType.post,
        {
          'followingId': followingId,
        },
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
  Future<ResponseModel> savePost({
    required bool isLoading,
    required String postId,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        PostApiEndPoints.postSavePost,
        NetworkRequestType.post,
        {
          'postId': postId,
        },
        null,
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
  Future<ResponseModel> likePost({
    required bool isLoading,
    required String postId,
    required String userId,
    required LikeAction likeAction,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        likeAction == LikeAction.like ? PostApiEndPoints.postLike : PostApiEndPoints.postUnLike,
        NetworkRequestType.post,
        {
          'postId': postId,
          'userId': userId,
        },
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
  Future<ResponseModel> reportPost({
    required bool isLoading,
    required String postId,
    required String message,
    required String reason,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        PostApiEndPoints.reportPost,
        NetworkRequestType.post,
        {
          'postId': postId,
          'message': message,
          'reason': reason,
        }.removeEmptyValues(),
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
  Future<ResponseModel> getReportReasons({
    required bool isLoading,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        PostApiEndPoints.getReportReasons,
        NetworkRequestType.get,
        null,
        null,
        {
          'Accept': AppConstants.headerAccept,
          'Content-Type': AppConstants.headerContentType,
          'Authorization': header.accessToken,
          'lang': header.language,
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.toString(),
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
        },
        isLoading,
      );

  @override
  Future<ResponseModel> getCloudDetails({
    required bool isLoading,
    required String key,
    required String value,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        PostApiEndPoints.getCloudDetails,
        NetworkRequestType.get,
        null,
        {
          key: value,
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
}
