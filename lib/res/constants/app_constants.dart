class AppConstants {
  AppConstants._();

  static const String appName = 'Reels Player';

  static const Duration animationDuration = Duration(milliseconds: 300);

  static const Duration timeOutDuration = Duration(seconds: 60);

  static const Duration debounceDuration = Duration(milliseconds: 750);

  static const int pinCodeLength = 6;
  static const int couponCodeLength = 5;
  static const String primaryFontFamily = 'Inter';
  static const String secondaryFontFamily = 'Inter';

  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  static const String passwordPattern =
      r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';

  static const String headerAccept = 'application/json';
  static const String headerContentType = 'application/json';

  static const bool isGumletEnable = false;
  static const String cloudinaryFolder = 'ShopAR/post/image';
}

abstract class AppUrl {
  static String appBaseUrl = '';
  static const String gumletUrl =
      'https://cdn.trulyfreehome.dev/tenant_001/project_001/user_007';
  static const String imageBaseUrl =
      'https://cdn.trulyfreehome.dev/tenant_001/project_001/user_007/';
}

abstract class DefaultValues {
  static const String defaultStoreCategoryId = '620cbd0bd3f999273e4839b3';

  static const String defaultCountryIsoCode = 'IN';

  static const String defaultCountryName = 'India';

  static const String defaultCountryDialCode = '91';

  static const String defaultLanguage = 'en';

  static const String defaultCurrencySymbol = '₹';

  static const String defaultCurrencyCode = 'INR';

  static const double defaultLatitude = 12.976750;

  static const double defaultLongitude = 77.575279;

  static const String defaultIpAddress = '192.168.1.0';

  static const String defaultCountryId = '620ca66bcf0bd360e40dfe23';
}
