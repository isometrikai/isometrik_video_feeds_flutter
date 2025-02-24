import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class DataSourceImpl extends DataSource {
  DataSourceImpl(this._localStorageManager, this._sessionManager);

  final LocalStorageManager _localStorageManager;
  final SessionManager _sessionManager;
  late Header header;

  @override
  Future<Header> getHeader() async => await initializeHeader();

  @override
  LocalStorageManager getStorageManager() => _localStorageManager;

  Future<Header> initializeHeader() async {
    final language =
        await _localStorageManager.getValue(LocalStorageKeys.language, SavedValueDataType.string) as String;

    final accessToken = await _sessionManager.getUserToken();

    final refreshToken = await _sessionManager.getRefreshToken();

    final latitude =
        await _localStorageManager.getValue(LocalStorageKeys.latitude, SavedValueDataType.double) as double;

    final longitude =
        await _localStorageManager.getValue(LocalStorageKeys.longitude, SavedValueDataType.double) as double;

    final ipAddress = await _localStorageManager.getValue(LocalStorageKeys.userIP, SavedValueDataType.string) as String;

    final city = '';

    final countryId = '';

    final cityId = '';

    final state = '';

    final postalCode = '';

    final country = '';

    final platForm = Utility.platFormType();

    final timeZone = '';

    final currencySymbol =
        await _localStorageManager.getValue(LocalStorageKeys.currencySymbol, SavedValueDataType.string) as String;

    final currencyCode =
        await _localStorageManager.getValue(LocalStorageKeys.currencyCode, SavedValueDataType.string) as String;

    return Header(
      accessToken: accessToken,
      refreshToken: refreshToken,
      language: language,
      latitude: latitude,
      longitude: longitude,
      ipAddress: ipAddress,
      countryId: countryId,
      city: city,
      cityId: cityId,
      state: state,
      postalCode: postalCode,
      country: country,
      platForm: platForm,
      timeZone: timeZone,
      currencySymbol: currencySymbol,
      currencyCode: currencyCode,
    );
  }
}
