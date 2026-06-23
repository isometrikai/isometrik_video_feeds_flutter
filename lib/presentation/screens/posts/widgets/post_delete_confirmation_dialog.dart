import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/isr_video_reel_config.dart';
import 'package:ism_video_reel_player/res/res.dart';

/// Figma delete confirmation for moderated posts.
class PostDeleteConfirmationDialog extends StatelessWidget {
  const PostDeleteConfirmationDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PostDeleteConfirmationDialog(),
    );
    return confirmed == true;
  }

  Color get _primaryColor =>
      IsrVideoReelConfig.socialConfig.themeConfig?.primaryColor ??
      IsrColors.appColor;

  @override
  Widget build(BuildContext context) {
    final dialogConfig = IsrVideoReelConfig.socialConfig.dialogConfig;
    final borderRadius = dialogConfig?.borderRadius ?? 16.0;

    return Dialog(
      backgroundColor: dialogConfig?.backgroundColor ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: dialogConfig?.padding ??
            const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    IsrTranslationFile.deleteThisPost,
                    style: dialogConfig?.titleTextStyle ??
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF182028),
                        ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close, color: Color(0xFF182028)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              IsrTranslationFile.deleteThisPostMessage,
              style: dialogConfig?.messageTextStyle ??
                  const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF505050),
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  IsrTranslationFile.confirmDelete,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
