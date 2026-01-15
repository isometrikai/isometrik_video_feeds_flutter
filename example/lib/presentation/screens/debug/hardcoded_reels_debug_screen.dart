import 'package:flutter/material.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_cache_manager.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/video_player_widget.dart';

class HardcodedReelsDebugScreen extends StatefulWidget {
  const HardcodedReelsDebugScreen({super.key});

  /// NOTE: Your pasted URLs contain "…" (ellipsis) which means they are truncated.
  /// Paste FULL Cloudinary URLs here (no ellipsis) for playback to work.
  static const List<String> mediaUrls = <String>[
    // Paste full URLs (examples kept as-is from chat):
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460387/WhatsApp_Video_2025-09-19_at_17.02.35…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460385/WhatsApp_Video_2025-09-19_at_18.26.49…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460384/WhatsApp_Video_2025-09-19_at_16.30.56…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460384/WhatsApp_Video_2025-09-19_at_17.01.53…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460384/WhatsApp_Video_2025-09-19_at_16.18.40…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460382/WhatsApp_Video_2025-09-19_at_16.28.01…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460382/WhatsApp_Video_2025-09-19_at_18.25.47…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460382/WhatsApp_Video_2025-09-19_at_18.26.21…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460381/WhatsApp_Video_2025-09-19_at_16.17.11…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460377/WhatsApp_Video_2025-09-19_at_18.24.35…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460374/WhatsApp_Video_2025-09-19_at_16.28.56…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460371/WhatsApp_Video_2025-09-19_at_18.25.05…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460370/WhatsApp_Video_2025-09-19_at_18.24.04…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460365/WhatsApp_Video_2025-09-19_at_18.23.44…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460364/WhatsApp_Video_2025-09-19_at_18.20.57…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460364/WhatsApp_Video_2025-09-19_at_16.15.35…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460362/WhatsApp_Video_2025-09-19_at_16.16.02…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460362/WhatsApp_Video_2025-09-19_at_18.22.47…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460361/WhatsApp_Video_2025-09-19_at_18.23.27…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460361/WhatsApp_Video_2025-09-19_at_17.08.30…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460360/WhatsApp_Video_2025-09-19_at_16.14.44…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460359/WhatsApp_Video_2025-09-19_at_18.22.01…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460358/WhatsApp_Video_2025-09-19_at_16.15.10…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460340/WhatsApp_Video_2025-09-19_at_17.06.45…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460335/WhatsApp_Video_2025-09-19_at_16.12.35…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460326/WhatsApp_Video_2025-09-19_at_17.05.42…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460319/WhatsApp_Video_2025-09-19_at_16.11.04…',
    'https://res.cloudinary.com/dcsujd521/video/upload/v1768460319/WhatsApp_Video_2025-09-19_at_16.11.29…',
  ];

  @override
  State<HardcodedReelsDebugScreen> createState() =>
      _HardcodedReelsDebugScreenState();
}

class _HardcodedReelsDebugScreenState extends State<HardcodedReelsDebugScreen> {
  final VideoCacheManager _cacheManager = VideoCacheManager();
  final PageController _pageController = PageController();

  bool _isMuted = false;

  List<String> get _urls => HardcodedReelsDebugScreen.mediaUrls
      .map(_sanitizeUrl)
      .where((u) => u.startsWith('http'))
      .toList(growable: false);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static String _sanitizeUrl(String url) =>
      url.trim().replaceAll('\u2026', '');

  static String _cloudinaryThumbUrl(String videoUrl) {
    final url = _sanitizeUrl(videoUrl);
    if (!url.contains('res.cloudinary.com')) return '';
    // Cloudinary can generate thumbnails from videos via transformations.
    // We use a simple "start offset 0" + force jpg format.
    return url.replaceFirst(
      '/video/upload/',
      '/video/upload/so_0,f_jpg/',
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = _urls;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Hardcoded Reels (${urls.length})'),
        actions: [
          IconButton(
            tooltip: _isMuted ? 'Unmute' : 'Mute',
            onPressed: () => setState(() => _isMuted = !_isMuted),
            icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
          ),
        ],
      ),
      body: urls.isEmpty
          ? const Center(
              child: Text(
                'No valid URLs.\nPaste full Cloudinary URLs (no “…”) in HardcodedReelsDebugScreen.mediaUrls.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            )
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: urls.length,
              itemBuilder: (context, index) {
                final url = urls[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoPlayerWidget(
                      mediaUrl: url,
                      thumbnailUrl: _cloudinaryThumbUrl(url),
                      videoCacheManager: _cacheManager,
                      isMuted: _isMuted,
                      onVisibilityChanged: (isVisible) {
                        // Helpful debug log to confirm visibility logic.
                        debugPrint(
                            '👁️ Debug reel[$index] visible=$isVisible url=$url');
                      },
                    ),
                    Positioned(
                      left: 12,
                      bottom: 24,
                      right: 12,
                      child: Text(
                        '[$index] $url',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          shadows: [
                            Shadow(blurRadius: 6, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

