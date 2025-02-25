import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class CommonMapper {
  CustomResponse<ResponseClass?> mapResponseData(ResponseModel response) =>
      CustomResponse(data: ResponseClass.fromJson(response.toJson()), responseCode: response.statusCode);

  CustomResponse<List<String>?> mapReasonData(ResponseModel response) =>
      CustomResponse(data: reportReasonResponseFromJson(response.data).data, responseCode: response.statusCode);
}
