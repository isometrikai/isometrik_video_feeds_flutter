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
      'Bearer eyJhbGciOiJSU0EtT0FFUCIsImN0eSI6IkpXVCIsImVuYyI6IkExMjhHQ00iLCJ0eXAiOiJKV1QifQ.eE9tX3TmagLqO0ulNIxl5RdYLwUfXfVTp3m9rZSyP9GcFNt5HDjuDo51ZRG7XWbIHhJFB9ajDIT_gL73DeizPi0-iLdmY7fkScibyISGp2aJEK__qHNGV6-Xzru3thkBxCFnBhQcW5bF7xFOyt_nGwMiSRziu6S1SEmfzhLXaw4.Imi_glmUC7CowCcz.tPsw-U3axEoxNeqsriWvv36OcQwuRjeXdQ68bsyNt76ody6exlo_Z7Lp8im6Hvrzx9JVNsELV3fjsO8iMtHUgwC7q4M1fAsgrfykgI6N7d4kX01daA2UfTLLW7MmV5DqOdmZOhWqNuOSgIx_1QSBXLfF-wLU-zyq96GDBXmbNZ3dcsy551lhYG2_qIdMcoWwzotc7J4EsEJ_N3Wg_IqTRuQO5_61Y3OD6SdKP4sPHPWHshYP4LiYrVrly-bcZHcT-PNK8PM9BpyNK1kisvlXqgSLwfAQtcZLiILU8Cr_EQKE0IbzPXlRqhbl5dqpdLilhCluncD1S2uNzIMwM38VoG-vK1KNLD_qAReNwYZqxPHbUHIKhIEIj6AZYJz3gGUpuKWVsHZO2A7-Ulq2RN5nX9HqfPZCfOHvtZWXbPocefGq8osm4YRAlDyIhjffulaDsQKlTH4EoyPx9OiluvWrdiQzXIq8v4aGWChieiI2a_q7PJwuxIWPYLwmkXgkVU6GVSFYFOTq7DlfWNdaOxCNjGZeCC4ukb1Gl9_5DeVTJol9UAh-urGsxBgoiHvyBmflZgi_KfMM5Vyxj58GFUCgf6fkroixwbSptNUl-2jYobh_6VawqPvffvQ3mk70BxNjxAHWzbIuElluhwbEjNMSDz401xWwvq4brmVUBVKkaPOmq70BWmHNNajQYh9jKhe2GK_UwY0XlXSu9npSRZcoFUiscrSNpNujLWxASQs4UdtIK3YKlpvdZyTSv4AWFawrsNnlkeg4YUUZTyzCNRVH-qMWU5XAOvQLr_oVjAHMTf8AUknMO60R68oL8EqHgOkGva1xknzjKWrQlbpLCkn2T08x3pipKFAH5txrbxeniLUM-EuN05ZLzytmdWFpMagCNXSRQhTLZGYhq8C3WsZ1GiyXO7Ixh_KxtP6YQgkpUgA5rIi3RwZUCK7en1iqjexVRj0KuRmfa-xEmsfwR7A4sfzh60SPzS8TBd9hIg07ZxNbMs5UlfdzdAA9UzEvjOq06uHVyZO7gsFjhViupMPM0i_LJbUtWmFwMSZzyK6f27sZ0r9nAlJAllGnEM7m_mfzdYFeG0Itin3kORkKGRw9z8zmTjAslhEIp5TUkQ-6HTVM-JZEes9ljr_aKCwB8kjjkYVi2cd88S90QFrEWrPH4Tp3KhnajFAfeJbQHWRNWAQxEXp_7h4gixXKn0C8EBZl9LdEhdnFOTWCDUG53QvnrUeJb_DQv-_j5BMTtR3BcOruFcF6RpKESS-zg-d8LRzgZ2GpMvgyMrTF9CVlAqG3hh7h3954GC2PrO4LK79fFhzAyMFLmTz_en5KwUDifNWgyO1D-e0MlNz7t9r0FBi40GCYmGbqsc1kIrbQOkkZrfGPpMZ-3AP3IjB2J6s0lAsb0ZgkjZwm-7s0j09m8oEJxz-P5gaYzp71p5DcUmoa3C5YujC4GEDGTSv3MPDiQ1O-x6MewbSO3tqL4BUKrxTzgMEfk50nUKzp2iZwf7hN5Ha152RwDTDRMJEEidjPN7o-N2QVIiRSsNkoR662Mw1TP1jBIttnEkAxXKS3elqKeQmOznpMqCLW_6ZF-vJ0_t4RHL3LXuC3QtJCBmTQ55URRTKRjY1Tl_8mzRyqRt37J0hvr6fs-5zOdCxZA0pBtRDhFUpjmJafEb5xk-VMUtoQdeS1H1DptcxMf_0STiN4cZFZ_nZEc_oR8H1yHYkhR575g7y9REaTAM322zNP1hXq5o5fLCVGopFaa-Jz.b9LxbqxdJnZotm12ZAwXsQ';

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
    required FollowAction followAction,
  }) async {
    final appVersion = await Utility.getAppVersion();
    final map = {
      'following_id': followingId,
    };
    return await networkClient.makeRequest(
      SocialApiEndPoints.postFollowPost,
      followAction == FollowAction.follow
          ? NetworkRequestType.post
          : NetworkRequestType.delete,
      followAction == FollowAction.follow ? map : null,
      followAction == FollowAction.unfollow ? map : null,
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
    final queryParams = socialPostAction == SocialPostAction.unSave
        ? {'post_id': postId}
        : null;
    final bodyParams =
        socialPostAction == SocialPostAction.save ? {'post_id': postId} : null;
    return await networkClient.makeRequest(
      SocialApiEndPoints.postSavePost,
      methodType,
      bodyParams,
      queryParams,
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
        'city': header.city,
        'country': header.country,
        'ipaddress': header.ipAddress,
        'version': deviceInfoManager.appVersion,
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
        likeAction == LikeAction.like
            ? SocialApiEndPoints.postLike
            : SocialApiEndPoints.postUnLike,
        likeAction == LikeAction.like
            ? NetworkRequestType.post
            : NetworkRequestType.delete,
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

  @override
  Future<ResponseModel> processMedia({
    required bool isLoading,
    required String postId,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        SocialApiEndPoints.postMediaProcess(postId),
        NetworkRequestType.post,
        null,
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
        },
        isLoading,
      );

  @override
  Future<ResponseModel> searchUser({
    required bool isLoading,
    required int limit,
    required int page,
    required String searchText,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        SocialApiEndPoints.getSearchUsers,
        NetworkRequestType.get,
        null,
        {
          'search': searchText,
          'page': page.toString(),
          'page_size': limit.toString(),
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
          'x-tenant-id': AppConstants.tenantId,
          'x-project-id': AppConstants.projectId,
        },
        isLoading,
      );

  @override
  Future<ResponseModel> searchTag({
    required bool isLoading,
    required int limit,
    required int page,
    required String searchText,
    required Header header,
  }) async =>
      await networkClient.makeRequest(
        SocialApiEndPoints.getSearchTags,
        NetworkRequestType.get,
        null,
        {
          'q': searchText,
          'page': page.toString(),
          'page_size': limit.toString(),
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
          'x-tenant-id': AppConstants.tenantId,
          'x-project-id': AppConstants.projectId,
        },
        isLoading,
      );
}
