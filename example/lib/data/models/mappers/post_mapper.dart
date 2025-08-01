import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class PostMapper {
  CustomResponse<PostResponse?> mapPostResponseData(ResponseModel response) =>
      CustomResponse(data: postResponseFromJson(response.data), responseCode: response.statusCode);

  CustomResponse<List<String>?> mapReasonData(ResponseModel response) => CustomResponse(
      data: reportReasonResponseFromJson(response.data).data, responseCode: response.statusCode);

  CustomResponse<CloudDetailsResponse?> mapCloudinaryData(ResponseModel response) => CustomResponse(
      data: cloudinaryResponseFromJson(response.data), responseCode: response.statusCode);

  CustomResponse<CreatePostResponse?> mapCreatePostResponseData(ResponseModel response) =>
      CustomResponse(
          data: createPostResponseFromJson(response.data), responseCode: response.statusCode);

  CustomResponse<TimelineResponse?> mapTimelineResponse(ResponseModel response) => CustomResponse(
        data: timelineResponseFromMap(response.data),
        responseCode: response.statusCode,
      );
}
