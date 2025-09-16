import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player_example/presentation/presentation.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class MusicSelectionScreen extends StatefulWidget {
  const MusicSelectionScreen({super.key});
  @override
  State<MusicSelectionScreen> createState() => _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends State<MusicSelectionScreen> {
  final _previewPlayer = AudioPlayer();
  var _currentlyPlaying = '';

  Future<void> _playPreview(MusicTrack track) async {
    if (_currentlyPlaying == track.id) {
      Utility.showLoader();
      await _previewPlayer.stop();
      Utility.closeProgressDialog();
      _currentlyPlaying = '';
      setState(() {});
    } else {
      Utility.showLoader();
      await _previewPlayer.stop();
      await _previewPlayer.play(UrlSource(track.url));
      Utility.closeProgressDialog();
      _currentlyPlaying = track.id;
      setState(() {});

      // Auto stop after track duration
      Timer(track.duration, () {
        if (_currentlyPlaying == track.id) {
          _currentlyPlaying = '';
          setState(() {});
        }
      });
    }
  }

  void _selectTrack(MusicTrack track) {
    _previewPlayer.stop();
    Navigator.of(context).pop(track);
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Select Music'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.white,
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: MusicService.getDummyTracks.length,
          itemBuilder: (context, index) {
            final track = MusicService.getDummyTracks[index];
            final isPlaying = _currentlyPlaying == track.id;
            return Card(
              color: Colors.grey[800],
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  track.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.artist,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${track.duration.inMinutes}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  onPressed: () => _playPreview(track),
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
                onTap: () => _selectTrack(track),
              ),
            );
          },
        ),
      );
}
