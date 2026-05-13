import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/domain/models/sound_library_models.dart';
import 'package:ism_video_reel_player/presentation/presentation.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_library_mock_data.dart';
import 'package:ism_video_reel_player/presentation/screens/media/sound_selection/sound_selection_theme.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

/// Full-bleed preview for a single track with preview playback and **Use this sound**.
class SoundTrackDetailScreen extends StatefulWidget {
  const SoundTrackDetailScreen({
    super.key,
    required this.track,
    required this.cameraBloc,
  });

  final SoundTrack track;
  final CameraBloc cameraBloc;

  @override
  State<SoundTrackDetailScreen> createState() => _SoundTrackDetailScreenState();
}

class _SoundTrackDetailScreenState extends State<SoundTrackDetailScreen> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _stateSub;

  String get _previewUrl => widget.track.trackUrl.isNotEmpty
      ? widget.track.trackUrl
      : SoundLibraryMockData.defaultTrackPreviewUrl;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _stateSub = _player.onPlayerStateChanged.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    try {
      if (_player.state == PlayerState.playing) {
        await _player.pause();
      } else {
        await _player.play(UrlSource(_previewUrl));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play preview')),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    final s = d.inSeconds;
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final playing = _player.state == PlayerState.playing;
    final st = SoundPickerTheme.of(context);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: st.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: st.appBarBackground,
        elevation: 0,
        foregroundColor: st.onSurface,
        iconTheme: IconThemeData(color: st.onSurface),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () async {
            await _player.pause();
            if (context.mounted) Navigator.pop(context, false);
          },
        ),
        title: Text(
          widget.track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: st.onSurface,
            fontSize: 16.responsiveDimension,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.responsiveDimension),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.responsiveDimension),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppImage.network(
                            widget.track.thumbnailUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Align(
                            child: Material(
                              color: st.playOverlayFill,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: _togglePlayback,
                                child: Padding(
                                  padding: EdgeInsets.all(
                                    14.responsiveDimension,
                                  ),
                                  child: Icon(
                                    playing ? Icons.pause : Icons.play_arrow,
                                    color: st.playIcon,
                                    size: 44.responsiveDimension,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.responsiveDimension),
                  Text(
                    widget.track.title,
                    style: TextStyle(
                      color: st.onSurface,
                      fontSize: 22.responsiveDimension,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.responsiveDimension),
                  Text(
                    widget.track.author,
                    style: TextStyle(
                      color: st.onSurfaceSecondary,
                      fontSize: 16.responsiveDimension,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12.responsiveDimension),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: st.onSurfaceTertiary,
                        size: 18.responsiveDimension,
                      ),
                      SizedBox(width: 6.responsiveDimension),
                      Text(
                        _formatDuration(widget.track.duration),
                        style: TextStyle(
                          color: st.onSurfaceSecondary,
                          fontSize: 14.responsiveDimension,
                        ),
                      ),
                    ],
                  ),
                  if (widget.track.lyricsSnippet != null &&
                      widget.track.lyricsSnippet!.isNotEmpty) ...[
                    SizedBox(height: 20.responsiveDimension),
                    Text(
                      'Lyrics',
                      style: TextStyle(
                        color: st.onSurface,
                        fontSize: 14.responsiveDimension,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.responsiveDimension),
                    Text(
                      widget.track.lyricsSnippet!,
                      style: TextStyle(
                        color: st.onSurfaceSecondary,
                        fontSize: 14.responsiveDimension,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20.responsiveDimension,
              8.responsiveDimension,
              20.responsiveDimension,
              16.responsiveDimension + bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52.responsiveDimension,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.responsiveDimension),
                  ),
                ),
                onPressed: () async {
                  await _player.pause();
                  widget.cameraBloc.add(
                    CameraSetMusicEvent(
                      musicId: widget.track.id,
                      musicName: widget.track.title,
                      musicArtist: widget.track.author,
                      musicThumbnailUrl: widget.track.thumbnailUrl,
                      musicDurationSeconds: widget.track.duration.inSeconds,
                      musicPreviewUrl: widget.track.trackUrl.isEmpty
                          ? SoundLibraryMockData.defaultTrackPreviewUrl
                          : widget.track.trackUrl,
                    ),
                  );
                  if (context.mounted) Navigator.pop(context, true);
                },
                child: Text(
                  'Use this sound',
                  style: TextStyle(
                    fontSize: 16.responsiveDimension,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
