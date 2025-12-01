import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:photo_manager/photo_manager.dart' as pm;

import '../media_selection.dart';

class MediaGridItemWidget extends StatelessWidget {
  const MediaGridItemWidget({
    super.key,
    required this.mediaSelectionConfig,
    required this.asset,
    required this.isSelected,
    required this.selectedIndex,
    required this.isMultiSelectMode,
    required this.onTap,
    required this.onDeselect,
  });

  final MediaSelectionConfig mediaSelectionConfig;
  final pm.AssetEntity asset;
  final bool isSelected;
  final int selectedIndex;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onDeselect;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          // Main media content
          GestureDetector(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildMediaContent(),
                if (asset.type == pm.AssetType.video) _buildVideoDuration(),
                if (isSelected) _buildSelectionOverlay(),
              ],
            ),
          ),

          // Selection indicator
          if (isSelected) _buildSelectionIndicator(),
        ],
      );

  Widget _buildMediaContent() => FutureBuilder<File?>(
        future: asset.file,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            final file = snapshot.data!;
            final isVideo = asset.type == pm.AssetType.video;

            if (isVideo) {
              return FutureBuilder<String?>(
                future: _getVideoThumbnail(file.path),
                builder: (context, thumbnailSnapshot) {
                  if (thumbnailSnapshot.hasData &&
                      thumbnailSnapshot.data != null) {
                    return Image.file(
                      File(thumbnailSnapshot.data!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildVideoPlaceholder(),
                    );
                  }
                  return _buildVideoPlaceholder();
                },
              );
            }

            return Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) =>
                  _buildImagePlaceholder(),
            );
          }

          return _buildLoadingState();
        },
      );

  Widget _buildVideoDuration() => Positioned(
        bottom: 4,
        right: 4,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _formatDuration(asset.duration),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ),
      );

  Widget _buildSelectionOverlay() => Container(
        color: Colors.white.withValues(alpha: 0.3),
      );

  Widget _buildSelectionIndicator() => Positioned(
        top: 4,
        right: 4,
        child: GestureDetector(
          onTap: onDeselect,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: mediaSelectionConfig.primaryColor,
              shape: isMultiSelectMode ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isMultiSelectMode ? null : BorderRadius.circular(4),
            ),
            child: Center(
              child: isMultiSelectMode
                  ? Text(
                      '${selectedIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
            ),
          ),
        ),
      );

  Widget _buildVideoPlaceholder() => Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(Icons.video_library, color: Colors.white),
        ),
      );

  Widget _buildImagePlaceholder() => Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(Icons.image, color: Colors.white),
        ),
      );

  Widget _buildLoadingState() => Container(
        color: Colors.grey[800],
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

  Future<String?> _getVideoThumbnail(String videoPath) async {
    try {
      final thumbnailFile = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await Directory.systemTemp.createTemp()).path,
        quality: 50,
      );
      return thumbnailFile.path;
    } catch (e) {
      return null;
    }
  }

  String _formatDuration(int duration) {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
