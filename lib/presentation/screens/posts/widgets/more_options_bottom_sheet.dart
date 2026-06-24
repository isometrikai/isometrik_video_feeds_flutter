import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/res/res.dart';

abstract final class MoreOptionsSheetResult {
  static const String dubWithAudio = 'dub_with_audio';
  static const String report = 'report';
  static const String edit = 'edit';
  static const String delete = 'delete';
  static const String insight = 'insight';
  static const String removeMeFromPost = 'remove_me_from_post';
  static const String download = 'download';
}

class MoreOptionsBottomSheet extends StatefulWidget {
  const MoreOptionsBottomSheet({
    super.key,
    this.onReportPost,
    this.showDubWithAudio = false,
    this.onDeletePost,
    this.onEditPost,
    this.onShowPostInsight,
    this.isSelfProfile = false,
    this.showRemoveMeFromPost = false,
    this.showDownload = false,
  });

  final Future<void> Function()? onReportPost;
  final bool showDubWithAudio;
  final Future<void> Function()? onDeletePost;
  final Future<void> Function()? onEditPost;
  final Future<void> Function()? onShowPostInsight;
  final bool isSelfProfile;
  final bool showRemoveMeFromPost;
  final bool showDownload;

  @override
  State<MoreOptionsBottomSheet> createState() => _MoreOptionsBottomSheetState();
}

class _MoreOptionsBottomSheetState extends State<MoreOptionsBottomSheet> {
  Color get _backgroundColor =>
      IsrVideoReelConfig
          .socialConfig.colorsConfig?.bottomSheetBackgroundColor ??
      IsrColors.white;

  Color get _textColor => IsrColors.primaryTextColor;

  Color get _deleteTextColor => IsrColors.error;

  Color get _dividerColor => IsrColors.dividerColor;

  @override
  Widget build(BuildContext context) => Material(
        color: _backgroundColor,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isSelfProfile) ...[
                if (widget.showDubWithAudio) ...[
                  _buildOption(
                    title: IsrTranslationFile.dubWithAudio,
                    onTap: () => Navigator.pop(
                      context,
                      MoreOptionsSheetResult.dubWithAudio,
                    ),
                  ),
                  Divider(height: 1, color: _dividerColor),
                ],
                if (widget.showRemoveMeFromPost) ...[
                  _buildOption(
                    title: IsrTranslationFile.removeMeFromPost,
                    onTap: () => Navigator.pop(
                      context,
                      MoreOptionsSheetResult.removeMeFromPost,
                    ),
                  ),
                  Divider(height: 1, color: _dividerColor),
                ],
                if (widget.showDownload) ...[
                  _buildOption(
                    title: IsrTranslationFile.download,
                    onTap: () => Navigator.pop(
                      context,
                      MoreOptionsSheetResult.download,
                    ),
                  ),
                  Divider(height: 1, color: _dividerColor),
                ],
                _buildOption(
                  title: IsrTranslationFile.report,
                  onTap: () => Navigator.pop(
                    context,
                    MoreOptionsSheetResult.report,
                  ),
                ),
              ] else ...[
                _buildOption(
                  title: IsrTranslationFile.edit,
                  onTap: () => Navigator.pop(
                    context,
                    MoreOptionsSheetResult.edit,
                  ),
                ),
                Divider(height: 1, color: _dividerColor),
                _buildOption(
                  title: IsrTranslationFile.postInsight,
                  onTap: () => Navigator.pop(
                    context,
                    MoreOptionsSheetResult.insight,
                  ),
                ),
                Divider(height: 1, color: _dividerColor),
                if (widget.showDownload) ...[
                  _buildOption(
                    title: IsrTranslationFile.download,
                    onTap: () => Navigator.pop(
                      context,
                      MoreOptionsSheetResult.download,
                    ),
                  ),
                  Divider(height: 1, color: _dividerColor),
                ],
                _buildOption(
                  title: IsrTranslationFile.delete,
                  textColor: _deleteTextColor,
                  onTap: () => Navigator.pop(
                    context,
                    MoreOptionsSheetResult.delete,
                  ),
                ),
              ],
              Divider(height: 1, color: _dividerColor),
              _buildOption(
                title: IsrTranslationFile.cancel,
                textColor: _textColor,
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
      Material(
        color: _backgroundColor,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: IsrStyles.primaryText16.copyWith(
                  fontWeight: FontWeight.w500,
                  color: textColor ?? _textColor,
                ),
              ),
            ),
          ),
        ),
      );
}
