import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_add/video_add_draft.dart';

void main() {
  group('VideoAddEditor', () {
    test('an empty canvas does not enable Done or ask to discard', () {
      final editor = VideoAddEditor();

      expect(editor.hasContent, isFalse);
      expect(editor.shouldConfirmDiscard, isFalse);
      expect(editor.canUndo, isFalse);
      expect(editor.canRedo, isFalse);
    });

    test('adding text enables Done and the text tab dot', () {
      final editor = VideoAddEditor();
      final item = editor.place(
        type: VideoAddItemType.text,
        text: 'Hello',
      );

      expect(editor.hasContent, isTrue);
      expect(editor.shouldConfirmDiscard, isTrue);
      expect(editor.document.hasTool(VideoAddTool.text), isTrue);
      expect(editor.document.hasTool(VideoAddTool.sticker), isFalse);
      expect(editor.document.hasTool(VideoAddTool.emoji), isFalse);
      expect(editor.document.hasTool(VideoAddTool.draw), isFalse);
      expect(item.x, 0.5);
      expect(item.y, 0.5);
    });

    test('a second item is offset from the center', () {
      final editor = VideoAddEditor();
      editor.place(type: VideoAddItemType.text, text: 'One');
      final second = editor.place(
        type: VideoAddItemType.sticker,
        assetPath: 'heart.svg',
      );

      expect(second.x, isNot(0.5));
      expect(editor.document.hasTool(VideoAddTool.sticker), isTrue);
      expect(editor.document.hasTool(VideoAddTool.text), isTrue);
    });

    test('move clamps position and scale, and undo restores them', () {
      final editor = VideoAddEditor();
      final item = editor.place(type: VideoAddItemType.emoji, emoji: '🔥');

      editor.move(item.id, x: -1, y: 2, scale: 9);

      final moved = editor.document.item(item.id);
      expect(moved?.x, 0.02);
      expect(moved?.y, 0.98);
      expect(moved?.scale, 4);

      editor.undo();
      expect(editor.document.item(item.id)?.x, 0.5);
      expect(editor.document.item(item.id)?.scale, 1);
      expect(editor.canRedo, isTrue);

      editor.redo();
      expect(editor.document.item(item.id)?.scale, 4);
    });

    test('delete clears the canvas and undo brings the item back', () {
      final editor = VideoAddEditor();
      final item = editor.place(type: VideoAddItemType.text, text: 'Bye');

      editor.delete(item.id);

      expect(editor.hasContent, isFalse);
      expect(editor.shouldConfirmDiscard, isFalse);
      expect(editor.document.hasTool(VideoAddTool.text), isFalse);

      editor.undo();
      expect(editor.document.item(item.id)?.text, 'Bye');
      expect(editor.hasContent, isTrue);
    });

    test('a new edit clears redo', () {
      final editor = VideoAddEditor();
      editor.place(type: VideoAddItemType.text, text: 'A');
      editor.undo();
      editor.place(type: VideoAddItemType.text, text: 'B');

      expect(editor.canRedo, isFalse);
      expect(editor.document.items.single.text, 'B');
    });

    test('a stroke marks only the draw tab', () {
      final editor = VideoAddEditor();
      editor.addStroke(
        const VideoAddStroke(
          points: [VideoAddPoint(0.2, 0.2), VideoAddPoint(0.4, 0.5)],
          color: 0xFFD92D20,
          width: 0.02,
        ),
      );

      expect(editor.document.hasTool(VideoAddTool.draw), isTrue);
      expect(editor.document.hasTool(VideoAddTool.text), isFalse);
      expect(editor.hasContent, isTrue);

      editor.undo();
      expect(editor.document.strokes, isEmpty);
      expect(editor.shouldConfirmDiscard, isFalse);
    });

    test('an unchanged commit is not a history step', () {
      final editor = VideoAddEditor();
      editor.place(type: VideoAddItemType.text, text: 'Hi');
      final current = editor.document;

      editor.commit(current);

      expect(editor.canUndo, isTrue);
      editor.undo();
      expect(editor.canUndo, isFalse);
    });

    test('background and shadow can be cleared and restored by undo', () {
      final editor = VideoAddEditor();
      final placed = editor.place(
        type: VideoAddItemType.text,
        text: 'Hi',
        color: 0xFFFFFFFF,
        background: 0xFF6D4AFF,
        shadow: 0xFF1C1C22,
      );

      expect(placed.background, 0xFF6D4AFF);
      expect(placed.shadow, 0xFF1C1C22);

      final cleared = placed.copyWith(background: null, shadow: null);
      expect(cleared.background, isNull);
      expect(cleared.shadow, isNull);
      expect(cleared.color, 0xFFFFFFFF);

      final restored = VideoAddItem.fromJson(cleared.toJson());
      expect(restored.background, isNull);
      expect(restored.shadow, isNull);

      editor.delete(placed.id);
      expect(editor.document.items, isEmpty);
      editor.undo();
      expect(editor.document.items.single.text, 'Hi');
      expect(editor.document.items.single.shadow, 0xFF1C1C22);
    });

    test('recent emoji moves to the front and stays unique', () {
      final recent = VideoAddDraft.rememberEmoji(
        VideoAddDraft.defaultRecent,
        '🔥',
      );

      expect(recent.first, '🔥');
      expect(recent.where((emoji) => emoji == '🔥'), hasLength(1));
      expect(recent, hasLength(8));
    });
  });
}
