import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_selection/model/media_asset_data.dart';
import 'package:ism_video_reel_player/presentation/screens/widgets/app_image.dart';
import 'package:photo_manager/photo_manager.dart' as pm;

typedef AssetThumbnailLoader = Future<Uint8List?> Function(
  pm.AssetEntity asset, {
  int size,
});

class AssetThumbnailWidget extends StatefulWidget {
  const AssetThumbnailWidget({
    super.key,
    required this.mediaData,
    required this.loadThumbnail,
    this.thumbnailSize = 300,
    this.loadingColor = Colors.grey,
    this.placeholderColor,
  });

  final MediaAssetData mediaData;
  final AssetThumbnailLoader loadThumbnail;
  final int thumbnailSize;
  final Color loadingColor;
  final Color? placeholderColor;

  @override
  State<AssetThumbnailWidget> createState() => _AssetThumbnailWidgetState();
}

class _AssetThumbnailWidgetState extends State<AssetThumbnailWidget> {
  Future<Uint8List?>? _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _resolveThumbnailFuture();
  }

  @override
  void didUpdateWidget(covariant AssetThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaData.assetId != widget.mediaData.assetId) {
      _thumbnailFuture = _resolveThumbnailFuture();
    }
  }

  Future<Uint8List?>? _resolveThumbnailFuture() {
    final entity = widget.mediaData.assetEntity;
    if (entity != null) {
      return widget.loadThumbnail(entity, size: widget.thumbnailSize);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final entity = widget.mediaData.assetEntity;
    if (entity != null) {
      return FutureBuilder<Uint8List?>(
        future: _thumbnailFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
            );
          }

          return _placeholder();
        },
      );
    }

    final thumbnailPath = widget.mediaData.thumbnailPath;
    if (thumbnailPath?.isNotEmpty == true) {
      return AppImage.file(
        thumbnailPath!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    final localPath = widget.mediaData.localPath;
    if (localPath?.isNotEmpty == true) {
      return AppImage.file(
        localPath!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return _placeholder();
  }

  Widget _placeholder() => ColoredBox(
        color: widget.placeholderColor ?? Colors.grey.shade200,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.loadingColor,
            ),
          ),
        ),
      );
}
