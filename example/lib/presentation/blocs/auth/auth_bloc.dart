import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ism_video_reel_player_example/core/core.dart';
import 'package:ism_video_reel_player_example/di/di.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this.loginUseCase,
    this.verifyOtpUseCase,
    this._guestLoginUseCase,
    this._localDataUseCase,
  ) : super(AuthInitialState()) {
    on<StartLoginEvent>(_onStartLogin);
    on<LoginEvent>(_onLogin);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<SendOtpEvent>(_sendOtp);
  }

  final LoginUseCase loginUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final GuestLoginUseCase _guestLoginUseCase;
  final LocalDataUseCase _localDataUseCase;

  FutureOr<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    final loginMap = {'verifyType': 2, 'loginType': 1, 'countryCode': event.countryCode, 'mobile': event.mobileNumber};
    final apiResult = await loginUseCase.executeLogin(
      isLoading: event.isLoading,
      loginMap: loginMap,
    );
    if (apiResult.isSuccess) {
      final jsonString = jsonDecode(apiResult.data?.data ?? '');
      final otpId = jsonString['data']['otpId'] as String;
      InjectionUtils.getRouteManagement().goToOtpScreen(arguments: {
        'otpId': otpId,
        'mobileNumber': event.mobileNumber,
        'countryCode': event.countryCode,
        'loginType': '1',
      });
    } else {
      ErrorHandler.showAppError(appError: apiResult.error, isNeedToShowError: true);
    }
  }

  FutureOr<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<AuthState> emit) async {
    final apiResult = await verifyOtpUseCase.executeVerifyOtp(
      isLoading: event.isLoading,
      otpId: event.otpId,
      otp: event.otp,
      mobileNumber: event.mobileNumber,
    );
    if (apiResult.isSuccess) {
      InjectionUtils.getRouteManagement().goToHomeScreen();
    } else {
      ErrorHandler.showAppError(appError: apiResult.error, isNeedToShowError: true);
    }
  }

  FutureOr<void> _sendOtp(SendOtpEvent event, Emitter<AuthState> emit) async {}

  FutureOr<void> _onStartLogin(StartLoginEvent event, Emitter<AuthState> emit) async {
    final accessToken = await _localDataUseCase.getAccessToken();
    if (accessToken.isEmptyOrNull) {
      await _guestLoginUseCase.executeGuestLogin(
        isLoading: true,
      );
    }
  }
}
