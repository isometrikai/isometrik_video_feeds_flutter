import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/core/models/video/trim_duration_span_model.dart';
import 'package:pro_image_editor/shared/utils/debounce.dart';
import 'package:pro_image_editor/shared/utils/platform_info.dart';
import 'package:pro_image_editor/shared/widgets/video/trimmer/video_editor_play_time_indicator.dart';
import 'package:pro_image_editor/shared/widgets/video/trimmer/video_editor_trim_handle.dart';
import 'package:pro_image_editor/shared/widgets/video/trimmer/video_editor_trim_thumbnail_bar.dart';
import 'package:pro_image_editor/shared/widgets/video/video_editor_configurable.dart';

/// Trim bar with auto-zoom and larger touch targets for short clips (e.g. 15s).
class IsrVideoEditorTrimBar extends StatefulWidget {
  const IsrVideoEditorTrimBar({super.key, this.initialTrimSpan});

  final TrimDurationSpan? initialTrimSpan;

  @override
  State<IsrVideoEditorTrimBar> createState() => _IsrVideoEditorTrimBarState();
}

class _IsrVideoEditorTrimBarState extends State<IsrVideoEditorTrimBar> {
  static const double _handleTouchWidth = 48;
  static const double _targetTrimViewportFraction = 0.58;

  double _trimStart = 0;
  double _trimEnd = 1;
  double _scale = 1;
  double _baseScale = 1;
  final _scrollCtrl = ScrollController();
  final _trimTimeDebounce = Debounce(const Duration(milliseconds: 350));

  VideoEditorConfigurable get _player => VideoEditorConfigurable.of(context);

  int get _videoDuration => _player.controller.videoDuration.inMicroseconds;

  double get _minTrimPercentage {
    if (_videoDuration <= 0) return 1;
    return min(
      _player.configs.minTrimDuration.inMicroseconds / _videoDuration,
      1.0,
    );
  }

  double get _maxTrimPercentage {
    if (_videoDuration <= 0) return 1;
    final maxTrimDurationMs =
        _player.configs.maxTrimDuration?.inMicroseconds ?? _videoDuration;
    return min(maxTrimDurationMs / _videoDuration, 1.0);
  }

  double _safeClamp(double value, double lower, double upper) {
    if (lower > upper) return lower;
    return value.clamp(lower, upper);
  }

  bool _isUpdatingTrimBar = false;

  final _leftHandlerActiveNotifier = ValueNotifier(false);
  final _rightHandlerActiveNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyInitialTrimSpan();

      final trimBarWidth = MediaQuery.sizeOf(context).width - 32;
      if (trimBarWidth > 0) {
        _autoFitScaleForShortClips(trimBarWidth);
      }

      setState(() {});

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (trimBarWidth > 0) {
          _centerScrollOnTrimSelection(trimBarWidth);
        }
      });
    });
  }

  void _applyInitialTrimSpan() {
    if (_videoDuration <= 0) {
      _trimStart = 0;
      _trimEnd = 1;
      return;
    }

    final initial =
        widget.initialTrimSpan ?? _player.controller.initialTrimSpan;
    if (initial == null) {
      _trimStart = 0;
      _trimEnd = _maxTrimPercentage;
    } else {
      final startUs = initial.start.inMicroseconds.toDouble();
      final endUs = initial.end.inMicroseconds.toDouble();

      _trimStart = startUs / _videoDuration;
      _trimEnd = endUs / _videoDuration;

      _trimStart = _safeClamp(_trimStart, 0, 1 - _minTrimPercentage);
      _trimEnd = _safeClamp(
        _trimEnd,
        _trimStart + _minTrimPercentage,
        1,
      );

      final spanDuration = _trimEnd - _trimStart;
      if (spanDuration > _maxTrimPercentage) {
        _trimEnd = _trimStart + _maxTrimPercentage;
      }
    }

    _updateTrimSpan(markIsUpdating: false);
  }

  void _autoFitScaleForShortClips(double trimBarWidth) {
    if (_videoDuration <= 0 || trimBarWidth <= 0) return;

    final trimFraction = (_trimEnd - _trimStart).clamp(0.001, 1.0);
    if (trimFraction >= _targetTrimViewportFraction) return;

    final neededScale = _targetTrimViewportFraction / trimFraction;
    _scale = _safeClamp(
      neededScale,
      _player.configs.trimBarMinScale,
      _player.configs.trimBarMaxScale,
    );
  }

  void _centerScrollOnTrimSelection(double trimBarWidth) {
    if (!_scrollCtrl.hasClients) return;
    final scaledWidth = trimBarWidth * _scale;
    final selectionCenter = ((_trimStart + _trimEnd) / 2) * scaledWidth;
    final maxExtent = _scrollCtrl.position.maxScrollExtent;
    if (!maxExtent.isFinite || maxExtent < 0) return;
    final targetOffset = _safeClamp(
      selectionCenter - trimBarWidth / 2,
      0,
      maxExtent,
    );
    _scrollCtrl.jumpTo(targetOffset);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _trimTimeDebounce.dispose();
    _leftHandlerActiveNotifier.dispose();
    _rightHandlerActiveNotifier.dispose();
    super.dispose();
  }

  void _updateTrimSpan({
    TrimDurationSpan? timeSpan,
    bool markIsUpdating = true,
  }) {
    final startTime = Duration(
      microseconds: (_trimStart * _videoDuration).round(),
    );
    final endTime = Duration(microseconds: (_trimEnd * _videoDuration).round());

    final span = timeSpan ??
        TrimDurationSpan(
          start: Duration(seconds: startTime.inSeconds),
          end: Duration(seconds: endTime.inSeconds),
        );

    _player.controller.setTrimSpan(span);
    if (markIsUpdating) {
      _player.showTrimTimeSpanNotifier.value = true;
      _isUpdatingTrimBar = true;
    }
    setState(() {});
  }

  void _updateTrimStart(double value) {
    _trimStart = _safeClamp(
      value,
      _trimEnd - _maxTrimPercentage,
      _trimEnd - _minTrimPercentage,
    );
    _updateTrimSpan();
  }

  void _updateTrimEnd(double value) {
    _trimEnd = _safeClamp(
      value,
      _trimStart + _minTrimPercentage,
      _trimStart + _maxTrimPercentage,
    );
    _updateTrimSpan();
  }

  void _updateScrollbar(double value) {
    if (!_scrollCtrl.hasClients) return;
    final maxExtent = _scrollCtrl.position.maxScrollExtent;
    if (!maxExtent.isFinite || maxExtent < 0) return;
    _scrollCtrl.jumpTo(
      _safeClamp(_scrollCtrl.offset - value, 0, maxExtent),
    );
  }

  void _updateDragTrimBar(DragUpdateDetails details, double scaledWidth) {
    final delta = details.primaryDelta;
    if (delta == null || scaledWidth <= 0) return;
    final factor = delta / scaledWidth;
    final controller = _player.controller;

    var newValueStart = _trimStart + factor;
    var newValueEnd = _trimEnd + factor;
    final diff = _trimEnd - _trimStart;

    if (newValueStart < 0) {
      newValueStart = 0;
      newValueEnd = diff;
    } else if (newValueEnd > 1) {
      newValueStart = 1 - diff;
      newValueEnd = 1;
    }

    _trimStart = newValueStart;
    _trimEnd = newValueEnd;
    final start = Duration(microseconds: (_trimStart * _videoDuration).round());
    final end = start + controller.endTime - controller.startTime;

    _updateTrimSpan(timeSpan: TrimDurationSpan(start: start, end: end));
  }

  void _triggerTrimSpanEnd() {
    _player.callbacks.onTrimSpanEnd?.call(
      TrimDurationSpan(
        start: Duration(microseconds: (_trimStart * _videoDuration).toInt()),
        end: Duration(microseconds: (_trimEnd * _videoDuration).toInt()),
      ),
    );
    _isUpdatingTrimBar = false;
    _trimTimeDebounce(() {
      _player.showTrimTimeSpanNotifier.value = false;
    });
    setState(() {});
  }

  void _handleMouseScroll(PointerSignalEvent event, double trimBarWidth) {
    if (event is! PointerScrollEvent || !_scrollCtrl.hasClients) return;

    final factor = 0.05 * (event.scrollDelta.dy / 50).abs().clamp(0.5, 2);
    final deltaY =
        event.scrollDelta.dy * (_player.configs.trimBarInvertMouseScroll ? -1 : 1);

    final startZoom = _scale;
    var newZoom = _scale;

    if (deltaY > 0) {
      newZoom -= factor;
      newZoom = max(_player.configs.trimBarMinScale, newZoom);
    } else if (deltaY < 0) {
      newZoom += factor;
      newZoom = min(_player.configs.trimBarMaxScale, newZoom);
    }

    final mouseX = event.localPosition.dx;
    final scaledWidth = trimBarWidth * startZoom;
    final newScaledWidth = trimBarWidth * newZoom;
    final mousePositionPercent = (mouseX + _scrollCtrl.offset) / scaledWidth;
    final newScrollOffset = (mousePositionPercent * newScaledWidth) - mouseX;
    final maxExtent = _scrollCtrl.position.maxScrollExtent;
    if (!maxExtent.isFinite || maxExtent < 0) return;
    final clampedScrollOffset = _safeClamp(newScrollOffset, 0, maxExtent);

    setState(() => _scale = newZoom);
    _scrollCtrl.jumpTo(clampedScrollOffset);
  }

  @override
  Widget build(BuildContext context) {
    final style = _player.style;
    final handlerButtonSize = style.trimBarHandlerButtonSize;

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (_, constraints) {
          final trimBarWidth = max(0.0, constraints.maxWidth - 16);
          final scaledWidth = max(trimBarWidth * _scale, trimBarWidth);
          final trimWidth = (_trimEnd - _trimStart) * scaledWidth;
          final offsetLeftHandler = _trimStart * scaledWidth;

          final minTrimWidthForHandlers = max(
            style.trimBarHandlerWidth + 4,
            _handleTouchWidth,
          );
          final effectiveTrimWidth = max(trimWidth, minTrimWidthForHandlers);

          final offsetRightHandler = offsetLeftHandler +
              effectiveTrimWidth -
              style.trimBarHandlerWidth;

          return SingleChildScrollView(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Listener(
              onPointerSignal: (ev) => _handleMouseScroll(ev, trimBarWidth),
              child: GestureDetector(
                onScaleStart: (_) => _baseScale = _scale,
                onScaleUpdate: (details) {
                  _scale = _safeClamp(
                    _baseScale * details.scale,
                    _player.configs.trimBarMinScale,
                    _player.configs.trimBarMaxScale,
                  );
                  setState(() {});
                },
                child: Container(
                  clipBehavior: Clip.none,
                  width: scaledWidth,
                  padding: const EdgeInsets.only(top: 8),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: handlerButtonSize,
                        ),
                        child: GestureDetector(
                          onHorizontalDragEnd:
                              !isDesktop ? null : (_) => _triggerTrimSpanEnd(),
                          onHorizontalDragUpdate: !isDesktop
                              ? null
                              : (details) => _updateScrollbar(details.delta.dx),
                          child: const VideoEditorTrimThumbnailBar(),
                        ),
                      ),
                      ..._buildOutsideShadows(
                        offsetLeftHandler,
                        offsetRightHandler,
                        scaledWidth,
                        handlerButtonSize,
                      ),
                      _buildTrimBodyArea(
                        offsetLeftHandler + handlerButtonSize,
                        offsetRightHandler - handlerButtonSize,
                        scaledWidth,
                        effectiveTrimWidth,
                      ),
                      _buildResizeHandler(true, offsetLeftHandler, scaledWidth),
                      _buildResizeHandler(
                        false,
                        offsetRightHandler,
                        scaledWidth,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildOutsideShadows(
    double offsetLeftHandler,
    double offsetRightHandler,
    double scaledWidth,
    double handlerButtonSize,
  ) {
    final radiusWidth = _player.style.trimBarHandlerRadius;
    return [
      Positioned(
        left: handlerButtonSize,
        width: max(0.0, offsetLeftHandler + radiusWidth),
        height: _player.style.trimBarHeight,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: _player.style.trimBarOutsideAreaBackground,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(_player.style.trimBarHandlerRadius),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: offsetRightHandler + handlerButtonSize,
        width: max(
          0.0,
          scaledWidth - offsetRightHandler - handlerButtonSize * 2,
        ),
        height: _player.style.trimBarHeight,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: _player.style.trimBarOutsideAreaBackground,
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(_player.style.trimBarHandlerRadius),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildTrimBodyArea(
    double offsetLeftHandler,
    double offsetRightHandler,
    double scaledWidth,
    double trimWidth,
  ) {
    final bodyWidth = max(
      0.0,
      offsetRightHandler -
          offsetLeftHandler +
          _player.style.trimBarHandlerWidth,
    );
    return Positioned(
      left: offsetLeftHandler,
      width: bodyWidth,
      child: Stack(
        children: [
          if (!_isUpdatingTrimBar)
            VideoEditorPlayTimeIndicator(areaWidth: trimWidth),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (_) => _triggerTrimSpanEnd(),
            onHorizontalDragUpdate: (details) =>
                _updateDragTrimBar(details, scaledWidth),
            child: MouseRegion(
              cursor: SystemMouseCursors.move,
              child: Container(
                width: trimWidth,
                height: _player.style.trimBarHeight,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _player.style.trimBarBackground,
                    width: _player.style.trimBarBorderWidth,
                  ),
                  borderRadius: BorderRadius.circular(
                    _player.style.trimBarHandlerRadius,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResizeHandler(bool isLeft, double offset, double scaledWidth) {
    final notifier =
        isLeft ? _leftHandlerActiveNotifier : _rightHandlerActiveNotifier;
    final handlerWidth = _player.style.trimBarHandlerWidth;
    final touchPadding = max(0.0, (_handleTouchWidth - handlerWidth) / 2);

    return Positioned(
      left: offset - touchPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => notifier.value = true,
        onHorizontalDragUpdate: (details) {
          final delta = details.primaryDelta;
          if (delta == null) return;
          if (isLeft) {
            final newValue = _trimStart + delta / scaledWidth;
            _updateTrimStart(max(0, newValue));
          } else {
            final newValue = _trimEnd + delta / scaledWidth;
            _updateTrimEnd(min(1, newValue));
          }
        },
        onHorizontalDragEnd: (_) {
          _triggerTrimSpanEnd();
          notifier.value = false;
        },
        child: SizedBox(
          width: _handleTouchWidth,
          height: _player.style.trimBarHeight + 16,
          child: Center(
            child: ValueListenableBuilder(
              valueListenable: notifier,
              builder: (_, value, __) {
                return VideoEditorTrimHandle(
                  isSelected: value,
                  isLeft: isLeft,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
