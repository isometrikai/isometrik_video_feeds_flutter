import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/utils/enums.dart'
    show ButtonType, LoaderType, MediaType;

/// App-provided loader builder used across SDK screens/dialogs.
///
/// The same callback is reused by:
/// - `AppLoader` (dialog and full-screen loaders)
/// - `Utility.loaderWidget()` (inline loaders in lists/cards/placeholders)
///
/// Returning a widget here lets host apps keep one consistent loading UI
/// without changing SDK internals.
typedef SdkLoaderBuilder = Widget Function(
  BuildContext context, {
  bool isDialog,
  String? message,
  LoaderType? loaderType,
  bool isAdaptive,
});

/// Main configuration class for social features in the SDK.
///
/// This class allows you to customize various aspects of the SDK including:
/// - Theme colors and appearance
/// - Toast messages styling
/// - Dialog appearance and button styles
/// - Text sizes throughout the app
/// - Font families
/// - Color scheme
/// - Global button styles (primary, secondary, tertiary)
///
/// **Usage Example:**
/// ```dart
/// SocialConfig(
///   themeConfig: ThemeConfig(
///     primaryColor: Colors.blue,
///     scaffoldBackgroundColor: Colors.white,
///   ),
///   dialogConfig: DialogConfig(
///     backgroundColor: Colors.white,
///     borderRadius: 12.0,
///   ),
///   primaryButton: ButtonConfig(
///     backgroundColor: Colors.blue,
///     textColor: Colors.white,
///     borderRadius: 8.0,
///   ),
///   secondaryButton: ButtonConfig(
///     backgroundColor: Colors.transparent,
///     textColor: Colors.blue,
///     borderColor: Colors.blue,
///     borderWidth: 1.0,
///   ),
///   toastConfig: ToastConfig(
///     backgroundColor: Colors.black87,
///     textColor: Colors.white,
///     gravity: ToastGravityType.bottom,
///   ),
///   textSizeConfig: TextSizeConfig(
///     textSize14: 14.0,
///     textSize16: 16.0,
///   ),
///   fontConfig: FontConfig(
///     primaryFontFamily: 'Roboto',
///   ),
///   colorsConfig: ColorsConfig(
///     primaryTextColor: Colors.black87,
///     errorColor: Colors.red,
///   ),
/// )
/// ```
///
/// All configuration properties are optional. If not provided, the SDK will use
/// default values defined in the res/theme files.
///
/// **Button Configuration:**
/// - [primaryButton] - Applied to all `ButtonType.primary` buttons throughout the SDK
/// - [secondaryButton] - Applied to all `ButtonType.secondary` buttons throughout the SDK
/// - [tertiaryButton] - Applied to all `ButtonType.tertiary` buttons throughout the SDK
///
/// These button configs are used in:
/// - `AppButton` widget (all instances)
/// - Dialog buttons
/// - Bottom sheet buttons
/// - Any other buttons using `ButtonType` enum
class SocialConfig {
  const SocialConfig({
    this.socialCallBackConfig,
    this.loaderBuilder,
    this.themeConfig,
    this.toastConfig,
    this.dialogConfig,
    this.textSizeConfig,
    this.fontConfig,
    this.colorsConfig,
    this.primaryButton,
    this.secondaryButton,
    this.tertiaryButton,
    this.googleCloudUpload,
  });

  final SocialCallBackConfig? socialCallBackConfig;

  /// App-side loader builder reused across the complete SDK.
  ///
  /// If provided, the SDK uses this loader for both dialog-level and inline
  /// loading states. If omitted, SDK falls back to default `AppLoader` /
  /// `CircularProgressIndicator` behavior.
  final SdkLoaderBuilder? loaderBuilder;
  final ThemeConfig? themeConfig;
  final ToastConfig? toastConfig;
  final DialogConfig? dialogConfig;
  final TextSizeConfig? textSizeConfig;
  final FontConfig? fontConfig;
  final ColorsConfig? colorsConfig;

  /// Configuration for primary buttons throughout the SDK.
  ///
  /// Applied to all buttons with `ButtonType.primary` including:
  /// - Dialog primary action buttons (OK, Delete, Report, Post, etc.)
  /// - All `AppButton` widgets with `type: ButtonType.primary`
  /// - Any other primary action buttons
  ///
  /// See [ButtonConfig] for available properties.
  /// Falls back to theme defaults if not provided.
  final ButtonConfig? primaryButton;

  /// Configuration for secondary buttons throughout the SDK.
  ///
  /// Applied to all buttons with `ButtonType.secondary` including:
  /// - Dialog cancel/negative action buttons
  /// - All `AppButton` widgets with `type: ButtonType.secondary`
  /// - Any other secondary action buttons
  ///
  /// See [ButtonConfig] for available properties.
  /// Falls back to theme defaults if not provided.
  final ButtonConfig? secondaryButton;

  /// Configuration for tertiary buttons throughout the SDK.
  ///
  /// Applied to all buttons with `ButtonType.tertiary` including:
  /// - All `AppButton` widgets with `type: ButtonType.tertiary`
  /// - Any other tertiary action buttons
  ///
  /// See [ButtonConfig] for available properties.
  /// Falls back to theme defaults if not provided.
  final ButtonConfig? tertiaryButton;

  /// Google Cloud Storage upload settings (service account JSON path and bucket).
  final GoogleCloudUpload? googleCloudUpload;

  SocialConfig copyWith({
    SocialCallBackConfig? socialCallBackConfig,
    SdkLoaderBuilder? loaderBuilder,
    ThemeConfig? themeConfig,
    ToastConfig? toastConfig,
    DialogConfig? dialogConfig,
    TextSizeConfig? textSizeConfig,
    FontConfig? fontConfig,
    ColorsConfig? colorsConfig,
    ButtonConfig? primaryButton,
    ButtonConfig? secondaryButton,
    ButtonConfig? tertiaryButton,
    GoogleCloudUpload? googleCloudUpload,
  }) =>
      SocialConfig(
        socialCallBackConfig: socialCallBackConfig ?? this.socialCallBackConfig,
        loaderBuilder: loaderBuilder ?? this.loaderBuilder,
        themeConfig: themeConfig ?? this.themeConfig,
        toastConfig: toastConfig ?? this.toastConfig,
        dialogConfig: dialogConfig ?? this.dialogConfig,
        textSizeConfig: textSizeConfig ?? this.textSizeConfig,
        fontConfig: fontConfig ?? this.fontConfig,
        colorsConfig: colorsConfig ?? this.colorsConfig,
        primaryButton: primaryButton ?? this.primaryButton,
        secondaryButton: secondaryButton ?? this.secondaryButton,
        tertiaryButton: tertiaryButton ?? this.tertiaryButton,
        googleCloudUpload: googleCloudUpload ?? this.googleCloudUpload,
      );
}

/// Configuration for social-related callbacks.
///
/// This class allows you to provide custom callback functions that the SDK
/// will invoke at specific points in the social flow.
///
/// **Usage Example:**
/// ```dart
/// SocialCallBackConfig(
///   onLoginInvoked: () async {
///     // Handle login logic
///     final success = await performLogin();
///     return success;
///   },
///   uploadMediaToCloud: (file, fileName, mediaType, onProgress, folderName, ext) async {
///     return await myUploader.upload(...);
///   },
///   convertToGumletUrl: (mediaUrl) { /* return Gumlet URL if enabled */ return mediaUrl; },
/// )
/// ```
class SocialCallBackConfig {
  const SocialCallBackConfig({
    this.onLoginInvoked,
    this.uploadMediaToCloud,
    this.convertToGumletUrl,
    this.placeHolderGenerator,
  });

  /// Callback invoked when login is required.
  /// Should return `true` if login was successful, `false` otherwise.
  final Future<bool> Function()? onLoginInvoked;

  /// Host app upload: use your own cloud storage / CDN instead of the SDK default uploader.
  ///
  /// Return the final public URL for the uploaded file, or an empty string on failure.
  /// The progress callback argument expects values in **0–100** (same as the default uploader).
  final Future<String> Function(
    File? file,
    String fileName,
    MediaType? mediaType,
    void Function(double) progressCallBackFunction,
    String folderName,
    String fileExtension,
  )? uploadMediaToCloud;

  /// When Gumlet (or similar) is enabled in the host project, map a raw media URL to the
  /// optimized Gumlet URL. If omitted, SDK uses the URL returned from upload as-is.
  final String Function(String mediaUrl)? convertToGumletUrl;

  /// to generate your own placeholders.
  final Widget? Function(double? height, double? width)? placeHolderGenerator;
  SocialCallBackConfig copyWith({
    Future<bool> Function()? onLoginInvoked,
    Future<String> Function(
      File? file,
      String fileName,
      MediaType? mediaType,
      void Function(double) progressCallBackFunction,
      String folderName,
      String fileExtension,
    )? uploadMediaToCloud,
    String Function(String mediaUrl)? convertToGumletUrl,
    Widget? Function(double? height, double? width)? placeHolderGenerator,
  }) =>
      SocialCallBackConfig(
        onLoginInvoked: onLoginInvoked ?? this.onLoginInvoked,
        uploadMediaToCloud: uploadMediaToCloud ?? this.uploadMediaToCloud,
        convertToGumletUrl: convertToGumletUrl ?? this.convertToGumletUrl,
        placeHolderGenerator:
            placeHolderGenerator ?? this.placeHolderGenerator,
      );
}

/// Google Cloud Storage upload configuration.
///
/// Provide the filesystem path to your service account JSON key file and the
/// target GCS bucket name.
class GoogleCloudUpload {
  const GoogleCloudUpload({
    required this.credentialsJsonPath,
    required this.bucketName,
  });

  /// Path to the Google Cloud service account credentials JSON file.
  final String credentialsJsonPath;

  /// GCS bucket name for uploads.
  final String bucketName;

  GoogleCloudUpload copyWith({
    String? credentialsJsonPath,
    String? bucketName,
  }) =>
      GoogleCloudUpload(
        credentialsJsonPath: credentialsJsonPath ?? this.credentialsJsonPath,
        bucketName: bucketName ?? this.bucketName,
      );
}

/// Configuration for app theme and colors.
///
/// This config allows you to customize the overall theme of the SDK,
/// including primary colors, background colors, and brightness.
///
/// **Usage Example:**
/// ```dart
/// ThemeConfig(
///   primaryColor: Color(0xFF006CD8),      // Main brand color
///   secondaryColor: Color(0xFF851E91),    // Secondary brand color
///   scaffoldBackgroundColor: Colors.white, // Background color
///   appBarColor: Colors.white,             // App bar background
///   brightness: Brightness.light,          // Light or dark theme
///   splashColor: Color(0xFF006CD8).withOpacity(0.5), // Splash effect color
/// )
/// ```
///
/// These values are used throughout the SDK in:
/// - AppBar themes
/// - Button default colors
/// - Scaffold backgrounds
/// - Theme data generation
class ThemeConfig {
  const ThemeConfig({
    this.primaryColor,
    this.secondaryColor,
    this.scaffoldBackgroundColor,
    this.appBarColor,
    this.brightness,
    this.splashColor,
  });

  /// Primary brand color used for buttons, accents, and primary actions.
  /// Falls back to `IsrColors.appColor` if not provided.
  final Color? primaryColor;

  /// Secondary brand color for secondary actions and accents.
  /// Falls back to `IsrColors.secondaryColor` if not provided.
  final Color? secondaryColor;

  /// Background color for scaffold/screen backgrounds.
  /// Falls back to `IsrColors.scaffoldColor` if not provided.
  final Color? scaffoldBackgroundColor;

  /// Background color for app bars.
  /// Falls back to `IsrColors.appBarColor` if not provided.
  final Color? appBarColor;

  /// Theme brightness (light or dark mode).
  /// Falls back to `Brightness.light` if not provided.
  final Brightness? brightness;

  /// Color used for splash/ripple effects.
  /// Falls back to primaryColor with 50% opacity if not provided.
  final Color? splashColor;

  ThemeConfig copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? scaffoldBackgroundColor,
    Color? appBarColor,
    Brightness? brightness,
    Color? splashColor,
  }) =>
      ThemeConfig(
        primaryColor: primaryColor ?? this.primaryColor,
        secondaryColor: secondaryColor ?? this.secondaryColor,
        scaffoldBackgroundColor:
            scaffoldBackgroundColor ?? this.scaffoldBackgroundColor,
        appBarColor: appBarColor ?? this.appBarColor,
        brightness: brightness ?? this.brightness,
        splashColor: splashColor ?? this.splashColor,
      );
}

/// Configuration for toast message appearance and behavior.
///
/// Toast messages are used throughout the SDK to show brief notifications
/// to users (e.g., success messages, error messages).
///
/// **Usage Example:**
/// ```dart
/// ToastConfig(
///   backgroundColor: Colors.black87,      // Toast background
///   textColor: Colors.white,               // Toast text color
///   gravity: ToastGravityType.bottom,       // Position on screen
///   duration: Duration(seconds: 3),        // How long to show
/// )
/// ```
///
/// This config is used in `Utility.showToastMessage()` which is called
/// throughout the SDK for various notifications.
class ToastConfig {
  const ToastConfig({
    this.backgroundColor,
    this.textColor,
    this.gravity,
    this.duration,
  });

  /// Background color of the toast message.
  /// Falls back to `IsrColors.black` if not provided.
  final Color? backgroundColor;

  /// Text color of the toast message.
  /// Falls back to `IsrColors.white` if not provided.
  final Color? textColor;

  /// Position where the toast appears on screen.
  /// - `ToastGravityType.top`: Top of screen
  /// - `ToastGravityType.bottom`: Bottom of screen (default)
  /// - `ToastGravityType.center`: Center of screen
  /// Falls back to `ToastGravityType.bottom` if not provided.
  final ToastGravityType? gravity;

  /// How long the toast message is displayed.
  /// If duration >= 3 seconds, uses `Toast.LENGTH_LONG`, otherwise `Toast.LENGTH_SHORT`.
  /// Falls back to `Toast.LENGTH_SHORT` if not provided.
  final Duration? duration;

  ToastConfig copyWith({
    Color? backgroundColor,
    Color? textColor,
    ToastGravityType? gravity,
    Duration? duration,
  }) =>
      ToastConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        textColor: textColor ?? this.textColor,
        gravity: gravity ?? this.gravity,
        duration: duration ?? this.duration,
      );
}

/// Enum for toast message position on screen.
///
/// Used with [ToastConfig.gravity] to specify where toast messages appear.
enum ToastGravityType {
  /// Toast appears at the top of the screen
  top,

  /// Toast appears at the bottom of the screen (default)
  bottom,

  /// Toast appears in the center of the screen
  center,
}

/// Configuration for dialog appearance and button styles.
///
/// This config allows you to customize all dialogs in the SDK including:
/// - Alert dialogs
/// - Confirmation dialogs (delete, report, etc.)
/// - Custom dialogs
/// - Button styles within dialogs
///
/// **Usage Example:**
/// ```dart
/// DialogConfig(
///   backgroundColor: Colors.white,                    // Dialog background
///   borderRadius: 12.0,                               // Rounded corners
///   padding: EdgeInsets.all(24),                      // Internal padding
///   titleTextStyle: TextStyle(                        // Title text style
///     fontSize: 18,
///     fontWeight: FontWeight.bold,
///   ),
///   messageTextStyle: TextStyle(                      // Message text style
///     fontSize: 14,
///     color: Colors.grey[700],
///   ),
///   primaryButton: ButtonConfig(                      // Primary action button
///     backgroundColor: Colors.blue,
///     textColor: Colors.white,
///     borderRadius: 8.0,
///   ),
///   secondaryButton: ButtonConfig(                    // Secondary action button
///     backgroundColor: Colors.grey[100],
///     textColor: Colors.blue,
///     borderColor: Colors.blue,
///     borderWidth: 1.0,
///   ),
/// )
/// ```
///
/// This config is automatically applied to:
/// - `Utility.showAppDialog()` - General alert dialogs
/// - `Utility.showCustomDialog()` - Custom widget dialogs
/// - Delete post dialogs
/// - Report dialogs
/// - Post now confirmation dialogs
/// - All other dialogs using `showDialog()`
class DialogConfig {
  const DialogConfig({
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.titleTextStyle,
    this.messageTextStyle,
    this.buttonTextStyle,
  });

  /// Background color of the dialog.
  /// Falls back to `IsrColors.dialogColor` or `Colors.white` if not provided.
  final Color? backgroundColor;

  /// Border radius for rounded corners of the dialog.
  /// Falls back to `12.0` or `IsrDimens.twelve` if not provided.
  final double? borderRadius;

  /// Internal padding of the dialog content.
  /// Falls back to `EdgeInsets.all(14)` or `EdgeInsets.symmetric(horizontal: 24, vertical: 28)` if not provided.
  final EdgeInsets? padding;

  /// Text style for dialog titles (e.g., "Alert", "Delete Post", "Report").
  /// Falls back to `IsrStyles.secondaryText14.copyWith(fontWeight: FontWeight.w700)` if not provided.
  final TextStyle? titleTextStyle;

  /// Text style for dialog messages/body text.
  /// Falls back to `IsrStyles.primaryText14` if not provided.
  final TextStyle? messageTextStyle;

  /// Default text style for buttons in dialogs (if button-specific config not provided).
  /// Falls back to default button text styles if not provided.
  final TextStyle? buttonTextStyle;

  DialogConfig copyWith({
    Color? backgroundColor,
    double? borderRadius,
    EdgeInsets? padding,
    TextStyle? titleTextStyle,
    TextStyle? messageTextStyle,
    TextStyle? buttonTextStyle,
  }) =>
      DialogConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        borderRadius: borderRadius ?? this.borderRadius,
        padding: padding ?? this.padding,
        titleTextStyle: titleTextStyle ?? this.titleTextStyle,
        messageTextStyle: messageTextStyle ?? this.messageTextStyle,
        buttonTextStyle: buttonTextStyle ?? this.buttonTextStyle,
      );
}

/// Configuration for button appearance and styling.
///
/// This config allows you to customize button styles used throughout the SDK.
/// It supports all button types: primary, secondary, and tertiary.
///
/// **Note:** Button configs are defined at the [SocialConfig] level (not in [DialogConfig])
/// and applied globally to all buttons based on their [ButtonType]. This ensures consistent
/// button styling across the entire SDK, including:
/// - All `AppButton` widgets
/// - Dialog buttons
/// - Bottom sheet buttons
/// - Any other buttons using `ButtonType` enum
///
/// **Usage Example:**
/// ```dart
/// ButtonConfig(
///   backgroundColor: Colors.blue,      // Button background color
///   textColor: Colors.white,            // Button text color
///   borderColor: Colors.blue,          // Stroke/border color
///   borderRadius: 8.0,                  // Corner radius
///   elevation: 2.0,                     // Shadow elevation
/// )
/// ```
///
/// All properties are optional. If not provided, buttons will use default
/// styles from the SDK or fallback to theme defaults.
class ButtonConfig {
  const ButtonConfig({
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderRadius,
    this.elevation,
  });

  /// Background color of the button.
  /// Falls back to theme primary color or default if not provided.
  final Color? backgroundColor;

  /// Text color of the button.
  /// Falls back to white for primary buttons, theme color for secondary if not provided.
  final Color? textColor;

  /// Stroke/border color of the button.
  /// Used for outlined/secondary button styles.
  /// Falls back to theme primary color or transparent if not provided.
  final Color? borderColor;

  /// Border radius for rounded button corners.
  /// Falls back to `8.0` or `IsrDimens.eight` if not provided.
  final double? borderRadius;

  /// Elevation/shadow depth of the button.
  /// Higher values create more pronounced shadows.
  final double? elevation;

  ButtonConfig copyWith({
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
    double? borderRadius,
    double? elevation,
  }) =>
      ButtonConfig(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        textColor: textColor ?? this.textColor,
        borderColor: borderColor ?? this.borderColor,
        borderRadius: borderRadius ?? this.borderRadius,
        elevation: elevation ?? this.elevation,
      );
}

/// Configuration for text sizes throughout the SDK.
///
/// This config allows you to customize font sizes used in text styles.
/// All sizes are applied with responsive scaling (.sp) for different screen sizes.
///
/// **Usage Example:**
/// ```dart
/// TextSizeConfig(
///   textSize8: 8.0,    // Very small text
///   textSize10: 10.0,   // Small text
///   textSize12: 12.0,   // Small-medium text
///   textSize14: 14.0,   // Medium text (most common)
///   textSize16: 16.0,   // Medium-large text
///   textSize18: 18.0,   // Large text
///   textSize20: 20.0,   // Extra large text
///   textSize22: 22.0,   // Headline text
///   textSize24: 24.0,   // Large headline text
/// )
/// ```
///
/// These sizes are used in:
/// - `IsrStyles.primaryText*` - Primary text styles
/// - `IsrStyles.secondaryText*` - Secondary text styles
/// - `IsrStyles.white*` - White text styles
/// - Button text styles
/// - Dialog text styles
///
/// All sizes are optional. If not provided, defaults from `IsrDimens` are used.
/// Sizes are automatically scaled using ScreenUtil for responsive design.
class TextSizeConfig {
  const TextSizeConfig({
    this.textSize8,
    this.textSize10,
    this.textSize12,
    this.textSize14,
    this.textSize16,
    this.textSize18,
    this.textSize20,
    this.textSize22,
    this.textSize24,
  });

  /// Font size 8 - Very small text (labels, captions).
  /// Falls back to `IsrDimens.eight` if not provided.
  final double? textSize8;

  /// Font size 10 - Small text (small labels, helper text).
  /// Falls back to `IsrDimens.ten` if not provided.
  final double? textSize10;

  /// Font size 12 - Small-medium text (body text, buttons).
  /// Falls back to `IsrDimens.twelve` if not provided.
  final double? textSize12;

  /// Font size 14 - Medium text (most common body text, dialog messages).
  /// Falls back to `IsrDimens.fourteen` if not provided.
  final double? textSize14;

  /// Font size 16 - Medium-large text (subheadings, important text).
  /// Falls back to `IsrDimens.sixteen` if not provided.
  final double? textSize16;

  /// Font size 18 - Large text (headings, dialog titles).
  /// Falls back to `IsrDimens.eighteen` if not provided.
  final double? textSize18;

  /// Font size 20 - Extra large text (large headings).
  /// Falls back to `IsrDimens.twenty` if not provided.
  final double? textSize20;

  /// Font size 22 - Headline text.
  /// Falls back to default if not provided.
  final double? textSize22;

  /// Font size 24 - Large headline text.
  /// Falls back to default if not provided.
  final double? textSize24;

  TextSizeConfig copyWith({
    double? textSize8,
    double? textSize10,
    double? textSize12,
    double? textSize14,
    double? textSize16,
    double? textSize18,
    double? textSize20,
    double? textSize22,
    double? textSize24,
  }) =>
      TextSizeConfig(
        textSize8: textSize8 ?? this.textSize8,
        textSize10: textSize10 ?? this.textSize10,
        textSize12: textSize12 ?? this.textSize12,
        textSize14: textSize14 ?? this.textSize14,
        textSize16: textSize16 ?? this.textSize16,
        textSize18: textSize18 ?? this.textSize18,
        textSize20: textSize20 ?? this.textSize20,
        textSize22: textSize22 ?? this.textSize22,
        textSize24: textSize24 ?? this.textSize24,
      );
}

/// Configuration for font families used throughout the SDK.
///
/// This config allows you to customize the fonts used for all text in the SDK.
/// Make sure the font families are included in your `pubspec.yaml` assets.
///
/// **Usage Example:**
/// ```dart
/// FontConfig(
///   primaryFontFamily: 'Roboto',      // Main font for most text
///   secondaryFontFamily: 'Roboto',    // Secondary font (usually same as primary)
/// )
/// ```
///
/// **Adding Custom Fonts:**
/// 1. Add font files to `assets/fonts/` directory
/// 2. Update `pubspec.yaml`:
/// ```yaml
/// flutter:
///   fonts:
///     - family: Roboto
///       fonts:
///         - asset: assets/fonts/Roboto-Regular.ttf
/// ```
///
/// These fonts are used in:
/// - All text styles (`IsrStyles.*`)
/// - Button text
/// - Dialog text
/// - Theme text styles
///
/// Falls back to `'Inter'` if not provided (default SDK font).
class FontConfig {
  const FontConfig({
    this.primaryFontFamily,
    this.secondaryFontFamily,
  });

  /// Primary font family used for most text throughout the SDK.
  /// This is the main font for body text, buttons, and UI elements.
  /// Falls back to `'Inter'` if not provided.
  ///
  /// **Note:** The font must be declared in your `pubspec.yaml` and included
  /// in your app's assets for it to work.
  final String? primaryFontFamily;

  /// Secondary font family (typically same as primary).
  /// Can be used for special cases or different text styles.
  /// Falls back to `'Inter'` if not provided.
  ///
  /// **Note:** The font must be declared in your `pubspec.yaml` and included
  /// in your app's assets for it to work.
  final String? secondaryFontFamily;

  FontConfig copyWith({
    String? primaryFontFamily,
    String? secondaryFontFamily,
  }) =>
      FontConfig(
        primaryFontFamily: primaryFontFamily ?? this.primaryFontFamily,
        secondaryFontFamily: secondaryFontFamily ?? this.secondaryFontFamily,
      );
}

/// Configuration for color scheme used throughout the SDK.
///
/// This config allows you to customize all colors used in the SDK,
/// providing a consistent color palette across all components.
///
/// **Usage Example:**
/// ```dart
/// ColorsConfig(
///   // Text Colors
///   primaryTextColor: Color(0xFF333333),        // Main text color
///   secondaryTextColor: Color(0xFF505050),      // Secondary text color
///
///   // Button Colors
///   buttonBackgroundColor: Color(0xFF006CD8),   // Default button background
///   buttonDisabledBackgroundColor: Color(0xFF808688), // Disabled button
///   buttonTextColor: Colors.white,              // Button text color
///
///   // UI Colors
///   dialogColor: Colors.white,                  // Dialog background
///   bottomSheetBackgroundColor: Colors.white,   // Bottom sheet background
///   dividerColor: Color(0xFFEFEFEF),            // Divider lines
///
///   // Status Colors
///   errorColor: Color(0xFFE30000),              // Error/delete actions
///   successColor: Color(0xFF00A86B),             // Success messages
///
///   // Base Colors
///   white: Colors.white,                        // White color
///   black: Color(0xFF182028),                   // Black color
///   grey: MaterialColor(0xFF829CB6, {           // Grey shades
///     100: Color(0xFFEBF0F5),
///     300: Color(0xFFD1DBE6),
///     500: Color(0xFF829CB6),
///     700: Color(0xFF627B92),
///     900: Color(0xFF4C6680),
///   }),
/// )
/// ```
///
/// These colors are used throughout the SDK in:
/// - Text styles (`IsrStyles.*`)
/// - Buttons (`AppButton`)
/// - Dialogs (`DialogConfig`)
/// - Bottom sheets
/// - Error/success messages
/// - Dividers and separators
///
/// All colors are optional. If not provided, defaults from `IsrColors` are used.
class ColorsConfig {
  const ColorsConfig({
    this.primaryTextColor,
    this.secondaryTextColor,
    this.buttonBackgroundColor,
    this.buttonDisabledBackgroundColor,
    this.buttonTextColor,
    this.dialogColor,
    this.errorColor,
    this.successColor,
    this.white,
    this.black,
    this.grey,
    this.dividerColor,
    this.bottomSheetBackgroundColor,
  });

  /// Primary text color used for most body text.
  /// Falls back to `IsrColors.primaryTextColor` (Color(0xFF333333)) if not provided.
  final Color? primaryTextColor;

  /// Secondary text color used for less prominent text.
  /// Falls back to `IsrColors.secondaryTextColor` (Color(0xFF505050)) if not provided.
  final Color? secondaryTextColor;

  /// Default background color for buttons.
  /// Falls back to theme primary color or `IsrColors.buttonBackgroundColor` if not provided.
  final Color? buttonBackgroundColor;

  /// Background color for disabled buttons.
  /// Falls back to `IsrColors.buttonDisabledBackgroundColor` (Color(0xFF808688)) if not provided.
  final Color? buttonDisabledBackgroundColor;

  /// Default text color for buttons.
  /// Falls back to `IsrColors.buttonTextColor` (Colors.white) if not provided.
  final Color? buttonTextColor;

  /// Background color for dialogs.
  /// Falls back to `IsrColors.dialogColor` (Colors.white) if not provided.
  final Color? dialogColor;

  /// Color used for error states and destructive actions (e.g., delete buttons).
  /// Falls back to `IsrColors.error` (Color(0xFFE30000)) if not provided.
  final Color? errorColor;

  /// Color used for success states and positive actions.
  /// Falls back to `IsrColors.success` (Color(0xFF00A86B)) if not provided.
  final Color? successColor;

  /// White color used throughout the SDK.
  /// Falls back to `IsrColors.white` (Colors.white) if not provided.
  final Color? white;

  /// Black color used throughout the SDK.
  /// Falls back to `IsrColors.black` (Color(0xFF182028)) if not provided.
  final Color? black;

  /// Material color palette for grey shades.
  /// Used for various grey tones throughout the UI.
  /// Falls back to `IsrColors.grey` if not provided.
  final MaterialColor? grey;

  /// Color used for divider lines and separators.
  /// Falls back to `IsrColors.dividerColor` (Color(0xFFEFEFEF)) if not provided.
  final Color? dividerColor;

  /// Background color for bottom sheets.
  /// Falls back to `IsrColors.white` if not provided.
  final Color? bottomSheetBackgroundColor;

  ColorsConfig copyWith({
    Color? primaryTextColor,
    Color? secondaryTextColor,
    Color? buttonBackgroundColor,
    Color? buttonDisabledBackgroundColor,
    Color? buttonTextColor,
    Color? dialogColor,
    Color? errorColor,
    Color? successColor,
    Color? white,
    Color? black,
    MaterialColor? grey,
    Color? dividerColor,
    Color? bottomSheetBackgroundColor,
  }) =>
      ColorsConfig(
        primaryTextColor: primaryTextColor ?? this.primaryTextColor,
        secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
        buttonBackgroundColor:
            buttonBackgroundColor ?? this.buttonBackgroundColor,
        buttonDisabledBackgroundColor:
            buttonDisabledBackgroundColor ?? this.buttonDisabledBackgroundColor,
        buttonTextColor: buttonTextColor ?? this.buttonTextColor,
        dialogColor: dialogColor ?? this.dialogColor,
        errorColor: errorColor ?? this.errorColor,
        successColor: successColor ?? this.successColor,
        white: white ?? this.white,
        black: black ?? this.black,
        grey: grey ?? this.grey,
        dividerColor: dividerColor ?? this.dividerColor,
        bottomSheetBackgroundColor:
            bottomSheetBackgroundColor ?? this.bottomSheetBackgroundColor,
      );
}
