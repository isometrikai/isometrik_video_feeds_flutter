import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:universal_io/io.dart';

class ImageEditorView extends StatelessWidget {
  ImageEditorView({super.key, required this.imagePath});

  final String imagePath;

  final _editor = GlobalKey<ProImageEditorState>();

  @override
  Widget build(BuildContext context) => ProImageEditor.file(
        File(imagePath),
        key: _editor,
        callbacks: ProImageEditorCallbacks(
          onImageEditingComplete: (bytes) async {
            final tempDir = await getTemporaryDirectory();
            final uniqueName = DateTime.now().millisecondsSinceEpoch.toString();
            final filePath = '${tempDir.path}/$uniqueName.png';
            final file = File(filePath);
            await file.writeAsBytes(bytes);
            Navigator.pop(context, XFile(file.path));
          },
        ),
      );
}
