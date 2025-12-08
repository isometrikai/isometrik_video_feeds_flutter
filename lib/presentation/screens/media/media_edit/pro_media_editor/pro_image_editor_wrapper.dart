import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/media_edit_config.dart';
import 'package:ism_video_reel_player/presentation/screens/media/media_edit/pro_media_editor/pro_media_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
// import '../../custom_pro_image_editor/pro_image_editor.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

class ProImageEditorWrapper extends StatefulWidget {
  const ProImageEditorWrapper({
    super.key,
    required this.mediaPath,
    required this.mediaEditConfig,
    this.title,
    this.filename,
    this.editingMode,
    this.saveLocally = false, // Default to temp save
  });

  final String mediaPath;
  final MediaEditConfig mediaEditConfig;
  final String? title;
  final String? filename;
  final String? editingMode; // 'text', 'filter', 'adjustment'
  final bool saveLocally; // true = save locally, false = save in temp/cache

  @override
  State<ProImageEditorWrapper> createState() => _ProImageEditorWrapperState();
}

class _ProImageEditorWrapperState extends State<ProImageEditorWrapper> {
  bool _hasNavigated = false;

  void _navigateBack(Map<String, dynamic> result) {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) => _buildImageEditor();

  Widget _buildImageEditor() => Scaffold(
        body: FutureBuilder<Uint8List>(
          future: File(widget.mediaPath).readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading image: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _navigateBack({
                        'success': false,
                        'error': 'Failed to load image',
                      }),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            return ProImageEditor.file(
              widget.mediaPath,
              configs: _getEditorConfigs(),
              callbacks: ProImageEditorCallbacks(
                onImageEditingStarted: () {
                  debugPrint('Image editing started');
                },
                onImageEditingComplete: (image) async {
                  debugPrint('Image editing completed');
                  await _saveEditedImage(image);
                },
              ),
            );
          },
        ),
      );

  /// Get editor configuration based on editing mode
  ProImageEditorConfigs _getEditorConfigs() {
    var _mainEditorConfig = mainEditorConfig(widget.mediaEditConfig);

    // Configure based on editing mode
    switch (widget.editingMode) {
      case 'text':
        _mainEditorConfig = _mainEditorConfig.copyWith(
          tools: [
            SubEditorMode.paint,
            SubEditorMode.text,
            SubEditorMode.emoji,
          ],
        );

      case 'filter':
        _mainEditorConfig = _mainEditorConfig.copyWith(
          tools: [
            SubEditorMode.tune,
            SubEditorMode.filter,
            SubEditorMode.blur,
          ],
        );
    }
    return proImageEditorConfigs(widget.mediaEditConfig).copyWith(
      mainEditor: _mainEditorConfig,
    );
  }

  Future<void> _saveEditedImage(Uint8List imageBytes) async {
    try {
      // Get temporary directory for output
      final directory = await getTemporaryDirectory();
      final now = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/edited_image_$now.jpg';

      // Write the edited image to file
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(imageBytes);

      debugPrint('Image editing complete, output: $outputPath');

      if (widget.saveLocally) {
        // Save to gallery
        try {
          final pm.AssetEntity? asset = await pm.PhotoManager.editor.saveImage(
            imageBytes,
            title: widget.title ?? 'edited_image.jpg',
            filename: widget.title ?? 'edited_image.jpg',
          );

          if (asset != null) {
            debugPrint('Got Image AssetEntity: ${asset.id}');
            final editedFile = await asset.file;

            _navigateBack({
              'success': true,
              'asset': asset,
              'file': editedFile ?? outputFile,
              'outputPath': outputPath,
              'mediaType': 'image',
              'savedLocally': true,
            });
          } else {
            debugPrint(
                'Failed to create Image AssetEntity, using file directly');
            _navigateBack({
              'success': true,
              'file': outputFile,
              'outputPath': outputPath,
              'mediaType': 'image',
              'savedLocally': false,
            });
          }
        } catch (e) {
          debugPrint('Error saving image to gallery: $e');
          _navigateBack({
            'success': true,
            'file': outputFile,
            'outputPath': outputPath,
            'mediaType': 'image',
            'savedLocally': false,
          });
        }
      } else {
        // Save to temp directory only
        _navigateBack({
          'success': true,
          'file': outputFile,
          'outputPath': outputPath,
          'mediaType': 'image',
          'savedLocally': false,
        });
      }
    } catch (e) {
      debugPrint('Error saving edited image: $e');
      _navigateBack({
        'success': false,
        'error': 'Failed to save edited image: $e',
      });
    }
  }
}
