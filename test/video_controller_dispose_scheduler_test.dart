import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/safe_video_player.dart';

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
}
