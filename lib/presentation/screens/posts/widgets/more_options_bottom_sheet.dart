import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/res/res.dart';

abstract final class MoreOptionsSheetResult {
  static const String dubWithAudio = 'dub_with_audio';
  static const String report = 'report';
  static const String edit = 'edit';
  static const String delete = 'delete';
  static const String insight = 'insight';
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
  });

  final Future<void> Function()? onReportPost;
  final bool showDubWithAudio;
  final Future<void> Function()? onDeletePost;
  final Future<void> Function()? onEditPost;
  final Future<void> Function()? onShowPostInsight;
  final bool isSelfProfile;

  @override
  State<MoreOptionsBottomSheet> createState() => _MoreOptionsBottomSheetState();
}

class _MoreOptionsBottomSheetState extends State<MoreOptionsBottomSheet> {
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
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
                  const Divider(height: 1),
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
                const Divider(height: 1),
                _buildOption(
                  title: IsrTranslationFile.postInsight,
                  onTap: () => Navigator.pop(
                    context,
                    MoreOptionsSheetResult.insight,
                  ),
                ),
                const Divider(height: 1),
                _buildOption(
                  title: IsrTranslationFile.delete,
                  onTap: () => Navigator.pop(
                    context,
                    MoreOptionsSheetResult.delete,
                  ),
                )
              ],

              const Divider(height: 1),

              /// Cancel
              _buildOption(
                title: IsrTranslationFile.cancel,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );

  Widget _buildOption({
    required String title,
    required VoidCallback onTap,
  }) =>
      ListTile(
        titleAlignment: ListTileTitleAlignment.center,
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: IsrStyles.primaryText16.copyWith(
            fontWeight: FontWeight.w500,
            color: IsrColors.black,
          ),
        ),
        onTap: onTap,
      );
}
