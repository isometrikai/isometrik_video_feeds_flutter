import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/remote/remote.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class AuthRepositoryImpl extends AuthRepository {
  AuthRepositoryImpl(this.apiService, this.dataSource, this._sessionManager);

  final AuthApiService apiService;
  final DataSource dataSource;
  final SessionManager _sessionManager;
  final AuthMapper _mapper = AuthMapper();
  final CommonMapper _commonMapper = CommonMapper();

  @override
  Future<CustomResponse<ResponseClass?>> login({
    required bool isLoading,
    required Map<String, dynamic>? loginMap,
  }) async {
    try {
      final header = await dataSource.getHeader();
      final response = await apiService.login(
        isLoading: isLoading,
        header: header,
        loginMap: loginMap,
      );
      return _commonMapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CustomResponse<LoginSignupData?>> verifyOtp({
    required bool isLoading,
    required String otpId,
    required String otp,
    required String mobileNumber,
  }) async {
    try {
      final header = await dataSource.getHeader();
      final response = await apiService.verifyOtp(
        isLoading: isLoading,
        header: header,
        otp: otp,
        otpId: otpId,
        mobileNumber: mobileNumber,
      );
      final loginData = _mapper.mapLoginData(response);
      if (response.statusCode == 200) {
        await saveRequiredDataInLocalStorage(loginData.data);
      }
      return loginData;
    } catch (e) {
      rethrow;
    }
  }

  ///save all required data in local storage
  Future<void> saveRequiredDataInLocalStorage(LoginSignupData? data) async {
    await dataSource.getStorageManager().saveValue(
        LocalStorageKeys.isFirstTimeVisit, false, SavedValueDataType.bool);
    await _sessionManager.createNewUserSession(data);
    await dataSource.getStorageManager().saveValue(LocalStorageKeys.longitude,
        data?.location?.long?.toDouble(), SavedValueDataType.double);
    await dataSource.getStorageManager().saveValue(LocalStorageKeys.latitude,
        data?.location?.lat?.toDouble(), SavedValueDataType.double);
  }

  @override
  Future<CustomResponse<LoginSignupData?>> sendOtp({
    required bool isLoading,
    required String mobileNumber,
  }) =>
      throw UnimplementedError();

  @override
  Future<CustomResponse<ResponseClass?>> guestLogin({
    required bool isLoading,
  }) async {
    try {
      final header = await dataSource.getHeader();
      final response = await apiService.guestLogin(
        isLoading: isLoading,
        header: header,
      );
      if (response.statusCode == 200) {
        final guestSignInResponse = _mapper.mapGuestLoginData(response);
        await saveGuestSignInDataIntoLocal(guestSignInResponse.data?.data);
      }
      return _commonMapper.mapResponseData(response);
    } catch (e) {
      rethrow;
    }
  }

  /// save guest sign in data into local storage
  Future<void> saveGuestSignInDataIntoLocal(GuestSignInData? data) async {
    await _sessionManager.createNewUserSessionFromGuest(data);
  }
}
