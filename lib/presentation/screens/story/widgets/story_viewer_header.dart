import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/res/res.dart';

class StoryViewerHeader extends StatelessWidget {
  const StoryViewerHeader({
    super.key,
    required this.group,
    required this.story,
    required this.canManageCurrentStory,
    required this.canReactToStory,
    required this.onClose,
    required this.onMoreActionsPressed,
  });

  final StoryGroup? group;
  final StoryData? story;
  final bool canManageCurrentStory;
  /// Viewers who can send reactions (e.g. love) see the same overflow entry point.
  final bool canReactToStory;
  final VoidCallback onClose;
  final VoidCallback onMoreActionsPressed;

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

  @override
  Widget build(BuildContext context) {
    final g = group;
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
                if (story != null && story!.caption.isNotEmpty)
                  _StoryCaptionReadMore(
                    key: ValueKey(story!.caption),
                    caption: story!.caption,
                  ),
              ],
            ),
          ),
          if (canManageCurrentStory || canReactToStory)
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              onPressed: onMoreActionsPressed,
            ),
        ],
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _StoryCaptionReadMore extends StatefulWidget {
  const _StoryCaptionReadMore({
    super.key,
    required this.caption,
  });

  final String caption;

  @override
  State<_StoryCaptionReadMore> createState() => _StoryCaptionReadMoreState();
}

class _StoryCaptionReadMoreState extends State<_StoryCaptionReadMore> {
  static const int _collapsedMaxLines = 2;
  bool _expanded = false;

  TextStyle _captionStyle(BuildContext context) => IsrStyles.getTextStyles(
        color: Colors.white.withValues(alpha: 0.92),
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

  TextStyle _toggleStyle(BuildContext context) =>
      _captionStyle(context).copyWith(
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final style = _captionStyle(context);
          final painter = TextPainter(
            text: TextSpan(text: widget.caption, style: style),
            maxLines: _collapsedMaxLines,
            textDirection: Directionality.of(context),
          )..layout(maxWidth: constraints.maxWidth);
          final exceeds = painter.didExceedMaxLines;

          return Padding(
            padding: EdgeInsets.only(top: IsrDimens.four),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.caption,
                  style: style,
                  maxLines: _expanded ? null : _collapsedMaxLines,
                  overflow:
                      _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
                if (exceeds && !_expanded)
                  Padding(
                    padding: EdgeInsets.only(top: IsrDimens.two),
                    child: GestureDetector(
                      onTap: () => setState(() => _expanded = true),
                      child: Text(
                        IsrTranslationFile.viewMore,
                        style: _toggleStyle(context),
                      ),
                    ),
                  ),
                if (exceeds && _expanded)
                  Padding(
                    padding: EdgeInsets.only(top: IsrDimens.two),
                    child: GestureDetector(
                      onTap: () => setState(() => _expanded = false),
                      child: Text(
                        IsrTranslationFile.viewLess,
                        style: _toggleStyle(context),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
}
