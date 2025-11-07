import 'package:ism_video_reel_player/data/models/response_model.dart';
import 'package:ism_video_reel_player/domain/domain.dart';

class AuthMapper {
  CustomResponse<LoginSignupData?> mapLoginData(ResponseModel response) => CustomResponse(
      data: signupResponseModelFromJson(response.data).data, responseCode: response.statusCode);

  CustomResponse<GuestSignInResponse?> mapGuestLoginData(ResponseModel response) => CustomResponse(
      data: guestSignInResponseFromJson(response.data), responseCode: response.statusCode);
}
