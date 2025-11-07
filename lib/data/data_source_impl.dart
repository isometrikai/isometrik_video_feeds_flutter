import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class DataSourceImpl extends DataSource {
  DataSourceImpl(
    this._localStorageManager,
  );

  final LocalStorageManager _localStorageManager;
  late Header header;

  @override
  Future<Header> getHeader() async => await initializeHeader();

  @override
  LocalStorageManager getStorageManager() => _localStorageManager;

  Future<Header> initializeHeader() async {
    final language = await _localStorageManager.getValue(
        LocalStorageKeys.language, SavedValueDataType.string) as String;

    final accessToken = await _localStorageManager.getSecuredValue(LocalStorageKeys.accessToken);

    final refreshToken = await _localStorageManager.getSecuredValue(LocalStorageKeys.refreshToken);

    final latitude = await _localStorageManager.getValue(
        LocalStorageKeys.latitude, SavedValueDataType.double) as double;

    final longitude = await _localStorageManager.getValue(
        LocalStorageKeys.longitude, SavedValueDataType.double) as double;

    final ipAddress = await _localStorageManager.getValue(
        LocalStorageKeys.ipAddress, SavedValueDataType.string) as String;

    final city = '';

    final countryId = '';

    final cityId = '';

    final state = '';

    final postalCode = '';

    final country = '';

    final platForm = Utility.platFormType();

    final timeZone = '';

    final currencySymbol = await _localStorageManager.getValue(
        LocalStorageKeys.currencySymbol, SavedValueDataType.string) as String;

    final currencyCode = await _localStorageManager.getValue(
        LocalStorageKeys.currencyCode, SavedValueDataType.string) as String;

    final xTenantId = await _localStorageManager.getValue(
        LocalStorageKeys.xTenantId, SavedValueDataType.string) as String;

    final xProjectId = await _localStorageManager.getValue(
        LocalStorageKeys.xProjectId, SavedValueDataType.string) as String;

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
      xTenantId: xTenantId,
      xProjectId: xProjectId,
    );
  }
}
