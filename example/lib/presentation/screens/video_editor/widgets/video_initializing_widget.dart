import 'package:flutter/material.dart';

class VideoInitializingWidget extends StatelessWidget {
  const VideoInitializingWidget({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blueGrey.shade900,
                Colors.black87,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 30,
              children: [
                Icon(
                  Icons.video_camera_back_rounded,
                  size: 80,
                  color: Colors.white70,
                ),
                Text(
                  'Initializing Video-Editor...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    color: Colors.white70,
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
