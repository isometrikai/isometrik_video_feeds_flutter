import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/res/res.dart';

class MoreOptionsBottomSheet extends StatefulWidget {
  const MoreOptionsBottomSheet({
    super.key,
    this.onReportPost,
    this.onDeletePost,
    this.onEditPost,
    this.onShowPostInsight,
    this.isSelfProfile = false,
  });

  final Future<void> Function()? onReportPost;
  final Future<void> Function()? onDeletePost;
  final Future<void> Function()? onEditPost;
  final Future<void> Function()? onShowPostInsight;
  final bool isSelfProfile;

  @override
  State<MoreOptionsBottomSheet> createState() => _MoreOptionsBottomSheetState();
}

class _MoreOptionsBottomSheetState extends State<MoreOptionsBottomSheet> {
  Color get _backgroundColor =>
      IsrVideoReelConfig.socialConfig.colorsConfig?.bottomSheetBackgroundColor ??
      IsrColors.white;

  Color get _textColor => IsrColors.primaryTextColor;

  Color get _secondaryTextColor => IsrColors.secondaryTextColor;

  Color get _deleteTextColor => IsrColors.error;

  Color get _dividerColor => IsrColors.dividerColor;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isSelfProfile) ...[
                _buildOption(
                  title: IsrTranslationFile.report,
                  onTap: () async {
                    Navigator.pop(context, true);
                    await widget.onReportPost?.call();
                  },
                ),
              ] else ...[
                _buildOption(
                  title: IsrTranslationFile.edit,
                  onTap: () async {
                    Navigator.pop(context, true);
                    await widget.onEditPost?.call();
                  },
                ),
                Divider(height: 1, color: _dividerColor),
                _buildOption(
                  title: IsrTranslationFile.postInsight,
                  onTap: () async {
                    Navigator.pop(context, true);
                    await widget.onShowPostInsight?.call();
                  },
                ),
                Divider(height: 1, color: _dividerColor),
                _buildOption(
                  title: IsrTranslationFile.delete,
                  textColor: _deleteTextColor,
                  onTap: () async {
                    Navigator.pop(context, true);
                    await widget.onDeletePost?.call();
                  },
                ),
              ],
              Divider(height: 1, color: _dividerColor),
              _buildOption(
                title: IsrTranslationFile.cancel,
                textColor: _secondaryTextColor,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );

  Widget _buildOption({
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) =>
      ListTile(
        titleAlignment: ListTileTitleAlignment.center,
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: IsrStyles.primaryText16.copyWith(
            fontWeight: FontWeight.w500,
            color: textColor ?? _textColor,
          ),
        ),
        onTap: onTap,
      );
}
