import 'package:flutter/material.dart';

class UnderlinedText extends StatelessWidget {
  const UnderlinedText({
    Key? key,
    required this.text,
    required this.textStyle,
    this.underlineGap = 1.0,
    this.underlineThickness = 1.0,
    this.underlineColor,
  }) : super(key: key);
  final String text;
  final TextStyle textStyle;
  final double underlineGap;
  final double underlineThickness;
  final Color? underlineColor;

  @override
  Widget build(BuildContext context) => IntrinsicWidth(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: underlineGap,
              left: 0,
              right: 0,
              child: Container(
                height: underlineThickness,
                color: underlineColor ?? textStyle.color,
              ),
            ),
            Text(
              text,
              style: textStyle.copyWith(
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      );
}
