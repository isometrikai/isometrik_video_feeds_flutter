import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/ism_video_reel_player.dart' as isr;

/// Example host wiring for [isr.CreateEditPostCallBackConfig.onBackgroundPostOperation].
///
/// Drives a top banner from SDK callbacks (upload %, posting, processing, success, failure + retry).
class BackgroundPostUploadDemo {
  BackgroundPostUploadDemo._();

  static final ValueNotifier<isr.BackgroundPostOperationUpdate?> lastUpdate =
      ValueNotifier<isr.BackgroundPostOperationUpdate?>(null);

  static void onSdkUpdate(isr.BackgroundPostOperationUpdate u) {
    lastUpdate.value = u;
    if (u.phase == isr.BackgroundPostOperationPhase.success) {
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (lastUpdate.value == u) {
          lastUpdate.value = null;
        }
      });
    }
  }

  static void dismiss() {
    lastUpdate.value = null;
  }
}

/// Top-of-screen banner for the example app (overlay-style feedback).
class BackgroundPostUploadBanner extends StatelessWidget {
  const BackgroundPostUploadBanner({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<isr.BackgroundPostOperationUpdate?>(
        valueListenable: BackgroundPostUploadDemo.lastUpdate,
        builder: (context, update, _) {
          if (update == null) return const SizedBox.shrink();
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          Color bg;
          switch (update.phase) {
            case isr.BackgroundPostOperationPhase.failure:
              bg = colorScheme.errorContainer;
              break;
            case isr.BackgroundPostOperationPhase.success:
              bg = const Color(0xFFE8F5E9);
              break;
            default:
              bg = colorScheme.surfaceContainerHighest;
          }
          return Material(
            color: bg,
            elevation: 2,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _headline(update),
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (update.subtitle != null && update.subtitle!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                update.subtitle!,
                                style: theme.textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (update.phase == isr.BackgroundPostOperationPhase.uploading &&
                              !update.isUploadError) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (update.overallProgressPercent / 100).clamp(0, 1),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${update.overallProgressPercent.toStringAsFixed(0)}% · '
                              '${update.currentFileIndex}/${update.totalFiles}',
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                          if (update.phase == isr.BackgroundPostOperationPhase.failure &&
                              update.retry != null) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: update.retry,
                              child: const Text('Retry'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: BackgroundPostUploadDemo.dismiss,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  static String _headline(isr.BackgroundPostOperationUpdate u) {
    switch (u.phase) {
      case isr.BackgroundPostOperationPhase.uploading:
        return u.title ?? 'Uploading';
      case isr.BackgroundPostOperationPhase.creatingPost:
        return u.title ?? 'Saving post';
      case isr.BackgroundPostOperationPhase.processingMedia:
        return u.title ?? 'Processing media';
      case isr.BackgroundPostOperationPhase.success:
        return u.successTitle ?? u.successMessage ?? 'Posted';
      case isr.BackgroundPostOperationPhase.failure:
        return u.failureMessage ?? 'Something went wrong';
    }
  }
}
