class AppConstants {
  AppConstants._();

  static const String boxName = 'flutter_ecommerce';
  static const String appName = 'Meolaa';

  static const int otpDuration = 60;

  static const Duration animationDuration = Duration(milliseconds: 300);

  static const Duration timeOutDuration = Duration(seconds: 60);

  static const Duration debounceDuration = Duration(milliseconds: 750);

  static const int pinCodeLength = 6;
  static const int couponCodeLength = 5;
  static const String primaryFontFamily = 'Satoshi';
  static const String secondaryFontFamily = 'Agenda';

  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  static const String passwordPattern =
      r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';

  static const String headerAccept = 'application/json';
  static const String headerContentType = 'application/json';
  static const String headerAcceptPlainText = 'application/json, text/plain, /';

  static const int otpLength = 4;
  static const bool isTaxCalculationEnable = true;
  static const bool isGumletEnable = false;
  static const bool isRewardWalletEnable = false;
  static const bool isPostEnable = false;
  static const int noInternetErrorCode = 1000;
  static const String cloudinaryFolder = 'ShopAR/post/image';
  static const String cloudinaryVideoFolder = 'video/folder/';
  static const String cloudinaryImageFolder = 'image/folder/';
  static const String cloudinaryThumbnailFolder = 'thumbnail/folder/';

  static const bool isCompressionEnable = true;
  static const bool isMultipleMediaSelectionEnabled = false;

  static const List<String> restrictedWords = [
    'null',
    'none',
    'nan',
    'undefined',
    'void',
    'missing',
    '',
    '   ',
    'empty',
    'blank',
    'default',
    'temp',
    'temporary',
    'placeholder',
    'example',
    'sample',
    'test',
    'n/a',
    'not available',
    'unknown',
    'unspecified',
    'no value',
    '0',
    '-1',
    '99999',
    '.',
    ',',
    '-',
    '_',
    '*',
    '#',
    '@',
    '!',
    '?',
    'false',
    'true',
    'none found',
    'not specified',
    'nullified',
    'nul',
    'non',
    'na',
    'n a',
    'not-applicable',
    '0.0',
    '...',
    '---',
    '___'
  ];

  static const String tenantId = 'tenant_001';
  static const String projectId = 'project_001';

  static String bucketName = 'trulyfree-staging';
}

abstract class AppUrl {
  static const String appBaseUrl = 'https://api.trulyfreehome.dev';
  static const String socialBaseUrl = 'https://social-apis.dev.trulyfree.com';
  static const String gumletUrl = 'https://cdn.trulyfreehome.dev';
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

abstract class SocialPostType {
  static const String video = 'video';
  static const String image = 'image';
  static const String carousel = 'carousel';
  static const String text = 'text';
  static const String product = 'product';
  static const String audio = 'audio';
}
