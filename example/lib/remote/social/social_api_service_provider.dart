import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/remote/remote.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class SocialApiServiceProvider extends SocialApiService {
  SocialApiServiceProvider({
    required this.networkClient,
    required this.deviceInfoManager,
  });

  final NetworkClient networkClient;
  final DeviceInfoManager deviceInfoManager;
  final dummyToken =
      'Bearer eyJhbGciOiJSU0EtT0FFUCIsImN0eSI6IkpXVCIsImVuYyI6IkExMjhHQ00iLCJ0eXAiOiJKV1QifQ.KVtQpyBgvz5Xm9rV3xkxQEqEhEiQHtSVT34KXfXcBVomLN26pzdymwU5OYPYsiO61qeqTCV6_hGHFMjOPowRG72Yo1vsd7g6O7slNbXOSebMeprh7opZO5FTirEX4mQ-8pcn6UIwZw34cNffatNmjyKQCCpy6HlAVWD0ZX9NfXs.kLJD6bk8a7LYMZlu.q8oia7vTFIc-EOrzNkrzrMpFYOVA1_npA24WumyrjADMH9eoob7qq9aWSLm-ycXp-B0iaQpYh_ZEJHNWzyowP1iwzNOfoSBuTvwKg17K9RXljo05YKjWgfjuqp1Zdl37DrSsQnB7lB7g8vfPfoy94cLH-YYkqEVVsX4AY6fjUFYr8qz59mRYcsHV1muBHhfWoCTzWk-YJHM8wAQY2zrT65Zbe65dMAoX8jbaXZPfYc8maaHCLLvx87JV6oagkMxkoOaE1U50slDhNafa8WK_TJ5vqIM3th4YPdXqI5mDEfp6fKm3JXF1jMEF1H2qam4_Ce_5C_1ImRJlnAX7MUKb6KNJx_ekb_4M0K82DqatuJ_EHwmW4XsfvRLUVIzTXI9excNRLR7__vmZxj99wFbxo6BAZbcHVjPMcTZjQM27abQdzfrnkeq4oxa3uWRUySUnD0BXSVzt8y-_XhG5iB4sXPtlbfkR8fAam7Uqj5OUWOHvc1MPkapyIl1fkO48DqEnf_50BSR-obt_FWMhIxDWJMrL3j1YJxVvfrr8Yyyl4dP71yk-5G5SMy6j-y9h-smAO33RHFQDKmA9lh2KUjA87mHkLBcIfb3wE2SG6I1ttKTgkAHnbevOUOfR4xddX7HPUyllakcqjaILIRp-pddJD8SeoF63xBOnG2hHtCYk9i0rzgSLQSCONmoYCEYsXUxNjE8goRelmbGqZMmR7fV7NO08c6mkEQtVsn6NgWwZdZhDhA0QZJAFZKhnrYHHVFHFT_DS93Nga-V3fhSHice5Fa7F3gqDmgv9r11WEIzd5MgqXUP6n9kirwVr6Gx0qorCmQVJgNTomlYHkGxt_Zl1fzSRlt5qT4RrrNuh7cnUw9vsHCFKCagGMM6LUEM3dGPo6Yf4Y6XEnp4bEeQFHzgPcvZKYgHfQGQNMiG_axVqc95CzyH5RBIaqyTmhxaimx34xyNJPx8-9whZVuyLLgUmT_0gWVEiYR4G4PeF1nTGTA-8RkuG6jQ3lv00TW4K65LhJ-8tJc5H5PFEjz_Jmb-OMHHYoe-NKfPvxh330eRgRdjVRA5zRFeBFfdn715ASZ9RUIQ8d8xYx_qglOKxyIs9-SygG9brgX9P8U2FnjO0QeAMICdHJfS_h5586_TrclXq44UcA4kYFrffR4eGMZunCMbzbMo5GyJTXMyCWOjFWH7rbXRzuhlIhuQuYvkKDfeu4tiRRjou9eFJjh1EPT9RArpxxA0UYMJsTlFLn4u1rflPTLrJRwOOxI19YsaiHnZOUDNEj9otAbxcps-mn6V2x9XwU8l0vt6CBCvOtJcjRatnCiqbRL22wHPINSCFRJwFi7uVUxbX6-iXaljLsP9b4a6QVHagtry5svPfnDJaAdUPlewfSZmRtDRecXR71L4fi3tnSb0E6xwhcjOdD9sy1DZ3Xc1spIQKdGO24rQe7IMnkDF7WC7jFJmJivKxPsNJP0m6vnJXvzng8CW5NsuL9ZYOiAcTmx2bDfyMg1cPr3pcvvBOU7AXd_gTz57reFdcmsjGNLZW2P_tbxeImLKtn34e5jjJp1xKvKKdTg5ev4iBh2JgBtlHHmH-4Ha2UREigsliMvO_-hMbUcmcB2Fqcg.J1on-dQA15LgzHKXy0pRzQ';

  @override
  Future<ResponseModel> createPost({
    required bool isLoading,
    required Header header,
    Map<String, dynamic>? createPostRequest,
  }) async {
    final appVersion = await Utility.getAppVersion();
    return await networkClient.makeRequest(
      SocialApiEndPoints.postCreatePost,
      NetworkRequestType.post,
      createPostRequest?.removeEmptyValues(),
      null,
      {
        'Accept': AppConstants.headerAccept,
        'Content-Type': AppConstants.headerContentType,
        'Authorization': header.accessToken,
        'lan': header.language,
        'city': 'Bengaluru',
        'state': header.state,
        'country': header.country,
        'ipaddress': header.ipAddress,
        'version': appVersion,
        'currencySymbol': header.currencySymbol,
        'currencyCode': header.currencyCode,
        'platform': header.platForm.platformText,
        'latitude': header.latitude.toString(),
        'longitude': header.longitude.toString(),
        'x-tenant-id': AppConstants.tenantId,
        'x-project-id': AppConstants.projectId,
      },
      isLoading,
    );
  }

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
        SocialApiEndPoints.getFollowingPosts,
        NetworkRequestType.get,
        null,
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
  Future<ResponseModel> getTimeLinePosts({
    required bool isLoading,
    required Header header,
    required int page,
    required int pageLimit,
  }) async =>
      await networkClient.makeRequest(
        SocialApiEndPoints.getTimeLinePosts,
        NetworkRequestType.get,
        null,
        {
          'page': page.toString(),
          'page_size': pageLimit.toString(),
        },
        {
          'Accept': AppConstants.headerAccept,
          'Content-Type': AppConstants.headerContentType,
          'Authorization': header.accessToken,
          'lan': header.language,
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.toString(),
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
          'x-tenant-id': AppConstants.tenantId,
          'x-project-id': AppConstants.projectId,
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
        SocialApiEndPoints.getTrendingPosts,
        NetworkRequestType.get,
        null,
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
  }) async {
    final appVersion = await Utility.getAppVersion();
    return await networkClient.makeRequest(
      SocialApiEndPoints.postFollowPost,
      NetworkRequestType.post,
      {
        'following_id': followingId,
      },
      null,
      {
        'Accept': AppConstants.headerAccept,
        'Content-Type': AppConstants.headerContentType,
        'Authorization': header.accessToken,
        'lan': header.language,
        'city': 'Bengaluru',
        'state': header.state,
        'country': header.country,
        'ipaddress': header.ipAddress,
        'version': appVersion,
        'currencySymbol': header.currencySymbol,
        'currencyCode': header.currencyCode,
        'platform': header.platForm.platformText,
        'latitude': header.latitude.toString(),
        'longitude': header.longitude.toString(),
        'x-tenant-id': AppConstants.tenantId,
        'x-project-id': AppConstants.projectId,
      },
      isLoading,
    );
  }

  @override
  Future<ResponseModel> unFollowPost({
    required bool isLoading,
    required String followingId,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        SocialApiEndPoints.postFollowPost,
        NetworkRequestType.delete,
        null,
        {'following_id': followingId},
        {
          'Accept': AppConstants.headerAccept,
          'Content-Type': AppConstants.headerContentType,
          'Authorization': header.accessToken,
          'language': header.language,
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.platformText,
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
          'x-tenant-id': AppConstants.tenantId,
          'x-project-id': AppConstants.projectId,
          'city': header.city,
          'country': header.country,
          'ipaddress': header.ipAddress,
          'version': deviceInfoManager.appVersion,
        },
        isLoading,
      );

  @override
  Future<ResponseModel> savePost({
    required bool isLoading,
    required String postId,
    required Header header,
    required SocialPostAction socialPostAction,
  }) async {
    final methodType = socialPostAction == SocialPostAction.unSave
        ? NetworkRequestType.delete
        : NetworkRequestType.post;
    final queryParams = socialPostAction == SocialPostAction.unSave ? {'postId': postId} : null;
    final bodyParams = socialPostAction == SocialPostAction.save ? {'postId': postId} : null;
    return await networkClient.makeRequest(
      SocialApiEndPoints.postSavePost,
      methodType,
      bodyParams,
      queryParams,
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
        'x-tenant-id': AppConstants.tenantId,
        'x-project-id': AppConstants.projectId,
      },
      isLoading,
    );
  }

  @override
  Future<ResponseModel> likePost({
    required bool isLoading,
    required String postId,
    required String userId,
    required LikeAction likeAction,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        likeAction == LikeAction.like ? SocialApiEndPoints.postLike : SocialApiEndPoints.postUnLike,
        likeAction == LikeAction.like ? NetworkRequestType.post : NetworkRequestType.delete,
        likeAction == LikeAction.like
            ? {
                'post_id': postId,
                'like_type': 'love',
              }
            : null,
        (likeAction == LikeAction.unlike) ? {'post_id': postId} : null,
        {
          'Accept': AppConstants.headerAccept,
          'Content-Type': AppConstants.headerContentType,
          'Authorization': header.accessToken,
          'language': header.language,
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.platformText,
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
          'x-tenant-id': AppConstants.tenantId,
          'x-project-id': AppConstants.projectId,
          'city': header.city,
          'country': header.country,
          'ipaddress': header.ipAddress,
          'version': deviceInfoManager.appVersion,
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
        SocialApiEndPoints.reportPost,
        NetworkRequestType.post,
        {
          'content_id': postId,
          'additional_details': message,
          'reason_id': reason,
          'type': 'post',
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
          'x-tenant-id': AppConstants.tenantId,
          'x-project-id': AppConstants.projectId,
          'city': header.city,
          'country': header.country,
          'ipaddress': header.ipAddress,
          'version': deviceInfoManager.appVersion,
        },
        isLoading,
      );

  @override
  Future<ResponseModel> getReportReasons({
    required bool isLoading,
    ReasonsFor? reasonFor = ReasonsFor.socialPost,
    required Header header,
  }) async {
    final endPoint = reasonFor == ReasonsFor.socialPost
        ? SocialApiEndPoints.getReportSocialPostReasons
        : SocialApiEndPoints.getReportCommentReasons;
    return await networkClient.makeRequest(
      endPoint,
      NetworkRequestType.get,
      null,
      {
        'reason_type': reasonFor == ReasonsFor.socialPost ? 'post' : 'comment',
      },
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
        'x-tenant-id': AppConstants.tenantId,
        'x-project-id': AppConstants.projectId,
      },
      isLoading,
    );
  }

  @override
  Future<ResponseModel> getCloudDetails({
    required bool isLoading,
    required String key,
    required String value,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        SocialApiEndPoints.getCloudDetails,
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

  @override
  Future<ResponseModel> getPostComments({
    required bool isLoading,
    required String postId,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        SocialApiEndPoints.getPostComments,
        NetworkRequestType.get,
        null,
        {
          'post_id': postId,
        },
        {
          'Accept': AppConstants.headerAccept,
          'Content-Type': AppConstants.headerContentType,
          'Authorization': header.accessToken,
          'language': header.language,
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.platformText,
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
          'x-tenant-id': AppConstants.tenantId,
          'x-project-id': AppConstants.projectId,
        },
        isLoading,
      );

  @override
  Future<ResponseModel> doCommentAction({
    required bool isLoading,
    required Map<String, dynamic> commentRequest,
    required Header header,
  }) async {
    final commentAction = commentRequest['commentAction'];
    var endPoint = '';
    var networkRequestType = NetworkRequestType.post;
    Map<String, dynamic>? requestBody;
    Map<String, dynamic>? queryParams;

    switch (commentAction) {
      case CommentAction.like:
        endPoint = SocialApiEndPoints.postCommentLike;
        networkRequestType = NetworkRequestType.post;
        requestBody = {
          'comment_id': commentRequest['commentId'],
          'like_type': 'haha',
        };
        break;

      case CommentAction.dislike:
        endPoint = SocialApiEndPoints.postCommentLike;
        networkRequestType = NetworkRequestType.delete;
        queryParams = {
          'comment_id': commentRequest['commentId'].toString(),
        };
        break;

      case CommentAction.comment:
        endPoint = SocialApiEndPoints.postComment;
        networkRequestType = NetworkRequestType.post;
        requestBody = commentRequest.removeEmptyValues();
        break;

      case CommentAction.delete:
        endPoint = SocialApiEndPoints.postComment;
        networkRequestType = NetworkRequestType.delete;
        queryParams = {
          'comment_id': commentRequest['commentId'].toString(),
        };
        break;

      case CommentAction.edit:
        endPoint = SocialApiEndPoints.postComment;
        networkRequestType = NetworkRequestType.put;
        queryParams = {
          'comment_id': commentRequest['commentId'].toString(),
        };
        requestBody = commentRequest.removeEmptyValues();
        break;

      case CommentAction.report:
        endPoint = SocialApiEndPoints.postReportComment;
        networkRequestType = NetworkRequestType.post;
        requestBody = {
          'additional_details': commentRequest['message'],
          'content_id': commentRequest['commentId'],
          'reason_id': commentRequest['reason'],
          'type': 'comment'
        };
        break;
    }

    commentRequest['commentAction'] = null;

    return await networkClient.makeRequest(
      endPoint,
      networkRequestType,
      requestBody,
      queryParams,
      {
        'Accept': AppConstants.headerAccept,
        'Content-Type': AppConstants.headerContentType,
        'Authorization': header.accessToken,
        'language': header.language,
        'currencySymbol': header.currencySymbol,
        'currencyCode': header.currencyCode,
        'platform': header.platForm.platformText,
        'latitude': header.latitude.toString(),
        'longitude': header.longitude.toString(),
        'x-tenant-id': AppConstants.tenantId,
        'x-project-id': AppConstants.projectId,
        'city': header.city,
        'country': header.country,
        'ipaddress': header.ipAddress,
        'version': deviceInfoManager.appVersion,
      },
      isLoading,
    );
  }

  @override
  Future<ResponseModel> getPostDetails({
    required bool isLoading,
    List<String>? productIds,
    int? page,
    int? limit,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        SocialApiEndPoints.getPostDetails,
        NetworkRequestType.get,
        null,
        {
          'productIds': productIds != null ? productIds.join(',') : '',
          'page': page.toString(),
          'limit': limit.toString(),
        }.removeEmptyValues(),
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
  Future<ResponseModel> deletePost({
    required bool isLoading,
    required String postId,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        SocialApiEndPoints.deletePost,
        NetworkRequestType.delete,
        null,
        {
          'post_id': postId,
        },
        {
          'Accept': AppConstants.headerAccept,
          'Content-Type': AppConstants.headerContentType,
          'Authorization': header.accessToken,
          'lan': header.language,
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.platformText,
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
          'x-tenant-id': AppConstants.tenantId,
          'x-project-id': AppConstants.projectId,
        },
        isLoading,
      );

  @override
  Future<ResponseModel> getPost({
    required bool isLoading,
    required String postId,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        SocialApiEndPoints.getPost,
        NetworkRequestType.get,
        null,
        {
          'postId': postId,
        },
        {
          'Accept': AppConstants.headerAccept,
          'Content-Type': AppConstants.headerContentType,
          'Authorization': header.accessToken,
          'language': header.language,
          'currencySymbol': header.currencySymbol,
          'currencyCode': header.currencyCode,
          'platform': header.platForm.platformText,
          'latitude': header.latitude.toString(),
          'longitude': header.longitude.toString(),
        },
        isLoading,
      );
}
