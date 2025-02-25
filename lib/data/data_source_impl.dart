import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class DataSourceImpl extends DataSource {
  DataSourceImpl(
    this._localStorageManager,
  );

  final IsrLocalStorageManager _localStorageManager;
  late Header header;

  @override
  Future<Header> getHeader() async => await initializeHeader();

  @override
  IsrLocalStorageManager getStorageManager() => _localStorageManager;

  Future<Header> initializeHeader() async {
    final language =
        await _localStorageManager.getValue(IsrLocalStorageKeys.language, SavedValueDataType.string) as String;

    final accessToken = await _localStorageManager.getSecuredValue(IsrLocalStorageKeys.accessToken);

    final refreshToken = await _localStorageManager.getSecuredValue(IsrLocalStorageKeys.refreshToken);

    final latitude =
        await _localStorageManager.getValue(IsrLocalStorageKeys.latitude, SavedValueDataType.double) as double;

    final longitude =
        await _localStorageManager.getValue(IsrLocalStorageKeys.longitude, SavedValueDataType.double) as double;

    final ipAddress =
        await _localStorageManager.getValue(IsrLocalStorageKeys.userIP, SavedValueDataType.string) as String;

    final city = '';

    final countryId = '';

    final cityId = '';

    final state = '';

    final postalCode = '';

    final country = '';

    final platForm = IsrVideoReelUtility.platFormType();

    final timeZone = '';

    final currencySymbol =
        await _localStorageManager.getValue(IsrLocalStorageKeys.currencySymbol, SavedValueDataType.string) as String;

    final currencyCode =
        await _localStorageManager.getValue(IsrLocalStorageKeys.currencyCode, SavedValueDataType.string) as String;

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
