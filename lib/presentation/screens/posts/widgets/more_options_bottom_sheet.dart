import 'package:flutter/material.dart';
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
                const Divider(height: 1),
                _buildOption(
                  title: IsrTranslationFile.postInsight,
                  onTap: () async {
                    Navigator.pop(context, true);
                    await widget.onShowPostInsight?.call();
                  },
                ),
                const Divider(height: 1),
                _buildOption(
                  title: IsrTranslationFile.delete,
                  onTap: () async {
                    Navigator.pop(context, true);
                    await widget.onDeletePost?.call();
                  },
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
