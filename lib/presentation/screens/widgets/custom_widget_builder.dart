import 'package:flutter/material.dart';

class CustomWidgetBuilder {
  static Widget build({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(8),
    VoidCallback? onTap,
  }) {
    var wrappedChild = child;

    if (onTap != null) {
      wrappedChild = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    }
    return Padding(
      padding: padding,
      child: wrappedChild,
    );
  }
}
