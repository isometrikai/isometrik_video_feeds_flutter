import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/feed_plain_text_post_body.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/feed_plain_text_post_section.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';
import 'package:ism_video_reel_player/res/strings/isr_translation_file.dart';

const _collapsedToggleLabel = ' ${IsrTranslationFile.plainTextPostMore}';
const _lessToggleLabel = ' ${IsrTranslationFile.plainTextPostLess}';

Widget _wrapForTest(Widget child) => ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: SizedBox(
                width: constraints.maxWidth,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  testWidgets(
      'FeedPlainTextPostSection places text below username without follow',
      (tester) async {
    const formatting = TextPostFormatting(
      text: 'text test post',
      fontFamily: 'Open Sans',
      fontSize: 17,
      textAlign: 'left',
    );

    await tester.pumpWidget(
      _wrapForTest(
        const FeedPlainTextPostSection(
          formatting: formatting,
          userName: 'nikunj_text',
          userNameStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textColor: Colors.white,
          timestampColor: Colors.grey,
          timestamp: '28 min ago',
          profileAvatar: CircleAvatar(radius: 16, child: Text('NT')),
          moreButton: Icon(Icons.more_horiz, color: Colors.white),
        ),
      ),
    );

    expect(find.text('nikunj_text'), findsOneWidget);
    expect(find.text('28 min ago'), findsOneWidget);
    expect(find.text('text test post'), findsOneWidget);
    expect(find.text('Following'), findsNothing);
    expect(find.text('Follow'), findsNothing);

    final usernameOffset = tester.getTopLeft(find.text('nikunj_text'));
    final textOffset = tester.getTopLeft(find.text('text test post'));
    expect(textOffset.dy, greaterThan(usernameOffset.dy));
    expect(textOffset.dx, greaterThanOrEqualTo(usernameOffset.dx));
  });

  testWidgets('FeedPlainTextPostBody collapses when rendered lines exceed 5',
      (tester) async {
    final longText = List.generate(20, (i) => 'line ${i + 1}').join('\n');
    final formatting = TextPostFormatting(
      text: longText,
      fontFamily: 'Open Sans',
      fontSize: 17,
      textAlign: 'left',
    );

    await tester.pumpWidget(
      _wrapForTest(
        FeedPlainTextPostBody(
          formatting: formatting,
          textColor: Colors.white,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_collapsedToggleLabel), findsOneWidget);
    expect(find.text('line 6'), findsNothing);

    await tester.tap(find.text(_collapsedToggleLabel));
    await tester.pumpAndSettle();

    expect(find.textContaining('line 6'), findsOneWidget);
    expect(find.textContaining(_lessToggleLabel), findsOneWidget);
  });

  testWidgets(
      'FeedPlainTextPostBody collapses line-break spam after normalization',
      (tester) async {
    final spamText = List.generate(8, (_) => 'Text\n\n').join();
    final formatting = TextPostFormatting(
      text: spamText,
      fontFamily: 'Open Sans',
      fontSize: 17,
      textAlign: 'left',
    );

    await tester.pumpWidget(
      _wrapForTest(
        FeedPlainTextPostBody(
          formatting: formatting,
          textColor: Colors.white,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_collapsedToggleLabel), findsOneWidget);
  });
}
