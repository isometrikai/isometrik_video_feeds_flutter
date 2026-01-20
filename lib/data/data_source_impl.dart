import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Default [DataSource] implementation backed by [LocalStorageManager].
class DataSourceImpl extends DataSource {
  /// Creates a [DataSourceImpl] using the provided [_localStorageManager].
  DataSourceImpl(
    this._localStorageManager,
  );

  final LocalStorageManager _localStorageManager;

  @override
  Future<Header> getHeader() async => initializeHeader();

  @override
  LocalStorageManager getStorageManager() => _localStorageManager;

  /// Builds a [Header] from values stored in [LocalStorageManager].
  ///
  /// This is typically called before network requests to ensure the SDK uses
  /// the latest auth tokens, locale, device location, and tenant/project ids.
  Future<Header> initializeHeader() async {
    final language = await _localStorageManager.getValue(
      LocalStorageKeys.language,
      SavedValueDataType.string,
    ) as String;

    final accessToken = await _localStorageManager
        .getSecuredValue(LocalStorageKeys.accessToken);

    final refreshToken = await _localStorageManager
        .getSecuredValue(LocalStorageKeys.refreshToken);

    final latitude = await _localStorageManager.getValue(
      LocalStorageKeys.latitude,
      SavedValueDataType.double,
    ) as double;

    final longitude = await _localStorageManager.getValue(
      LocalStorageKeys.longitude,
      SavedValueDataType.double,
    ) as double;

    final ipAddress = await _localStorageManager.getValue(
      LocalStorageKeys.ipAddress,
      SavedValueDataType.string,
    ) as String;

    final city = await _localStorageManager.getValue(
      LocalStorageKeys.city,
      SavedValueDataType.string,
    ) as String;

    final countryId = await _localStorageManager.getValue(
      LocalStorageKeys.countryId,
      SavedValueDataType.string,
    ) as String;

    final cityId = '';

    final state = await _localStorageManager.getValue(
      LocalStorageKeys.state,
      SavedValueDataType.string,
    ) as String;

    final postalCode = '';

    final country = await _localStorageManager.getValue(
      LocalStorageKeys.country,
      SavedValueDataType.string,
    ) as String;

    final platForm = Utility.platFormType();

    final timeZone = DateTime.now().timeZoneName;

    final currencySymbol = await _localStorageManager.getValue(
      LocalStorageKeys.currencySymbol,
      SavedValueDataType.string,
    ) as String;

    final currencyCode = await _localStorageManager.getValue(
      LocalStorageKeys.currencyCode,
      SavedValueDataType.string,
    ) as String;

    final xTenantId = await _localStorageManager.getValue(
      LocalStorageKeys.xTenantId,
      SavedValueDataType.string,
    ) as String;

    final xProjectId = await _localStorageManager.getValue(
      LocalStorageKeys.xProjectId,
      SavedValueDataType.string,
    ) as String;

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
