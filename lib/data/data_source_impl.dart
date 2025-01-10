import 'package:injectable/injectable.dart';
import 'package:ism_video_reel_player/export.dart';

@lazySingleton
class DataSourceImpl extends DataSource {
  final storageManager = LocalStorageManager();

  late Header header;

  @override
  Services getNetworkManager() => ServiceProvider();

  @override
  Future<Header> getHeader() async => await initializeHeader();

  @override
  LocalStorageManager getStorageManager() => storageManager;

  Future<Header> initializeHeader() async {
    final language = '';

    final accessToken = '';

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

    final platForm = Utility.platFormType();

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
