import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_add/video_add_canvas.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_add/video_add_catalog.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_add/video_add_draft.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_add/video_add_raster.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/app_button.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/app_image.dart';
import 'package:ism_video_reel_player/utils/enums.dart';
import 'package:ism_video_reel_player/utils/ffmpeg_media_ops.dart';
import 'package:video_player/video_player.dart';

/// Text, stickers, emoji, and drawing for one video.
class VideoAddScreen extends StatefulWidget {
  const VideoAddScreen({
    super.key,
    required this.videoPath,
    required this.stickerAssetPaths,
    this.initial = VideoAddDraft.empty,
  });

  final VideoAddDraft initial;
  final List<String> stickerAssetPaths;
  final String videoPath;

  @override
  State<VideoAddScreen> createState() => _VideoAddScreenState();
}

class _VideoAddScreenState extends State<VideoAddScreen> {
  final List<GlobalKey> _sectionKeys = List<GlobalKey>.generate(
    VideoAddCatalog.categories.length,
    (_) => GlobalKey(),
  );

  late final VideoPlayerController _controller;
  late final VideoAddEditor _editor;
  late final FocusNode _focus;
  late final TextEditingController _text;
  late final ScrollController _emojiScroll;

  late List<String> _recent;
  var _tool = VideoAddTool.text;
  final _chipsKey = GlobalKey();
  final _colorPortal = OverlayPortalController();
  var _font = VideoAddFont.classic;
  var _color = 0xFFFFFFFF;
  int? _background;
  int? _shadow = 0xFF1C1C22;
  _TextColorTarget? _colorTarget;
  var _picking = false;
  var _hue = 262.0;
  var _saturation = 90.0;
  var _lightness = 62.0;
  var _drawTool = VideoAddDrawTool.freehand;
  var _drawColor = 0xFFD92D20;
  var _strokeSlider = 35.0;
  var _emojiCategory = 0;
  int? _selectedId;
  int? _editingId;
  VideoAddDocument? _preEdit;
  VideoAddDocument? _beforeGesture;
  var _playing = false;
  var _ready = false;
  var _saving = false;
  var _encodeProgress = 0.0;

  bool get _keyboard => _focus.hasFocus;

  VideoAddItem? get _ghost {
    if (_tool != VideoAddTool.text || _editingId != null) return null;
    final value = _text.text.trim();
    if (value.isEmpty) return null;
    return VideoAddItem(
      id: -1,
      type: VideoAddItemType.text,
      x: 0.5,
      y: 0.5,
      text: value,
      font: _font,
      color: _color,
      background: _background,
      shadow: _shadow,
    );
  }

  @override
  void initState() {
    super.initState();
    _editor = VideoAddEditor(initial: widget.initial.document);
    _recent = List<String>.of(widget.initial.recentEmojis);
    _text = TextEditingController()..addListener(_onTextChanged);
    _focus = FocusNode()..addListener(_onFocus);
    _emojiScroll = ScrollController();
    _controller = VideoPlayerController.file(File(widget.videoPath));
    unawaited(_open());
  }

  @override
  void dispose() {
    _text.removeListener(_onTextChanged);
    _text.dispose();
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _emojiScroll.dispose();
    _controller.removeListener(_onPlayback);
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _open() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.pause();
      _controller.addListener(_onPlayback);
      if (!mounted) return;
      setState(() => _ready = _controller.value.isInitialized);
    } catch (_) {
      if (mounted) setState(() => _ready = false);
    }
  }

  void _onPlayback() {
    final playing = _controller.value.isPlaying;
    if (playing == _playing || !mounted) return;
    setState(() => _playing = playing);
  }

  void _onFocus() {
    if (_focus.hasFocus && _colorTarget != null) {
      _colorTarget = null;
      _picking = false;
    }
    if (mounted) setState(() {});
  }

  void _onTextChanged() {
    if (!mounted) return;
    final id = _editingId;
    if (id == null) {
      setState(() {});
      return;
    }
    final item = _editor.document.item(id);
    if (item == null || item.text == _text.text) {
      setState(() {});
      return;
    }
    _editor.apply(_editor.document.updateItem(item.copyWith(text: _text.text)));
    setState(() {});
  }

  void _togglePlay() {
    if (!_ready) return;
    if (_playing) {
      unawaited(_controller.pause());
    } else {
      unawaited(_controller.play());
    }
  }

  void _setFont(VideoAddFont font) {
    _font = font;
    _colorTarget = null;
    _picking = false;
    _applyTextStyle();
  }

  void _applyTextStyle() {
    final id = _editingId;
    final item = id == null ? null : _editor.document.item(id);
    if (item != null) {
      _editor.apply(
        _editor.document.updateItem(
          item.copyWith(
            font: _font,
            color: _color,
            background: _background,
            shadow: _shadow,
          ),
        ),
      );
    }
    setState(() {});
  }

  void _placeText() {
    final value = _text.text.trim();
    if (value.isEmpty) return;
    if (_editingId != null) {
      _endEditing();
      return;
    }
    final item = _editor.place(
      type: VideoAddItemType.text,
      text: value,
      font: _font,
      color: _color,
      background: _background,
      shadow: _shadow,
    );
    _selectedId = item.id;
    _text.clear();
    _focus.unfocus();
    setState(() {});
  }

  void _editText(int id) {
    final item = _editor.document.item(id);
    if (item == null || item.type != VideoAddItemType.text) return;
    _editingId = id;
    _preEdit = _editor.document;
    _selectedId = id;
    _tool = VideoAddTool.text;
    _font = item.font;
    _color = item.color;
    _background = item.background;
    _shadow = item.shadow;
    _text.value = TextEditingValue(
      text: item.text,
      selection: TextSelection.collapsed(offset: item.text.length),
    );
    setState(() {});
    _focus.requestFocus();
  }

  void _endEditing() {
    final id = _editingId;
    final before = _preEdit;
    if (id == null || before == null) return;
    _editingId = null;
    _preEdit = null;
    final item = _editor.document.item(id);
    if (item != null && item.text.trim().isEmpty) {
      _editor.apply(_editor.document.removeItem(id));
      if (_selectedId == id) _selectedId = null;
    } else if (item != null) {
      _editor.apply(
        _editor.document.updateItem(item.copyWith(text: item.text.trim())),
      );
    }
    _editor.commit(before);
    _text.clear();
    _focus.unfocus();
    setState(() {});
  }

  void _deselect() {
    _endEditing();
    _selectedId = null;
    _colorTarget = null;
    _picking = false;
    _focus.unfocus();
    setState(() {});
  }

  void _setTool(VideoAddTool tool) {
    if (_editingId != null) _endEditing();
    _colorTarget = null;
    _picking = false;
    setState(() => _tool = tool);
  }

  void _deleteItem(int id) {
    if (_editingId == id) {
      _editingId = null;
      _preEdit = null;
      _text.clear();
      _focus.unfocus();
    }
    _editor.delete(id);
    if (_selectedId == id) _selectedId = null;
    _colorTarget = null;
    _picking = false;
    setState(() {});
  }

  void _undo() {
    _endEditing();
    _colorTarget = null;
    _picking = false;
    _editor.undo();
    _selectedId = null;
    setState(() {});
  }

  void _redo() {
    _endEditing();
    _colorTarget = null;
    _picking = false;
    _editor.redo();
    _selectedId = null;
    setState(() {});
  }

  void _gestureStart() => _beforeGesture ??= _editor.document;

  void _gestureEnd() {
    final before = _beforeGesture;
    _beforeGesture = null;
    if (before != null) _editor.commit(before);
    setState(() {});
  }

  void _onDocument(VideoAddDocument next) {
    _editor.apply(next);
    final selected = _selectedId;
    if (selected != null && next.item(selected) == null) _selectedId = null;
    setState(() {});
  }

  void _placeSticker(String path) {
    final item = _editor.place(
      type: VideoAddItemType.sticker,
      assetPath: path,
    );
    setState(() => _selectedId = item.id);
  }

  void _placeEmoji(String emoji) {
    final item = _editor.place(
      type: VideoAddItemType.emoji,
      emoji: emoji,
    );
    _recent = VideoAddDraft.rememberEmoji(_recent, emoji);
    setState(() => _selectedId = item.id);
  }

  void _scrollToCategory(int index) {
    setState(() => _emojiCategory = index);
    final target = _sectionKeys[index].currentContext;
    if (target == null) return;
    unawaited(
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 200),
        alignment: 0.15,
      ),
    );
  }

  Future<void> _apply() async {
    _endEditing();
    if (!_editor.hasContent || _saving || !mounted) return;
    if (_ready && _playing) await _controller.pause();
    if (!mounted) return;
    setState(() {
      _saving = true;
      _encodeProgress = 0;
    });
    final info = await FfmpegMediaOps.probe(widget.videoPath);
    var width = info?.width ?? 0;
    var height = info?.height ?? 0;
    if ((width <= 0 || height <= 0) && _controller.value.isInitialized) {
      width = _controller.value.size.width.round();
      height = _controller.value.size.height.round();
    }
    if (!mounted) return;
    if (width <= 0 || height <= 0) {
      _failApply();
      return;
    }
    final png = await rasterizeVideoAddPng(
      context: context,
      document: _editor.document,
      width: width,
      height: height,
    );
    if (!mounted) return;
    if (png == null) {
      _failApply();
      return;
    }
    final output = await FfmpegMediaOps.encodeVideoOverlay(
      inputPath: widget.videoPath,
      overlayPng: png,
      onProgress: (value) {
        if (!mounted) return;
        setState(() => _encodeProgress = value);
      },
    );
    if (!mounted) return;
    if (output == null) {
      _failApply();
      return;
    }
    Navigator.of(context).pop(
      VideoAddExport(
        draft: VideoAddDraft(
          document: _editor.document,
          recentEmojis: List<String>.of(_recent),
        ),
        inputPath: widget.videoPath,
        outputPath: output,
      ),
    );
  }

  void _failApply() {
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not apply the additions')),
    );
  }

  Future<void> _close() async {
    _focus.unfocus();
    if (!_editor.shouldConfirmDiscard) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final discard = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _DiscardSheet(),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = _keyboard;
    final popupOpen = _colorTarget != null;
    if (popupOpen != _colorPortal.isShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || (_colorTarget != null) == _colorPortal.isShowing) return;
        if (_colorTarget != null) {
          _colorPortal.show();
        } else {
          _colorPortal.hide();
        }
      });
    }
    return PopScope(
      canPop: !_saving && !_editor.shouldConfirmDiscard,
      onPopInvokedWithResult: (didPop, _) {
        if (_saving || didPop) return;
        unawaited(_close());
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(child: _preview()),
                  if (!keyboard) _history(),
                  _panel(keyboard),
                ],
              ),
            ),
            if (_saving) _encodingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _preview() => LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth - 32;
          final maxHeight = constraints.maxHeight - 16;
          var width = maxWidth;
          var height = width * 16 / 9;
          if (height > maxHeight) {
            height = maxHeight;
            width = height * 9 / 16;
          }
          final aspect = _ready && _controller.value.aspectRatio > 0
              ? _controller.value.aspectRatio
              : 9 / 16;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ColoredBox(
                    color: const Color(0xFF111111),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: aspect,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_ready) VideoPlayer(_controller),
                            VideoAddStage(
                              document: _editor.document,
                              selectedId: _selectedId,
                              ghost: _ghost,
                              drawing: _tool == VideoAddTool.draw,
                              drawTool: _drawTool,
                              drawColor: Color(_drawColor),
                              strokeSlider: _strokeSlider,
                              onDocument: _onDocument,
                              onSelect: (id) {
                                _colorTarget = null;
                                _picking = false;
                                setState(() => _selectedId = id);
                              },
                              onEditText: _editText,
                              onDelete: _deleteItem,
                              onDeselect: _deselect,
                              onGestureStart: _gestureStart,
                              onGestureEnd: _gestureEnd,
                              onStroke: (stroke) {
                                _editor.addStroke(stroke);
                                setState(() {});
                              },
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: _playButton(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

  Widget _playButton() => Semantics(
        button: true,
        label: _playing ? 'Pause' : 'Play',
        child: Material(
          color: VideoAddPalette.ink,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _ready ? _togglePlay : null,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                _playing ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      );

  Widget _history() => SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _historyButton(
                label: 'Undo',
                icon: Icons.undo,
                enabled: _editor.canUndo,
                onPressed: _undo,
              ),
              _historyButton(
                label: 'Redo',
                icon: Icons.redo,
                enabled: _editor.canRedo,
                onPressed: _redo,
              ),
            ],
          ),
        ),
      );

  Widget _historyButton({
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) =>
      Semantics(
        button: true,
        label: label,
        child: IconButton(
          tooltip: label,
          onPressed: enabled ? onPressed : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          style: IconButton.styleFrom(
            foregroundColor: VideoAddPalette.ink,
            disabledForegroundColor: const Color(0xFFB4B4BF),
          ),
          icon: Icon(icon, size: 22),
        ),
      );

  Widget _panel(bool keyboard) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: VideoAddPalette.disabled)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, keyboard ? 8 : 12),
          child: GestureDetector(
            onTap: _closeColors,
            behavior: HitTestBehavior.translucent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 168, child: _toolBody()),
                if (!keyboard) ...[
                  const SizedBox(height: 6),
                  _tabs(),
                  const SizedBox(height: 12),
                  _actions(),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _toolBody() => switch (_tool) {
        VideoAddTool.text => _textTool(),
        VideoAddTool.sticker => _stickerTool(),
        VideoAddTool.emoji => _emojiTool(),
        VideoAddTool.draw => _drawToolBody(),
      };

  Widget _textTool() {
    final editing = _editingId != null;
    final enabled = _text.text.trim().isNotEmpty;
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  focusNode: _focus,
                  maxLength: 24,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _placeText(),
                  style: const TextStyle(color: VideoAddPalette.ink, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Add text',
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    hintStyle: const TextStyle(color: VideoAddPalette.secondary),
                    border: _fieldBorder(VideoAddPalette.track),
                    enabledBorder: _fieldBorder(VideoAddPalette.track),
                    focusedBorder: _fieldBorder(VideoAddPalette.accent),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                height: 44,
                child: FilledButton(
                  onPressed: enabled ? _placeText : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: VideoAddPalette.accent,
                    disabledBackgroundColor: VideoAddPalette.disabled,
                    disabledForegroundColor: VideoAddPalette.disabledText,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    editing ? 'Update' : 'Add',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              for (final font in VideoAddFont.values) ...[
                if (font != VideoAddFont.classic) const SizedBox(width: 8),
                Expanded(child: _fontChip(font)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        _colorChipRow(),
      ],
    );
  }

  OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  Widget _fontChip(VideoAddFont font) {
    final selected = font == _font;
    return Semantics(
      button: true,
      selected: selected,
      label: font.label,
      child: Material(
        color: selected ? VideoAddPalette.tint : VideoAddPalette.fill,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _setFont(font),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? VideoAddPalette.accent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Text(
              font.label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: font == VideoAddFont.modern ? FontWeight.w800 : FontWeight.w700,
                fontFamily: switch (font) {
                  VideoAddFont.classic => 'Georgia',
                  VideoAddFont.typewriter => 'Courier',
                  _ => null,
                },
                fontFamilyFallback: switch (font) {
                  VideoAddFont.classic => const ['Times New Roman', 'serif'],
                  VideoAddFont.typewriter => const ['monospace'],
                  _ => null,
                },
                color: VideoAddPalette.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _swatch(Color color, {required bool selected, required VoidCallback onTap}) =>
      Semantics(
        button: true,
        selected: selected,
        label: 'Color ${color.toARGB32().toRadixString(16)}',
        child: SizedBox(
          width: 44,
          height: 44,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x24000000)),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: VideoAddPalette.accent,
                            spreadRadius: 4,
                          ),
                          BoxShadow(color: Colors.white, spreadRadius: 2),
                        ]
                      : null,
                ),
                child: const SizedBox(width: 28, height: 28),
              ),
            ),
          ),
        ),
      );

  Widget _colorChipRow() => OverlayPortal(
        controller: _colorPortal,
        overlayChildBuilder: (context) => _colorPopupLayer(),
        child: KeyedSubtree(key: _chipsKey, child: _colorChips()),
      );

  Widget _colorChips() => SizedBox(
        height: 44,
        child: Row(
          children: [
            for (final target in _TextColorTarget.values) ...[
              if (target != _TextColorTarget.text) const SizedBox(width: 8),
              Expanded(child: _colorChip(target)),
            ],
          ],
        ),
      );

  Widget _colorChip(_TextColorTarget target) {
    final selected = _colorTarget == target;
    final value = _slotValue(target);
    return Semantics(
      button: true,
      selected: selected,
      label: target.chipLabel,
      child: Material(
        color: selected ? VideoAddPalette.tint : VideoAddPalette.fill,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _toggleColor(target),
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? VideoAddPalette.accent : Colors.transparent,
                width: 2,
              ),
            ),
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _colorDot(value),
                  const SizedBox(width: 8),
                  Text(
                    target.chipLabel,
                    style: const TextStyle(fontSize: 13, color: VideoAddPalette.ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorDot(int? value) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value == null ? null : Color(value),
          border: Border.all(color: const Color(0x2E000000)),
          gradient: value == null
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.white,
                    VideoAddPalette.destructive,
                    VideoAddPalette.destructive,
                    Colors.white,
                    Colors.white,
                  ],
                  stops: [0, 0.44, 0.44, 0.56, 0.56, 1],
                )
              : null,
        ),
      );

  Widget _colorPopupLayer() {
    final target = _chipsKey.currentContext?.findRenderObject();
    if (target is! RenderBox || !target.attached || !target.hasSize) {
      return const SizedBox.shrink();
    }
    final overlay = Overlay.of(context).context.findRenderObject();
    final origin = target.localToGlobal(Offset.zero);
    final local = overlay is RenderBox ? overlay.globalToLocal(origin) : origin;
    final height = overlay is RenderBox ? overlay.size.height : MediaQuery.sizeOf(context).height;
    return Positioned(
      left: local.dx,
      width: target.size.width,
      bottom: height - local.dy + 20,
      child: GestureDetector(
        onTap: () {},
        behavior: HitTestBehavior.opaque,
        child: _colorPopup(),
      ),
    );
  }

  Widget _colorPopup() {
    final target = _colorTarget;
    if (target == null) return const SizedBox.shrink();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E4EA)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x381C1C22),
                blurRadius: 28,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: _picking ? _pickerBody() : _swatchBody(target),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -7,
          child: Align(
            alignment: Alignment(target.arrow, 0),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A1C1C22),
                      blurRadius: 4,
                      offset: Offset(3, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _swatchBody(_TextColorTarget target) {
    final current = _slotValue(target);
    final colors = <int?>[
      if (target != _TextColorTarget.text) null,
      for (final preset in VideoAddPalette.textPresets) preset.toARGB32(),
    ];
    if (current != null && !_isPreset(current)) colors.add(current);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _popupHeader(target.popupLabel, back: false),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              for (final color in colors)
                Expanded(
                  child: _popupSwatch(
                    color,
                    selected: color == null ? current == null : _sameColor(current, color),
                    onTap: () => _chooseSwatch(color),
                  ),
                ),
              Expanded(child: _moreSwatch()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pickerBody() {
    final color = VideoAddCatalog.hslToArgb(_hue, _saturation, _lightness);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _popupHeader('Pick a color', back: true),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(color),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x29000000)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _hexLabel(color),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.28,
                        color: VideoAddPalette.ink,
                      ),
                    ),
                  ],
                ),
              ),
              _hslSlider(
                label: 'Hue',
                value: _hue,
                max: 360,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF0000),
                    Color(0xFFFFFF00),
                    Color(0xFF00FF00),
                    Color(0xFF00FFFF),
                    Color(0xFF0000FF),
                    Color(0xFFFF00FF),
                    Color(0xFFFF0000),
                  ],
                ),
                onChanged: (value) {
                  _hue = value;
                  _applyPicked();
                },
              ),
              _hslSlider(
                label: 'Saturation',
                value: _saturation,
                max: 100,
                gradient: LinearGradient(
                  colors: [
                    Color(VideoAddCatalog.hslToArgb(_hue, 0, _lightness)),
                    Color(VideoAddCatalog.hslToArgb(_hue, 100, _lightness)),
                  ],
                ),
                onChanged: (value) {
                  _saturation = value;
                  _applyPicked();
                },
              ),
              _hslSlider(
                label: 'Lightness',
                value: _lightness,
                max: 100,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF000000),
                    Color(VideoAddCatalog.hslToArgb(_hue, _saturation, 50)),
                    const Color(0xFFFFFFFF),
                  ],
                ),
                onChanged: (value) {
                  _lightness = value;
                  _applyPicked();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _popupHeader(String title, {required bool back}) => SizedBox(
        height: 36,
        child: Row(
          children: [
            if (back)
              _popupIcon(
                label: 'Back',
                icon: Icons.chevron_left,
                onTap: () => setState(() => _picking = false),
              )
            else
              const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: VideoAddPalette.ink,
                ),
              ),
            ),
            _popupIcon(
              label: 'Close',
              icon: Icons.close,
              onTap: _closeColors,
            ),
          ],
        ),
      );

  Widget _popupIcon({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 36,
            child: Icon(icon, size: 18, color: VideoAddPalette.secondary),
          ),
        ),
      );

  Widget _popupSwatch(int? color, {required bool selected, required VoidCallback onTap}) =>
      Semantics(
      button: true,
      selected: selected,
      label: color == null ? 'None' : _hexLabel(color),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(child: _roundSwatch(color, selected: selected)),
        ),
      ),
    );

  Widget _moreSwatch() => Semantics(
        button: true,
        label: 'More colors',
        child: InkWell(
          onTap: _openPicker,
          child: const SizedBox(
            height: 44,
            child: Center(child: _MoreSwatch()),
          ),
        ),
      );

  Widget _roundSwatch(int? color, {required bool selected}) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color == null ? null : Color(color),
          border: Border.all(color: const Color(0x29000000)),
          gradient: color == null
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.white,
                    VideoAddPalette.destructive,
                    VideoAddPalette.destructive,
                    Colors.white,
                    Colors.white,
                  ],
                  stops: [0, 0.44, 0.44, 0.56, 0.56, 1],
                )
              : null,
          boxShadow: selected
              ? const [
                  BoxShadow(color: VideoAddPalette.accent, spreadRadius: 4),
                  BoxShadow(color: Colors.white, spreadRadius: 2),
                ]
              : null,
        ),
      );

  Widget _hslSlider({
    required String label,
    required double value,
    required double max,
    required Gradient gradient,
    required ValueChanged<double> onChanged,
  }) =>
      SizedBox(
        height: 40,
        child: Row(
          children: [
            SizedBox(
              width: 68,
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: VideoAddPalette.secondary),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 10,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: Colors.white,
                  overlayColor: const Color(0x1F6D4AFF),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                    elevation: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: gradient,
                      ),
                    ),
                    Slider(
                      value: value.clamp(0, max).toDouble(),
                      max: max,
                      semanticFormatterCallback: (next) => '$label ${next.round()}',
                      onChanged: onChanged,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  void _toggleColor(_TextColorTarget target) {
    _focus.unfocus();
    setState(() {
      if (_colorTarget == target) {
        _colorTarget = null;
        _picking = false;
      } else {
        _colorTarget = target;
        _picking = false;
      }
    });
  }

  void _closeColors() {
    if (_colorTarget == null && !_picking) return;
    setState(() {
      _colorTarget = null;
      _picking = false;
    });
  }

  void _openPicker() {
    final current = _slotValue(_colorTarget);
    final hsl = current == null ? null : VideoAddCatalog.argbToHsl(current);
    if (hsl != null && hsl.s > 10 && hsl.l > 8 && hsl.l < 92) {
      _hue = hsl.h;
      _saturation = hsl.s;
      _lightness = hsl.l;
    } else {
      _hue = 262;
      _saturation = 90;
      _lightness = 62;
    }
    setState(() => _picking = true);
  }

  void _chooseSwatch(int? color) {
    switch (_colorTarget) {
      case _TextColorTarget.text:
        if (color != null) _color = color;
      case _TextColorTarget.background:
        _background = color;
      case _TextColorTarget.shadow:
        _shadow = color;
      case null:
        break;
    }
    _colorTarget = null;
    _picking = false;
    _applyTextStyle();
  }

  void _applyPicked() {
    final color = VideoAddCatalog.hslToArgb(_hue, _saturation, _lightness);
    switch (_colorTarget) {
      case _TextColorTarget.text:
        _color = color;
      case _TextColorTarget.background:
        _background = color;
      case _TextColorTarget.shadow:
        _shadow = color;
      case null:
        break;
    }
    _applyTextStyle();
  }

  int? _slotValue(_TextColorTarget? target) => switch (target) {
        _TextColorTarget.text => _color,
        _TextColorTarget.background => _background,
        _TextColorTarget.shadow => _shadow,
        null => null,
      };

  bool _isPreset(int color) =>
      VideoAddPalette.textPresets.any((preset) => _sameColor(preset.toARGB32(), color));

  bool _sameColor(int? left, int right) => left != null && (left & 0xFFFFFF) == (right & 0xFFFFFF);

  String _hexLabel(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  Widget _stickerTool() {
    final paths = widget.stickerAssetPaths;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 22,
          child: Text(
            'Stickers',
            style: TextStyle(
              color: VideoAddPalette.ink,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: paths.isEmpty
              ? const DecoratedBox(
                  decoration: BoxDecoration(
                    color: VideoAddPalette.fill,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Center(
                    child: Text(
                      'No stickers available',
                      style: TextStyle(color: VideoAddPalette.secondary, fontSize: 14),
                    ),
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    mainAxisExtent: 58,
                  ),
                  itemCount: paths.length,
                  itemBuilder: (context, index) {
                    final path = paths[index];
                    final label = VideoAddCatalog.stickerLabel(path);
                    return Semantics(
                      button: true,
                      label: label,
                      child: Material(
                        color: VideoAddPalette.fill,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _placeSticker(path),
                          borderRadius: BorderRadius.circular(12),
                          child: Center(child: _stickerThumb(path)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _stickerThumb(String path) {
    if (path.toLowerCase().endsWith('.png')) {
      return AppImage.asset(path, width: 32, height: 32, fit: BoxFit.contain);
    }
    return AppImage.svg(path, width: 32, height: 32, fit: BoxFit.contain);
  }

  Widget _emojiTool() => CustomScrollView(
        controller: _emojiScroll,
        slivers: [
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 20,
              child: Text(
                'Recent',
                style: TextStyle(
                  color: VideoAddPalette.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  for (final emoji in _recent)
                    Expanded(child: _emojiButton(emoji)),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _EmojiCategories(
              selected: _emojiCategory,
              onSelect: _scrollToCategory,
            ),
          ),
          for (var index = 0; index < VideoAddCatalog.categories.length; index++) ...[
            SliverToBoxAdapter(
              child: SizedBox(
                key: _sectionKeys[index],
                height: 28,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    VideoAddCatalog.categories[index].name,
                    style: const TextStyle(
                      color: VideoAddPalette.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisExtent: 44,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, emojiIndex) => _emojiButton(
                  VideoAddCatalog.categories[index].emojis[emojiIndex],
                ),
                childCount: VideoAddCatalog.categories[index].emojis.length,
              ),
            ),
          ],
        ],
      );

  Widget _emojiButton(String emoji) => Semantics(
        button: true,
        label: emoji,
        child: InkWell(
          onTap: () => _placeEmoji(emoji),
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24, height: 1)),
          ),
        ),
      );

  Widget _drawToolBody() => Column(
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                for (final tool in VideoAddDrawTool.values)
                  Expanded(child: _drawButton(tool)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: Row(
              children: [
                for (final color in VideoAddPalette.drawColors)
                  _swatch(
                    color,
                    selected: color.toARGB32() == _drawColor,
                    onTap: () => setState(() => _drawColor = color.toARGB32()),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: Row(
              children: [
                const Text(
                  'Thin',
                  style: TextStyle(color: VideoAddPalette.secondary, fontSize: 12),
                ),
                Expanded(
                  child: Semantics(
                    label: 'Stroke width',
                    slider: true,
                    value: _strokeSlider.round().toString(),
                    child: Slider(
                      value: _strokeSlider,
                      max: 100,
                      divisions: 100,
                      activeColor: VideoAddPalette.accent,
                      onChanged: (value) => setState(() => _strokeSlider = value),
                    ),
                  ),
                ),
                const Text(
                  'Thick',
                  style: TextStyle(color: VideoAddPalette.secondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _drawButton(VideoAddDrawTool tool) {
    final selected = tool == _drawTool;
    return Semantics(
      button: true,
      selected: selected,
      label: tool.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: selected ? VideoAddPalette.tint : VideoAddPalette.fill,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => setState(() => _drawTool = tool),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? VideoAddPalette.accent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                switch (tool) {
                  VideoAddDrawTool.freehand => Icons.draw_outlined,
                  VideoAddDrawTool.arrow => Icons.arrow_outward,
                  VideoAddDrawTool.line => Icons.remove,
                  VideoAddDrawTool.rectangle => Icons.crop_square,
                  VideoAddDrawTool.circle => Icons.circle_outlined,
                  VideoAddDrawTool.eraser => Icons.auto_fix_off_outlined,
                },
                size: 22,
                color: selected ? VideoAddPalette.accent : VideoAddPalette.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabs() => DecoratedBox(
        decoration: BoxDecoration(
          color: VideoAddPalette.fill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: SizedBox(
            height: 38,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final tool in VideoAddTool.values) ...[
                  if (tool != VideoAddTool.text) const SizedBox(width: 3),
                  Expanded(child: _tab(tool)),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _tab(VideoAddTool tool) {
    final selected = tool == _tool;
    final dotted = _editor.document.hasTool(tool);
    final label = switch (tool) {
      VideoAddTool.text => 'Text',
      VideoAddTool.sticker => 'Sticker',
      VideoAddTool.emoji => 'Emoji',
      VideoAddTool.draw => 'Draw',
    };
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        elevation: selected ? 1 : 0,
        shadowColor: const Color(0x24000000),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: () => _setTool(tool),
          borderRadius: BorderRadius.circular(9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? VideoAddPalette.ink : VideoAddPalette.secondary,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotted ? VideoAddPalette.accent : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions() => Row(
        children: [
          Expanded(
            child: AppButton(
              title: 'Cancel',
              type: ButtonType.secondary,
              height: 48,
              borderColor: const Color(0xFFCFCFD8),
              textColor: VideoAddPalette.ink,
              onPress: () => unawaited(_close()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(
              title: 'Done',
              height: 48,
              isDisable: !_editor.hasContent || _saving,
              backgroundColor: _editor.hasContent && !_saving
                  ? VideoAddPalette.accent
                  : VideoAddPalette.disabled,
              textColor: Colors.white,
              onPress: () => unawaited(_apply()),
            ),
          ),
        ],
      );

  Widget _encodingOverlay() => ColoredBox(
        color: Colors.white.withValues(alpha: 0.86),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Applying additions',
                  style: TextStyle(
                    color: VideoAddPalette.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _encodeProgress <= 0 ? null : _encodeProgress,
                  color: VideoAddPalette.accent,
                  backgroundColor: VideoAddPalette.track,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_encodeProgress * 100).round()}%',
                  style: const TextStyle(color: VideoAddPalette.secondary),
                ),
              ],
            ),
          ),
        ),
      );
}

class _EmojiCategories extends SliverPersistentHeaderDelegate {
  _EmojiCategories({required this.selected, required this.onSelect});

  final ValueChanged<int> onSelect;
  final int selected;

  @override
  double get maxExtent => 44;

  @override
  double get minExtent => 44;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(
        color: Colors.white,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: VideoAddPalette.disabled)),
          ),
          child: Row(
            children: [
              for (var index = 0; index < VideoAddCatalog.categories.length; index++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: index == selected,
                    label: VideoAddCatalog.categories[index].name,
                    child: IconButton(
                      tooltip: VideoAddCatalog.categories[index].name,
                      onPressed: () => onSelect(index),
                      color: index == selected
                          ? VideoAddPalette.accent
                          : VideoAddPalette.secondary,
                      icon: Icon(VideoAddCatalog.categories[index].icon),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  @override
  bool shouldRebuild(covariant _EmojiCategories oldDelegate) =>
      oldDelegate.selected != selected;
}

class _DiscardSheet extends StatelessWidget {
  const _DiscardSheet();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: VideoAddPalette.track,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Discard changes?',
              style: TextStyle(
                color: VideoAddPalette.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Your edits won't be applied to the video.",
              style: TextStyle(color: VideoAddPalette.secondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            AppButton(
              title: 'Keep editing',
              height: 48,
              backgroundColor: VideoAddPalette.accent,
              textColor: Colors.white,
              onPress: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 10),
            AppButton(
              title: 'Discard',
              type: ButtonType.secondary,
              height: 48,
              borderColor: const Color(0xFFCFCFD8),
              textColor: VideoAddPalette.destructive,
              onPress: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );
}

enum _TextColorTarget {
  text,
  background,
  shadow;

  String get chipLabel => switch (this) {
        text => 'Text',
        background => 'Background',
        shadow => 'Shadow',
      };

  String get popupLabel => switch (this) {
        text => 'Text color',
        background => 'Background',
        shadow => 'Shadow',
      };

  /// Horizontal alignment of the popup arrow, from -1 to 1.
  double get arrow => switch (this) {
        text => -0.666,
        background => 0,
        shadow => 0.666,
      };
}

class _MoreSwatch extends StatelessWidget {
  const _MoreSwatch();

  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Color(0xFFF43F5E),
              Color(0xFFF59E0B),
              Color(0xFFEAB308),
              Color(0xFF22C55E),
              Color(0xFF06B6D4),
              Color(0xFF3B82F6),
              Color(0xFF8B5CF6),
              Color(0xFFF43F5E),
            ],
          ),
        ),
        child: const DecoratedBox(
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: SizedBox(
            width: 20,
            height: 20,
            child: Center(
              child: Text(
                '+',
                style: TextStyle(
                  color: VideoAddPalette.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      );
}
