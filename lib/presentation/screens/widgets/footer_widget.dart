import 'package:flutter/material.dart';

class ReelsWidgetBuilder {
  const ReelsWidgetBuilder({
    required this.child,
    this.padding,
    this.alignment,
  });

  final Widget child;
  final EdgeInsets? padding;
  final Alignment? alignment;
}
