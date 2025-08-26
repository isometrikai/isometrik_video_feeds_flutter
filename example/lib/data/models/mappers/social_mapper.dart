import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/utils/extensions.dart';

class SocialMapper {
  CustomResponse<PostResponse?> mapPostResponseData(ResponseModel response) =>
      CustomResponse(data: postResponseFromJson(response.data), responseCode: response.statusCode);

  CustomResponse<List<String>?> mapReasonData(ResponseModel response) => CustomResponse(
      data: reportReasonResponseFromJson(response.data).data, responseCode: response.statusCode);

  CustomResponse<CloudDetailsResponse?> mapCloudinaryData(ResponseModel response) => CustomResponse(
      data: cloudinaryResponseFromJson(response.data), responseCode: response.statusCode);

  CustomResponse<CreatePostResponse?> mapCreatePostResponseData(ResponseModel response) =>
      CustomResponse(
          data: createPostResponseFromJson(response.data), responseCode: response.statusCode);

  CustomResponse<CommentsResponse?> mapCommentsResponse(ResponseModel response) => CustomResponse(
      data: commentsResponseFromJson(response.data), responseCode: response.statusCode);

  CustomResponse<PostDetailsResponse?> mapPostDetailsResponse(ResponseModel response) =>
      CustomResponse(
          data: postDetailsResponseFromJson(response.data), responseCode: response.statusCode);

  CustomResponse<PostData?> mapPostData(ResponseModel response) {
    final post = postResponseFromJson(response.data);
    return CustomResponse(
        data: post.data.isEmptyOrNull == true ? null : post.data!.first,
        responseCode: response.statusCode);
  }

  CustomResponse<TimelineResponse?> mapTimelineResponse(ResponseModel response) => CustomResponse(
      data: timelineResponseFromJson(response.data), responseCode: response.statusCode);
}
