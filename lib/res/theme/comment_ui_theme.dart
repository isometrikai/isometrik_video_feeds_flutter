import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// Builds [CommentUIConfig] from [IsrVideoReelConfig.socialConfig] so host apps
/// only need to pass brightness + colors once via [ThemeConfig] / [ColorsConfig].
abstract final class CommentUiTheme {
  static bool get isDark =>
      IsrVideoReelConfig.socialConfig.themeConfig?.brightness ==
      Brightness.dark;

  static String get _fontFamily =>
      IsrVideoReelConfig.socialConfig.fontConfig?.primaryFontFamily ??
      AppConstants.primaryFontFamily;

  static double _size(double fallback, double? configured) =>
      configured ?? fallback;

  static TextStyle _text({
    required double size,
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: size,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );

  /// Theme-aware comment sheet UI. Pass [belowCommentsConfig] for reel-overlay
  /// inline comments (typically white text on video).
  static CommentUIConfig build({
    BelowCommentsConfig? belowCommentsConfig,
    Color? bottomSheetBackgroundColor,
    double borderRadius = 12,
    double dialogPadding = 24,
  }) {
    final sizes = IsrVideoReelConfig.socialConfig.textSizeConfig;
    final primary = IsrColors.primaryTextColor;
    final secondary = IsrColors.secondaryTextColor;
    final sheetBg =
        bottomSheetBackgroundColor ??
        IsrColors.dialogColor;
    final primaryBrand = IsrColors.appColor;
    final onPrimary = IsrColors.buttonTextColor;
    final error = IsrColors.error;
    final dark = isDark;

    final inputFill = dark
        ? primary.withValues(alpha: 0.08)
        : const Color(0xFFF5F5F5);
    final inputBorder = dark
        ? secondary.withValues(alpha: 0.35)
        : const Color(0xFFDBDBDB);
    final avatarBackground = IsrColors.profileInitialsBackground;
    final avatarForeground = IsrColors.profileInitialsForeground;

    return CommentUIConfig(
      bottomSheetConfig: BottomSheetConfig(
        backgroundColor: sheetBg,
      ),
      headerConfig: CommentHeaderConfig(
        titleStyle: _text(
          size: _size(16, sizes?.textSize16),
          color: primary,
          fontWeight: FontWeight.w700,
        ),
        dragHandleColor: secondary.withValues(alpha: dark ? 0.45 : 0.25),
      ),
      commentItemConfig: CommentItemConfig(
        usernameStyle: _text(
          size: 13,
          color: primary,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
        commentTextStyle: _text(
          size: 16,
          color: primary,
          height: 1.25,
        ),
        timestampStyle: _text(
          size: 13,
          color: secondary,
          height: 1.1,
        ),
        replyButtonStyle: _text(
          size: _size(12, sizes?.textSize12),
          color: secondary,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        likeCountStyle: _text(
          size: _size(12, sizes?.textSize12),
          color: secondary,
          height: 1.1,
        ),
        viewRepliesStyle: _text(
          size: 13,
          color: secondary,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        hideRepliesStyle: _text(
          size: 13,
          color: secondary,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        moreIconColor: primary,
        avatarBackgroundColor: avatarBackground,
        avatarForegroundColor: avatarForeground,
      ),
      belowCommentsConfig: belowCommentsConfig,
      replyFieldConfig: ReplyFieldConfig(
        inputBackgroundColor: inputFill,
        inputBorderColor: inputBorder,
        hintTextStyle: _text(
          size: _size(14, sizes?.textSize14),
          color: secondary,
        ),
        inputTextStyle: _text(
          size: _size(14, sizes?.textSize14),
          color: primary,
        ),
        replyingToBackgroundColor: dark
            ? primary.withValues(alpha: 0.06)
            : const Color(0xFFEFEFEF),
        replyingToTextStyle: _text(
          size: _size(12, sizes?.textSize12),
          color: secondary,
        ),
        replyingToNameStyle: _text(
          size: _size(12, sizes?.textSize12),
          color: secondary,
          fontWeight: FontWeight.w600,
        ),
        closeReplyIconColor: secondary,
        sendButtonColor: primaryBrand,
        sendButtonIconColor: onPrimary,
      ),
      placeholderConfig: CommentPlaceholderConfig(
        placeholderIconColor: secondary,
        titleStyle: _text(
          size: _size(16, sizes?.textSize16),
          color: primary,
          fontWeight: FontWeight.w600,
        ),
        subtitleStyle: _text(
          size: _size(14, sizes?.textSize14),
          color: secondary,
        ),
      ),
      moreOptionsConfig: MoreOptionsConfig(
        dialogDecoration: BoxDecoration(
          color: sheetBg,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        dialogPadding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: dialogPadding,
        ),
        optionTextStyle: _text(
          size: _size(14, sizes?.textSize14),
          color: primary,
        ),
        deleteTextStyle: _text(
          size: _size(14, sizes?.textSize14),
          color: error,
        ),
        reportTextStyle: _text(
          size: _size(14, sizes?.textSize14),
          color: primary,
        ),
        cancelTextStyle: _text(
          size: _size(14, sizes?.textSize14),
          color: secondary,
        ),
      ),
    );
  }
}
