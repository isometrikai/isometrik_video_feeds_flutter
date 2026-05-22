import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/extensions.dart';

class StoryViewerFooter extends StatelessWidget {
  const StoryViewerFooter({
    super.key,
    required this.story,
    required this.showViewCount,
  });

  final StoryData? story;
  final bool showViewCount;

  @override
  Widget build(BuildContext context) {
    final s = story;
    if (s == null) return const SizedBox.shrink();

    final hasCaption = s.caption.trim().isNotEmpty;
    final hasViewCount = showViewCount;

    if (!hasCaption && !hasViewCount) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasCaption)
          Padding(
            padding:
                IsrDimens.edgeInsetsSymmetric(horizontal: IsrDimens.sixteen),
            child: _StoryCaptionReadMore(
              key: ValueKey(s.caption),
              caption: s.caption,
            ),
          ),
        if (hasCaption && hasViewCount) SizedBox(height: IsrDimens.sixteen),
        if (hasViewCount) _StoryViewCountPill(viewCount: s.viewCount),
      ],
    );
  }
}

class _StoryViewCountPill extends StatelessWidget {
  const _StoryViewCountPill({required this.viewCount});

  final int viewCount;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          padding: IsrDimens.edgeInsetsSymmetric(
            horizontal: IsrDimens.sixteen,
            vertical: IsrDimens.eight,
          ),
          decoration: BoxDecoration(
            color: IsrColors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(IsrDimens.twentyFour),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.remove_red_eye_outlined,
                color: Colors.white,
                size: 18.responsiveDimension,
              ),
              SizedBox(width: IsrDimens.eight),
              Text(
                '$viewCount ${viewCount == 1 ? 'view' : 'views'}',
                style: IsrStyles.primaryText14.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
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
  static const int _collapsedMaxLines = 3;
  bool _expanded = false;

  TextStyle _captionStyle(BuildContext context) => IsrStyles.getTextStyles(
        color: Colors.white,
        fontSize: IsrDimens.fifteen,
      ).copyWith(
        shadows: const [
          Shadow(
            offset: Offset(0, 1),
            blurRadius: 4,
            color: Color(0x80000000),
          ),
        ],
      );

  TextStyle _toggleStyle(BuildContext context) =>
      _captionStyle(context).copyWith(
        fontWeight: FontWeight.w600,
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

          return Column(
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
                  padding: EdgeInsets.only(top: IsrDimens.four),
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
                  padding: EdgeInsets.only(top: IsrDimens.four),
                  child: GestureDetector(
                    onTap: () => setState(() => _expanded = false),
                    child: Text(
                      IsrTranslationFile.viewLess,
                      style: _toggleStyle(context),
                    ),
                  ),
                ),
            ],
          );
        },
      );
}
