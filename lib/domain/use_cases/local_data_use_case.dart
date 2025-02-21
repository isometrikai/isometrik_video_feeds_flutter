import 'package:ism_video_reel_player/domain/domain.dart';

class LocalDataUseCase extends BaseUseCase {
  LocalDataUseCase(this.repository);

  final IsrLocalStorageRepository repository;

  Future<String> getUserId() async => await repository.getUserId();

  Future<String> getEmail() async => await repository.getEmail();

  Future<String> getCurrencySymbol() async => await repository.getCurrencySymbol();

  Future<String> getCurrencyCode() async => await repository.getCurrencyCode();

  Future<bool> isLoggedIn() async => await repository.isLoggedIn();

  Future<String> getLanguage() async => await repository.getLanguage();

  Future<String> getAccessToken() async => await repository.getAccessToken();

  Future<String> getRefreshToken() async => await repository.getRefreshToken();

  Future<String> getPhoneNumber() async => await repository.getPhoneNumber();

  Future<String> getFirstName() async => await repository.getFirstName();

  Future<String> getLastName() async => await repository.getLastName();

  Future<String> getProfilePic() async => await repository.getProfilePic();

  Future<String> getUserInfo() async => await repository.getUserInfo();

  void saveLanguage(String value) => repository.saveLanguage(value);

  void saveIsLoggedIn(bool value) => repository.saveIsLoggedIn(value);

  void saveEmail(String value) => repository.saveEmail(value);

  void saveAccessToken(String value) => repository.saveAccessToken(value);

  void saveRefreshToken(String value) => repository.saveRefreshToken(value);

  void savePhoneNumber(String value) => repository.savePhoneNumber(value);

  void saveFirstName(String value) => repository.saveFirstName(value);

  void saveLastName(String value) => repository.saveLastName(value);

  void saveProfilePic(String value) => repository.saveProfilePic(value);

  void clearLocalData() {
    repository.clearLocalData();
  }

  void deleteAllSecuredValues() {
    repository.deleteAllSecuredValues();
  }

  void deleteSecuredValue(String key) {
    repository.deleteSecuredValue(key);
  }

  void deleteValue(String key) {
    repository.deleteValue(key);
  }

  void clearSession() {
    repository.clearSession();
  }
}
