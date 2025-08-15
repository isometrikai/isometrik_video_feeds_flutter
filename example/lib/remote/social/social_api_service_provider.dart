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
      'Bearer eyJhbGciOiJSU0EtT0FFUCIsImN0eSI6IkpXVCIsImVuYyI6IkExMjhHQ00iLCJ0eXAiOiJKV1QifQ.GZOPy3DuEddv3r_VV_33SGjiT0kg-W-uh-byHZNTebK6c04POA4MAG4aUtW9Y-SBi8_xHlAV9BFvBtqOBmLZTT6ALC775NJaDNIQlwMv-XYXqWc59BqEld75mMtGlaLTVY9viflWKsbwMRkxXgT_3A624W7JdmIj20LCVk-sv8M.KXlMOC15QPaYfVwD.Gv8_H4wofhIdaST8aO_Lw2_34n30YplBXtGApOkGsklf_48GUP73qVmDeQvLPK9_Pofy6LwcL8s3Sr8Mxs4WPi-wOcG6K4t3vQZbyQxUIlM6XdEnMv1VN_qOhbDSGKTAQyRZkzUsFQP_oTJRx5UIzFHvTRL_8s7GR27nlOS3a2Ke1SmPdKqWZnVyWYmtGfNlBH4y9reBtSfQhQmfR3hPCx_o5jqu_ISqAyuMx142dqJOWGGgS15qevWu94Z-e690vUpwwj7UzqcAoO2cpHzetkPRpb8LugIm-oEsVpPmjmTdT5BbrZMe0b7sHAKaVInwV6GEgRdbSpwcOLPB27OG1oE_Sq2eIhJfAej_wc5R-gLfVzmV7Xot6na8kO_jrFQEDvtvDsSF2x8h8h9_1mHaqDJI9gsFU3TBBCfzxUeqpwBiQQIeUDvZLp5I47mzvY9kH9359CAYddkU1Xa3kk1VcwfVvirOVgDmCkTxXIrBOFOn9n6IHhDGAJSCtucCGo65QLl5lobA4HBLcIzY36vMzvRpmYnjIaQ6GZYJgo6vkurNE2EV7lT_Cv_GwQsUGJjy_YSgWHnW4GQlgTD2TteFdo9LU_h9LT9PsPuDa4fdvhht7NLkbh3xTRY1O9EDfLCoML5HsPNneXn453Qaoc4dG-8rAlCGRtD1xZgPDeX7BBGxWDYH_5-ovDksviiTOzDis5kTLPMLZ8cfnrOJ2c6EBHRTad8xczYiCoEknn40StcR8pLYxSWAbf2VtxhCpxqhklszey1pFykzDwHbjWiUL82BIj0wCk0nR5qXnUWIJKxmy2sbT_A3QNBxOmjyrcsPfc6Mhd3OOMYUUPhpHSV1dw5fby9rUTcDQFz0R-pdnyydybdg7D6Cvz3qlrCMC_bsqWtCAt3VGUFTYfgfmxKt_Y6lYY0oIBHe_qwYGepXxt0Cp7TxuxVlvmMs2SU4e4QUIeCXbLK9iL20y5ZPZ5_nTd_RrQS8bzaIvRIUk2ZLrDDxkbw3VgEwFTpZT2xHQyWhTJPp0r-adw7qa12-vuTs3VDC1GFftD2mryZKxQpU0KwEIoeMIZ1cAnXDKKlGc6NbNa2jWYfgEOpiHb20CXeOcxkFZqarG00EgVqtjpXQfk6E0KDcNc_NCGjCJ63p5-fSTA71kEuqOX7nStcNxn5IxNjKMIZR1MWhMY8cvaJjd0Z_i7pdLw07zx41QA3JUqvF30c2kt5YAV-9B60CfWy42pXF6LfaElWzEpMu2FO3tC3ZYwUGVu0wzB_pbwTx_54qfVfifkwh8VdNlFUzJj1SbJcR_-9a-UB5TLQiLd1mzsZGBjTUVdJKGX0b_B9PTosiQkQP2dgjIA4u5533N7RTeT7vQ1t_S45w84E-4WwqCINWhVo_gmzRcEllzmRDDDrcOY1di9usgCiAz4TJffGnBPmRSd9ZZLUGKFSFdMyuNp15T5asEkqb2XZBW-5XfB-MSwCU7-3vsRIEjmZizMdYQrmgdGXyp7V1Dcqfkadmg9kGihB51Fh0xu2usQrJHCSbO7fKA_HQX-UlmzpZf79DZr2J0NyG0zEb8yX_Lz3a9OKq-4fGPVPIyjeh06Mt7BwjX0jarWqRNBUpUWyuSn2tUiStyU1nx-BM88Ehe6VwxD9hPul1f9GDk5gy1NvZ4EZxcZKQ_LAyaDHhP2Qb6gPPKnCuffCKO96NhycDxtX3bXsIiEEG1AMTGHW-DEQaxXUtYXSCEJ1PbMA6LT-38CFtnLE-2zE2foQaBSpF.K8cHkDa2pckysnmd1n16Mg';

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
