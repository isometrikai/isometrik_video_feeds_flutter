/// Request metadata used by the SDK's network layer.
///
/// This model collects authentication tokens, localization, device location,
/// tenant/project identifiers, and other headers commonly required by the API.
class Header {
  /// Creates a [Header].
  ///
  /// Parameters:
  /// - [accessToken]: Bearer/access token used for authenticated requests.
  /// - [refreshToken]: Refresh token used to renew [accessToken].
  /// - [language]: Current language/locale code.
  /// - [ipAddress]: Client IP address (if available).
  /// - [countryId]: Country identifier expected by the backend.
  /// - [latitude] / [longitude]: Last known device coordinates.
  /// - [city] / [cityId]: City name and identifier.
  /// - [state]: State/province name.
  /// - [postalCode]: Postal/zip code.
  /// - [country]: Country name.
  /// - [platForm]: Numeric platform identifier produced by the SDK.
  /// - [timeZone]: Device timezone name.
  /// - [currencySymbol] / [currencyCode]: Currency metadata.
  /// - [xTenantId] / [xProjectId]: Tenant/project headers required by multi-tenant APIs.
  Header({
    required this.accessToken,
    required this.refreshToken,
    required this.language,
    required this.ipAddress,
    required this.countryId,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.cityId,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.platForm,
    required this.timeZone,
    required this.currencySymbol,
    required this.currencyCode,
    required this.xTenantId,
    required this.xProjectId,
  });

  /// Bearer/access token used for authenticated requests.
  String accessToken;

  /// Refresh token used to renew [accessToken].
  String refreshToken;

  /// Current language/locale code.
  String language;

  /// Client IP address (if available).
  String ipAddress;

  /// Country identifier expected by the backend.
  String countryId;

  /// Last known latitude.
  double latitude;

  /// Last known longitude.
  double longitude;

  /// City name.
  String city;

  /// City identifier.
  String cityId;

  /// State/province name.
  String state;

  /// Postal/zip code.
  String postalCode;

  /// Country name.
  String country;

  /// Numeric platform identifier produced by the SDK.
  int platForm;

  /// Device timezone name.
  String timeZone;

  /// Currency symbol.
  String currencySymbol;

  /// Currency ISO code.
  String currencyCode;

  /// Tenant identifier header.
  String xTenantId;

  /// Project identifier header.
  String xProjectId;
}
