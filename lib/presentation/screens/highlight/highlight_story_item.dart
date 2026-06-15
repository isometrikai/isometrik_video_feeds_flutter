import 'package:ism_video_reel_player/domain/domain.dart';

/// A past story row used when building highlights from profile or composer.
class HighlightStoryItem {
  const HighlightStoryItem({
    required this.id,
    required this.thumbUrl,
    this.dateLabel = '',
  });

  factory HighlightStoryItem.fromStory(StoryData story) => HighlightStoryItem(
        id: story.id,
        thumbUrl: story.thumbDisplayUrl,
        dateLabel: _dateLabelFromStory(story),
      );

  static String _dateLabelFromStory(StoryData story) {
    final raw = story.createdAt.trim();
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return '';
    }
  }

  final String id;
  final String thumbUrl;
  final String dateLabel;
}
