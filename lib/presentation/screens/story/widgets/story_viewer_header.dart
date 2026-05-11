import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/res/res.dart';

class StoryViewerHeader extends StatelessWidget {
  const StoryViewerHeader({
    super.key,
    required this.group,
    required this.story,
    required this.canManageCurrentStory,
    required this.onClose,
    required this.onMoreActionsPressed,
  });

  final StoryGroup? group;
  final StoryData? story;
  final bool canManageCurrentStory;
  final VoidCallback onClose;
  final VoidCallback onMoreActionsPressed;

  @override
  Widget build(BuildContext context) {
    final g = group;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: onClose,
        ),
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
                  style: IsrStyles.primaryText16Bold,
                ),
                if (story != null && story!.caption.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: IsrDimens.four),
                    child: Text(
                      story!.caption,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: IsrStyles.getTextStyles(
                        color: Colors.white70,
                        fontSize: IsrDimens.thirteen,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (canManageCurrentStory)
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              onPressed: onMoreActionsPressed,
            ),
        ],
      ],
    );
  }
}
