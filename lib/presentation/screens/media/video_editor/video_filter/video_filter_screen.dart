import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_filter/video_filter_draft.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_filter/video_filter_look.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/app_button.dart';
import 'package:ism_video_reel_player/utils/enums.dart';
import 'package:ism_video_reel_player/utils/ffmpeg_media_ops.dart';
import 'package:video_player/video_player.dart';

const _textColor = Color(0xFF1C1C22);
const _secondaryText = Color(0xFF5E5E69);
const _accent = Color(0xFF6D4AFF);
const _track = Color(0xFFDADAE1);
const _disabledFill = Color(0xFFE4E4EA);

/// Filter, tune, and blur for one video. Done returns the draft.
class VideoFilterScreen extends StatefulWidget {
  const VideoFilterScreen({
    super.key,
    required this.videoPath,
    this.initial = VideoFilterDraft.neutral,
  });

  final VideoFilterDraft initial;
  final String videoPath;

  @override
  State<VideoFilterScreen> createState() => _VideoFilterScreenState();
}

class _VideoFilterScreenState extends State<VideoFilterScreen> {
  late final VideoPlayerController _controller;
  late VideoFilterDraft _draft;
  late final VideoFilterDraft _opened;
  var _tool = VideoFilterTool.filter;
  var _tune = VideoTuneControl.brightness;
  var _dragging = false;
  var _playing = false;
  var _ready = false;
  var _saving = false;
  var _encodeProgress = 0.0;
  String? _stillPath;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _opened = widget.initial;
    _controller = VideoPlayerController.file(File(widget.videoPath));
    unawaited(_open());
  }

  @override
  void dispose() {
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
      final still = await FfmpegMediaOps.thumbnail(
        video: widget.videoPath,
        outputPath:
            '${Directory.systemTemp.path}/filter_still_${DateTime.now().microsecondsSinceEpoch}.jpg',
        timeMs: 400,
        quality: 70,
        maxWidth: 160,
      );
      if (!mounted) return;
      setState(() {
        _ready = _controller.value.isInitialized;
        _stillPath = still;
      });
    } catch (_) {
      if (mounted) setState(() => _ready = false);
    }
  }

  void _onPlayback() {
    final playing = _controller.value.isPlaying;
    if (playing == _playing || !mounted) return;
    setState(() => _playing = playing);
  }

  bool get _hasChanges => _draft.differsFrom(_opened);

  Future<void> _close() async {
    if (!_hasChanges) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _DiscardChangesSheet(),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _apply() async {
    if (!_hasChanges || _saving) return;
    if (_playing) await _controller.pause();
    final filter = VideoFilterLook.fromDraft(_draft).ffmpegVideoFilter;
    if (filter == null) {
      if (!mounted) return;
      Navigator.of(context).pop(
        VideoFilterExport(
          baked: false,
          inputPath: widget.videoPath,
          outputPath: widget.videoPath,
          settings: VideoFilterDraft.neutral,
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _encodeProgress = 0;
    });
    final output = await FfmpegMediaOps.encodeVideoFilter(
      inputPath: widget.videoPath,
      videoFilter: filter,
      onProgress: (value) {
        if (!mounted) return;
        setState(() => _encodeProgress = value);
      },
    );
    if (!mounted) return;
    if (output == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not apply the filter')),
      );
      return;
    }
    Navigator.of(context).pop(
      VideoFilterExport(
        baked: true,
        inputPath: widget.videoPath,
        outputPath: output,
        settings: _draft,
      ),
    );
  }

  void _togglePlay() {
    if (!_ready) return;
    if (_playing) {
      unawaited(_controller.pause());
    } else {
      unawaited(_controller.play());
    }
  }

  @override
  Widget build(BuildContext context) {
    final look = VideoFilterLook.fromDraft(_draft);
    return PopScope(
      canPop: !_hasChanges && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (_saving || didPop) return;
        unawaited(_close());
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(child: _preview(look)),
                  SizedBox(height: 144, child: _toolBody()),
                  _toolSwitcher(),
                  _actions(),
                ],
              ),
              if (_saving) _encodingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview(VideoFilterLook look) => LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth - 32;
          final maxHeight = constraints.maxHeight - 16;
          var width = maxWidth;
          var height = width * 16 / 9;
          if (height > maxHeight) {
            height = maxHeight;
            width = height * 9 / 16;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: const Color(0xFF111111),
                        child: _ready
                            ? applyVideoFilterLook(
                                look: look,
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _controller.value.size.width,
                                    height: _controller.value.size.height,
                                    child: VideoPlayer(_controller),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: _playButton(),
                      ),
                    ],
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
          color: Colors.black.withValues(alpha: 0.45),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _togglePlay,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                _playing ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );

  Widget _toolBody() => switch (_tool) {
        VideoFilterTool.filter => _filterTool(),
        VideoFilterTool.tune => _tuneTool(),
        VideoFilterTool.blur => _blurTool(),
      };

  Widget _filterTool() {
    final original = _draft.theme == VideoFilterTheme.original;
    return Column(
      children: [
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: VideoFilterTheme.values.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final theme = VideoFilterTheme.values[index];
              return _ThemeChip(
                theme: theme,
                stillPath: _stillPath,
                selected: theme == _draft.theme,
                onTap: () => setState(() => _draft = _draft.withTheme(theme)),
              );
            },
          ),
        ),
        _slider(
          label: 'Level',
          value: _draft.level.toDouble(),
          min: 0,
          max: 100,
          enabled: !original,
          valueLabel: '${_draft.level}',
          onChanged: (value) =>
              setState(() => _draft = _draft.copyWith(level: value.round())),
        ),
      ],
    );
  }

  Widget _tuneTool() => Column(
        children: [
          SizedBox(
            height: 64,
            child: Row(
              children: [
                for (final control in VideoTuneControl.values)
                  Expanded(
                    child: _TuneChip(
                      control: control,
                      value: _draft.tuneValue(control),
                      selected: control == _tune,
                      emphasized: _dragging && control == _tune,
                      onTap: () => setState(() => _tune = control),
                    ),
                  ),
              ],
            ),
          ),
          _slider(
            label: _tune.label,
            value: _draft.tuneValue(_tune).toDouble(),
            min: -100,
            max: 100,
            enabled: true,
            valueLabel: videoFilterSignedValue(_draft.tuneValue(_tune)),
            centerTick: true,
            onChanged: (value) => setState(
              () => _draft = _draft.withTune(_tune, value.round()),
            ),
          ),
        ],
      );

  Widget _blurTool() => Column(
        children: [
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('None', style: TextStyle(color: _secondaryText, fontSize: 12)),
                const Spacer(),
                Text(
                  '${_draft.blur}',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: _dragging ? 18 : 13,
                    fontWeight: _dragging ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Text('Strong', style: TextStyle(color: _secondaryText, fontSize: 12)),
              ],
            ),
          ),
          _slider(
            label: 'Blur',
            value: _draft.blur.toDouble(),
            min: 0,
            max: 100,
            enabled: true,
            showValue: false,
            onChanged: (value) =>
                setState(() => _draft = _draft.copyWith(blur: value.round())),
          ),
        ],
      );

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required bool enabled,
    required ValueChanged<double> onChanged,
    String? valueLabel,
    bool showValue = true,
    bool centerTick = false,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (showValue)
              SizedBox(
                width: 64,
                child: Text(
                  valueLabel ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: enabled ? _textColor : _secondaryText,
                    fontSize: _dragging ? 18 : 13,
                    fontWeight: _dragging ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            Expanded(
              child: Semantics(
                label: label,
                value: value.round().toString(),
                slider: true,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: _accent,
                    inactiveTrackColor: _track,
                    thumbColor: _accent,
                    disabledActiveTrackColor: _track,
                    disabledInactiveTrackColor: _track,
                    disabledThumbColor: _track,
                    overlayColor: _accent.withValues(alpha: 0.22),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Slider(
                        value: value.clamp(min, max),
                        min: min,
                        max: max,
                        divisions: (max - min).round(),
                        onChangeStart: enabled
                            ? (value) => setState(() => _dragging = true)
                            : null,
                        onChangeEnd: enabled
                            ? (value) => setState(() => _dragging = false)
                            : null,
                        onChanged: enabled ? onChanged : null,
                      ),
                      if (centerTick)
                        const IgnorePointer(
                          child: SizedBox(
                            width: 2,
                            height: 12,
                            child: ColoredBox(color: _secondaryText),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _toolSwitcher() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              for (final tool in VideoFilterTool.values)
                Expanded(
                  child: _ToolTab(
                    tool: tool,
                    selected: tool == _tool,
                    edited: _draft.hasEdits(tool),
                    onTap: () => setState(() => _tool = tool),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _actions() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                title: 'Cancel',
                type: ButtonType.secondary,
                height: 48,
                borderColor: _track,
                textColor: _textColor,
                onPress: () => unawaited(_close()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                title: 'Done',
                height: 48,
                isDisable: !_hasChanges || _saving,
                backgroundColor: _hasChanges ? _accent : _disabledFill,
                textColor: Colors.white,
                onPress: () => unawaited(_apply()),
              ),
            ),
          ],
        ),
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
                  'Applying filter',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _encodeProgress <= 0 ? null : _encodeProgress,
                  color: _accent,
                  backgroundColor: _track,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_encodeProgress * 100).round()}%',
                  style: const TextStyle(color: _secondaryText),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Paints [child] with [look]: color matrix, then blur.
Widget applyVideoFilterLook({
  required VideoFilterLook look,
  required Widget child,
}) {
  final colored = ColorFiltered(
    colorFilter: ColorFilter.matrix(look.matrix),
    child: child,
  );
  if (look.blurSigma <= 0) return colored;
  return ClipRect(
    child: Transform.scale(
      scale: look.coverScale,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: look.blurSigma,
          sigmaY: look.blurSigma,
          tileMode: TileMode.clamp,
        ),
        child: colored,
      ),
    ),
  );
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.theme,
    required this.selected,
    required this.onTap,
    this.stillPath,
  });

  final VoidCallback onTap;
  final bool selected;
  final String? stillPath;
  final VideoFilterTheme theme;

  @override
  Widget build(BuildContext context) {
    final look = VideoFilterLook.fromDraft(
      VideoFilterDraft(
        theme: theme,
        level: theme == VideoFilterTheme.original ? 0 : 100,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: theme.label,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? _accent : Colors.transparent,
                    width: 2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: applyVideoFilterLook(
                  look: look,
                  child: stillPath == null
                      ? const ColoredBox(color: Color(0xFFB9B9C2))
                      : Image.file(File(stillPath!), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                theme.label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? _accent : _secondaryText,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TuneChip extends StatelessWidget {
  const _TuneChip({
    required this.control,
    required this.value,
    required this.selected,
    required this.emphasized,
    required this.onTap,
  });

  final VideoTuneControl control;
  final bool emphasized;
  final VoidCallback onTap;
  final bool selected;
  final int value;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: control.label,
        value: videoFilterSignedValue(value),
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                control.label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? _accent : _secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                videoFilterSignedValue(value),
                style: TextStyle(
                  color: _textColor,
                  fontSize: emphasized ? 18 : 13,
                  fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ToolTab extends StatelessWidget {
  const _ToolTab({
    required this.tool,
    required this.selected,
    required this.edited,
    required this.onTap,
  });

  final bool edited;
  final VoidCallback onTap;
  final bool selected;
  final VideoFilterTool tool;

  String get _label => switch (tool) {
        VideoFilterTool.filter => 'Filter',
        VideoFilterTool.tune => 'Tune',
        VideoFilterTool.blur => 'Blur',
      };

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: _label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: selected ? Border.all(color: const Color(0xFFE7E7EE)) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _label,
                    style: TextStyle(
                      color: selected ? _textColor : _secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (edited) ...[
                    const SizedBox(width: 6),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 6, height: 6),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

class _DiscardChangesSheet extends StatelessWidget {
  const _DiscardChangesSheet();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _track,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Discard changes?',
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your edits won't be applied to the video.",
              style: TextStyle(color: _secondaryText, fontSize: 14),
            ),
            const SizedBox(height: 20),
            AppButton(
              title: 'Keep editing',
              height: 48,
              backgroundColor: _accent,
              textColor: Colors.white,
              onPress: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              child: const Text(
                'Discard',
                style: TextStyle(color: Color(0xFFD92D20), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}
