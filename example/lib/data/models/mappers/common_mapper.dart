import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';

class CommonMapper {
  CustomResponse<ResponseClass?> mapResponseData(ResponseModel response) =>
      CustomResponse(
          data: ResponseClass.fromJson(response.toJson()),
          responseCode: response.statusCode);
}
