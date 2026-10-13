import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_filter/video_filter_draft.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_filter/video_filter_look.dart';

void main() {
  group('VideoFilterDraft', () {
    test('neutral draft has no edits and no changes', () {
      const draft = VideoFilterDraft.neutral;

      expect(draft.differsFrom(VideoFilterDraft.neutral), isFalse);
      expect(draft.filterHasEdits, isFalse);
      expect(draft.tuneHasEdits, isFalse);
      expect(draft.blurHasEdits, isFalse);
      expect(draft.hasEdits(VideoFilterTool.filter), isFalse);
      expect(draft.hasEdits(VideoFilterTool.tune), isFalse);
      expect(draft.hasEdits(VideoFilterTool.blur), isFalse);
    });

    test('a theme with level marks only the filter tab', () {
      final draft = VideoFilterDraft.neutral.copyWith(
        theme: VideoFilterTheme.warm,
        level: 100,
      );

      expect(draft.filterHasEdits, isTrue);
      expect(draft.tuneHasEdits, isFalse);
      expect(draft.blurHasEdits, isFalse);
      expect(draft.differsFrom(VideoFilterDraft.neutral), isTrue);
    });

    test('original or a zero level clears the filter edit', () {
      final themed = VideoFilterDraft.neutral.withTheme(VideoFilterTheme.vivid);

      expect(themed.level, 100);
      expect(themed.withTheme(VideoFilterTheme.original).filterHasEdits, isFalse);
      expect(themed.copyWith(level: 0).filterHasEdits, isFalse);
      expect(
        themed.withTheme(VideoFilterTheme.original).differsFrom(VideoFilterDraft.neutral),
        isFalse,
      );
    });

    test('a tune value marks the tune tab and zero clears it', () {
      final draft = VideoFilterDraft.neutral.copyWith(contrast: -20);

      expect(draft.tuneHasEdits, isTrue);
      expect(draft.hasEdits(VideoFilterTool.tune), isTrue);
      expect(draft.copyWith(contrast: 0).tuneHasEdits, isFalse);
    });

    test('blur marks the blur tab and zero clears it', () {
      final draft = VideoFilterDraft.neutral.copyWith(blur: 35);

      expect(draft.blurHasEdits, isTrue);
      expect(draft.copyWith(blur: 0).blurHasEdits, isFalse);
    });

    test('matching the opened draft means discard is not required', () {
      const opened = VideoFilterDraft(
        theme: VideoFilterTheme.cool,
        level: 40,
        brightness: 10,
      );
      final edited = opened.copyWith(blur: 15, saturation: -5);

      expect(edited.differsFrom(opened), isTrue);
      expect(
        edited.copyWith(blur: 0, saturation: 0).differsFrom(opened),
        isFalse,
      );
    });

    test('tabs keep independent edits', () {
      final draft = VideoFilterDraft.neutral
          .withTheme(VideoFilterTheme.fade)
          .copyWith(temp: 12, blur: 8);

      expect(draft.hasEdits(VideoFilterTool.filter), isTrue);
      expect(draft.hasEdits(VideoFilterTool.tune), isTrue);
      expect(draft.hasEdits(VideoFilterTool.blur), isTrue);
    });
  });

  group('VideoFilterLook', () {
    test('a neutral draft is an identity matrix with no blur', () {
      final look = VideoFilterLook.fromDraft(VideoFilterDraft.neutral);

      expect(look.matrix, VideoFilterLook.identity);
      expect(look.blurSigma, 0);
      expect(look.coverScale, 1);
    });

    test('level zero keeps the theme from changing the matrix', () {
      final look = VideoFilterLook.fromDraft(
        const VideoFilterDraft(theme: VideoFilterTheme.warm, level: 0),
      );

      expect(look.matrix, VideoFilterLook.identity);
    });

    test('blur grows the radius and the cover scale', () {
      final look = VideoFilterLook.fromDraft(
        const VideoFilterDraft(blur: 100),
      );

      expect(look.blurSigma, greaterThan(0));
      expect(look.coverScale, greaterThan(1));
    });

    test('a visible theme produces an ffmpeg color filter', () {
      final filter = VideoFilterLook.fromDraft(
        const VideoFilterDraft(theme: VideoFilterTheme.warm, level: 100),
      ).ffmpegVideoFilter;

      expect(filter, contains('colorchannelmixer'));
    });
  });
}
