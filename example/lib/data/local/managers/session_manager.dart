import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/domain/domain.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class SessionManager {
  SessionManager(this._localStorageManager);

  final LocalStorageManager _localStorageManager;

  Future<void> createNewUserSession(LoginSignupData? data) async {
    saveIsLoggedIn(true);
    saveUserId(data?.userId ?? '');
    await saveUserToken(data?.token?.accessToken ?? '');
    saveRefreshToken(data?.token?.refreshToken ?? '');
    saveFirstName(data?.firstName ?? '');
    saveLastName(data?.lastName ?? '');
    saveFullName('${data?.firstName ?? ''} ${data?.lastName ?? ''}');
    savePhoneNumber(data?.mobile ?? '');
    saveCountryId(DefaultValues.defaultCountryId);
    saveEmail(data?.email ?? '');
    saveProfilePic(data?.profilePic ?? '');
    saveCurrencyCode(data?.currency ?? '');
    saveCurrencySymbol(data?.currencySymbol ?? '');
  }

  Future<void> createNewUserSessionFromGuest(GuestSignInData? data) async {
    saveIsLoggedIn(false);
    await saveUserToken(data?.token?.accessToken ?? '');
    saveRefreshToken(data?.token?.refreshToken ?? '');
    saveCurrencyCode(DefaultValues.defaultCurrencyCode);
    saveCurrencySymbol(DefaultValues.defaultCurrencySymbol);
  }

  void saveIsLoggedIn(bool isLoggedIn) async {
    await _localStorageManager.saveValue(LocalStorageKeys.isLoggedIn, isLoggedIn, SavedValueDataType.bool);
  }

  Future<bool> isLoggedIn() async =>
      await _localStorageManager.getValue(LocalStorageKeys.isLoggedIn, SavedValueDataType.bool) as bool;

  void saveUserId(String userId) {
    _localStorageManager.saveValueSecurely(LocalStorageKeys.userId, userId);
  }

  Future<String> getUserId() async => await _localStorageManager.getSecuredValue(LocalStorageKeys.userId);

  void saveFirstName(String firstName) {
    _localStorageManager.saveValue(LocalStorageKeys.firstName, firstName, SavedValueDataType.string);
  }

  Future<String> getFirstName() async =>
      await _localStorageManager.getValue(LocalStorageKeys.firstName, SavedValueDataType.string) as String;

  void saveFullName(String fullName) {
    _localStorageManager.saveValue(LocalStorageKeys.fullName, fullName, SavedValueDataType.string);
  }

  Future<String> getFullName() async =>
      await _localStorageManager.getValue(LocalStorageKeys.fullName, SavedValueDataType.string) as String;

  void saveLastName(String lastName) {
    _localStorageManager.saveValue(LocalStorageKeys.lastName, lastName, SavedValueDataType.string);
  }

  Future<String> getLastName() async =>
      await _localStorageManager.getValue(LocalStorageKeys.lastName, SavedValueDataType.string) as String;

  void saveProfilePic(String profile) {
    _localStorageManager.saveValue(LocalStorageKeys.profilePic, profile, SavedValueDataType.string);
  }

  void savePhoneNumber(String phoneNumber) {
    _localStorageManager.saveValueSecurely(LocalStorageKeys.phoneNumber, phoneNumber);
  }

  Future<String> getPhoneNumber() async => await _localStorageManager.getSecuredValue(LocalStorageKeys.phoneNumber);

  void saveCountryId(String countryId) {
    _localStorageManager.saveValue(LocalStorageKeys.countryId, countryId, SavedValueDataType.string);
  }

  Future<String> getCountryId() async =>
      await _localStorageManager.getValue(LocalStorageKeys.countryId, SavedValueDataType.string) as String;

  void saveEmail(String email) {
    _localStorageManager.saveValue(LocalStorageKeys.email, email, SavedValueDataType.string);
  }

  Future<String> getEmail() async =>
      await _localStorageManager.getValue(LocalStorageKeys.email, SavedValueDataType.string) as String;

  Future<String> getProfilePic() async =>
      await _localStorageManager.getValue(LocalStorageKeys.profilePic, SavedValueDataType.string) as String;

  Future<String> getUserToken() async => await _localStorageManager.getSecuredValue(LocalStorageKeys.accessToken);

  Future<void> saveUserToken(String userToken) async {
    await _localStorageManager.saveValueSecurely(LocalStorageKeys.accessToken, userToken);
  }

  Future<String> getRefreshToken() async => await _localStorageManager.getSecuredValue(LocalStorageKeys.refreshToken);

  void saveRefreshToken(String userToken) {
    _localStorageManager.saveValueSecurely(LocalStorageKeys.refreshToken, userToken);
  }

  Future<String> getCurrencyCode() async =>
      await _localStorageManager.getValue(LocalStorageKeys.currencyCode, SavedValueDataType.string) as String;

  void saveCurrencyCode(String currencyCode) {
    _localStorageManager.saveValue(LocalStorageKeys.currencyCode, currencyCode, SavedValueDataType.string);
  }

  Future<String> getCurrencySymbol() async =>
      await _localStorageManager.getValue(LocalStorageKeys.currencySymbol, SavedValueDataType.string) as String;

  void saveCurrencySymbol(String currencySymbol) {
    _localStorageManager.saveValue(
        LocalStorageKeys.currencySymbol, Utility.encodeChar(currencySymbol), SavedValueDataType.string);
  }

  void clearSession() async {
    await _localStorageManager.clearData();
  }
}
