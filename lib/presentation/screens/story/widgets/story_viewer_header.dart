import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utility.dart';

class StoryViewerHeader extends StatelessWidget {
  const StoryViewerHeader({
    super.key,
    required this.group,
    required this.story,
    required this.canManageCurrentStory,
    required this.canReactToStory,
    required this.onClose,
    required this.onMoreActionsPressed,
    this.showAddToHighlight = false,
    this.inHighlightViewer = false,
    this.onAddToHighlightPressed,
    this.onDeleteStoryPressed,
  });

  final StoryGroup? group;
  final StoryData? story;
  final bool canManageCurrentStory;

  /// Viewers who can send reactions (e.g. love) see the same overflow entry point.
  final bool canReactToStory;
  final VoidCallback onClose;
  final VoidCallback onMoreActionsPressed;
  final bool showAddToHighlight;
  final bool inHighlightViewer;
  final VoidCallback? onAddToHighlightPressed;
  final VoidCallback? onDeleteStoryPressed;

  static TextStyle _usernameStyle(BuildContext context) =>
      IsrStyles.primaryText16Bold.copyWith(
        color: Colors.white,
        shadows: const [
          Shadow(
            offset: Offset(0, 1),
            blurRadius: 4,
            color: Color(0x80000000),
          ),
        ],
      );

  static TextStyle _timestampStyle(BuildContext context) =>
      IsrStyles.getTextStyles(
        color: Colors.white.withValues(alpha: 0.75),
        fontSize: IsrDimens.thirteen,
      ).copyWith(
        shadows: const [
          Shadow(
            offset: Offset(0, 1),
            blurRadius: 3,
            color: Color(0x80000000),
          ),
        ],
      );

  static String? _storyTimestamp(StoryData? story) {
    final raw = story?.createdAt.trim() ?? '';
    if (raw.isEmpty) return null;
    try {
      final parsed = DateTime.parse(raw).toLocal();
      return Utility.formatPublishedTimeAgo(parsed);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = group;
    final timestamp = _storyTimestamp(story);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (g != null) ...[
          CircleAvatar(
            radius: IsrDimens.eighteen,
            backgroundImage:
                g.avatarUrl.isNotEmpty ? NetworkImage(g.avatarUrl) : null,
            child: g.avatarUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white54)
                : null,
          ),
          SizedBox(width: IsrDimens.eight),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  g.username.isEmpty ? 'Story' : g.username,
                  style: _usernameStyle(context),
                ),
                if (timestamp != null)
                  Padding(
                    padding: EdgeInsets.only(top: IsrDimens.two),
                    child: Text(
                      timestamp,
                      style: _timestampStyle(context),
                    ),
                  ),
              ],
            ),
          ),
          if (showAddToHighlight && onAddToHighlightPressed != null) ...[
            _StoryOverlayIconButton(
              icon: Icons.star_border_rounded,
              onPressed: onAddToHighlightPressed!,
            ),
            SizedBox(width: IsrDimens.six),
          ],
          if (canManageCurrentStory &&
              onDeleteStoryPressed != null &&
              !inHighlightViewer) ...[
            _StoryOverlayIconButton(
              icon: Icons.delete_outline_rounded,
              onPressed: onDeleteStoryPressed!,
            ),
            SizedBox(width: IsrDimens.six),
          ],
          if (canManageCurrentStory && inHighlightViewer) ...[
            _StoryOverlayIconButton(
              icon: Icons.more_horiz,
              onPressed: onMoreActionsPressed,
            ),
            SizedBox(width: IsrDimens.six),
          ],
          if (!canManageCurrentStory) ...[
            _StoryOverlayIconButton(
              icon: Icons.more_horiz,
              onPressed: onMoreActionsPressed,
            ),
            SizedBox(width: IsrDimens.six),
          ],
        ],
        _StoryOverlayIconButton(
          icon: Icons.close,
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _StoryOverlayIconButton extends StatelessWidget {
  const _StoryOverlayIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      );
}
