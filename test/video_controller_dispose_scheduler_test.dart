import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/safe_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpTwoFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
    // Flush the async disposeFn scheduled inside the second post-frame callback.
    await tester.idle();
  }

  testWidgets('dispose scheduler runs after two frames', (tester) async {
    var disposed = false;
    final token = Object();

    VideoControllerDisposeScheduler.scheduleAfterUnmount(token, () async {
      disposed = true;
    });

    expect(disposed, isFalse);
    await pumpTwoFrames(tester);
    expect(disposed, isTrue);
  });

  testWidgets('dispose scheduler cancel prevents dispose', (tester) async {
    var disposed = false;
    final token = Object();

    VideoControllerDisposeScheduler.scheduleAfterUnmount(token, () async {
      disposed = true;
    });
    VideoControllerDisposeScheduler.cancel(token);

    await pumpTwoFrames(tester);
    expect(disposed, isFalse);
  });

  testWidgets('reattach cancels prior dispose then allows new schedule',
      (tester) async {
    var disposeCount = 0;
    final token = Object();

    VideoControllerDisposeScheduler.scheduleAfterUnmount(token, () async {
      disposeCount++;
    });
    // Simulate re-attach before frames complete.
    VideoControllerDisposeScheduler.cancel(token);

    await pumpTwoFrames(tester);
    expect(disposeCount, 0);

    VideoControllerDisposeScheduler.scheduleAfterUnmount(token, () async {
      disposeCount++;
    });
    await pumpTwoFrames(tester);
    expect(disposeCount, 1);
  });

  testWidgets('dispose scheduler awaits waitBeforeDispose', (tester) async {
    var disposed = false;
    var waited = false;
    final token = Object();
    final gate = Completer<void>();

    VideoControllerDisposeScheduler.scheduleAfterUnmount(
      token,
      () async {
        disposed = true;
      },
      waitBeforeDispose: () async {
        waited = true;
        await gate.future;
      },
    );

    await tester.pump();
    await tester.pump();
    await tester.idle();
    expect(waited, isTrue);
    expect(disposed, isFalse);

    gate.complete();
    await tester.idle();
    expect(disposed, isTrue);
  });

  testWidgets('SafeVideoPlayer returns shrink for uninitialized controller',
      (tester) async {
    VideoPlayerPlatform.instance = _ThrowingVideoPlayerPlatform();

    final controller = VideoPlayerController.networkUrl(
      Uri.parse('https://example.com/video.mp4'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SafeVideoPlayer(
          controller: controller,
          isBuildSafe: () => true,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await controller.dispose();
  });

  testWidgets('SafeVideoPlayer catches platform build StateError',
      (tester) async {
    VideoPlayerPlatform.instance = _ThrowingVideoPlayerPlatform();

    final controller = _FakeInitializedController();
    var mounted = false;
    var unmounted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SafeVideoPlayer(
          controller: controller,
          isBuildSafe: () => true,
          onSurfaceMounted: () => mounted = true,
          onSurfaceUnmounted: () => unmounted = true,
        ),
      ),
    );

    expect(mounted, isTrue);
    // Platform throws → shrink, no crash.
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(unmounted, isTrue);
  });
}

class _ThrowingVideoPlayerPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    throw StateError('No active player with ID ${options.playerId}.');
  }
}

/// Minimal controller double so [SafeVideoPlayer] reaches buildViewWithOptions.
class _FakeInitializedController extends Fake
    implements VideoPlayerController {
  @override
  int get playerId => 3;

  @override
  VideoPlayerValue get value => const VideoPlayerValue(
        duration: Duration(seconds: 1),
        isInitialized: true,
      );

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  Future<void> dispose() async {}
}
