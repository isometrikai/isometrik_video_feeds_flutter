import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/models/custom_response.dart';
import 'package:ism_video_reel_player/domain/models/response/post_response.dart';

class PostMapper {
  CustomResponse<PostResponse?> mapPostResponseData(ResponseModel response) =>
      CustomResponse(data: postResponseFromJson(response.data), responseCode: response.statusCode);
}
