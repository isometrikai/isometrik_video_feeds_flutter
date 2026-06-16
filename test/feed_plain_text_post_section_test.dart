import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/feed_plain_text_post_section.dart';
import 'package:ism_video_reel_player/presentation/screens/posts/widgets/text_post_formatting.dart';

void main() {
  testWidgets('FeedPlainTextPostSection places text below username without follow',
      (tester) async {
    const formatting = TextPostFormatting(
      text: 'text test post',
      fontFamily: 'Open Sans',
      fontSize: 17,
      textAlign: 'left',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FeedPlainTextPostSection(
            formatting: formatting,
            userName: 'nikunj_text',
            userNameStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textColor: Colors.white,
            timestampColor: Colors.grey,
            timestamp: '28 min ago',
            profileAvatar: const CircleAvatar(radius: 16, child: Text('NT')),
            moreButton: const Icon(Icons.more_horiz, color: Colors.white),
          ),
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
}
