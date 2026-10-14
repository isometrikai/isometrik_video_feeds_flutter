import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_add/video_add_canvas.dart';
import 'package:ism_video_reel_player/presentation/screens/media/video_editor/video_add/video_add_draft.dart';

/// Renders [document] at the video's pixel size into a transparent PNG.
///
/// Positions match the on-screen overlay, which uses the same 0–1 coordinates.
Future<Uint8List?> rasterizeVideoAddPng({
  required BuildContext context,
  required VideoAddDocument document,
  required int width,
  required int height,
}) async {
  if (!context.mounted || width <= 0 || height <= 0) return null;
  await _precacheStickers(context, document);
  if (!context.mounted) return null;

  final key = GlobalKey();
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 0,
      top: 0,
      width: 1,
      height: 1,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.01,
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width.toDouble(),
            maxWidth: width.toDouble(),
            minHeight: height.toDouble(),
            maxHeight: height.toDouble(),
            child: RepaintBoundary(
              key: key,
              child: MediaQuery(
                data: MediaQuery.of(context),
                child: SizedBox(
                  width: width.toDouble(),
                  height: height.toDouble(),
                  child: VideoAddOverlay(document: document),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
  try {
    final frames = document.items.any(
      (item) => item.type == VideoAddItemType.sticker && item.assetPath.isNotEmpty,
    )
        ? 8
        : 3;
    for (var frame = 0; frame < frames; frame++) {
      await WidgetsBinding.instance.endOfFrame;
    }
    final render = key.currentContext?.findRenderObject();
    if (render is! RenderRepaintBoundary || !render.hasSize || render.size.isEmpty) {
      return null;
    }
    final image = await render.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return null;
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    entry.remove();
  }
}

Future<void> _precacheStickers(BuildContext context, VideoAddDocument document) async {
  for (final item in document.items) {
    if (item.type != VideoAddItemType.sticker || item.assetPath.isEmpty) continue;
    final asset = item.assetPath;
    if (asset.toLowerCase().endsWith('.png')) {
      await precacheImage(AssetImage(asset), context);
    } else {
      final picture = await vg.loadPicture(SvgAssetLoader(asset), context);
      picture.picture.dispose();
    }
  }
}
