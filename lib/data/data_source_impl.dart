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
    final language = '';

    final accessToken = await _localStorageManager.getSecuredValue(IsrLocalStorageKeys.accessToken);

    final refreshToken = '';

    final latitude = 0.0;

    final longitude = 0.0;

    final ipAddress = '';

    final city = '';

    final countryId = '';

    final cityId = '';

    final state = '';

    final postalCode = '';

    final country = '';

    final platForm = IsrVideoReelUtility.platFormType();

    final timeZone = '';

    final currencySymbol = '';

    final currencyCode = '';

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
