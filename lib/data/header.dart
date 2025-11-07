class Header {
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

  String accessToken;
  String refreshToken;
  String language;
  String ipAddress;
  String countryId;
  double latitude;
  double longitude;
  String city;
  String cityId;
  String state;
  String postalCode;
  String country;
  int platForm;
  String timeZone;
  String currencySymbol;
  String currencyCode;
  String xTenantId;
  String xProjectId;
}
