import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum TransitionType {
  bottomToTop,
  topToBottom,
  fade,
  leftToRight,
  rightToLeft,
  none,
}

class IsmPageTransition extends CustomTransitionPage<void> {
  IsmPageTransition({
    required this.transitionType,
    required Widget child,
  }) : super(
          child: child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              _buildTransition(animation, child, transitionType),
        );

  final TransitionType transitionType;

  static Widget _buildTransition(Animation<double> animation, Widget child,
      TransitionType transitionType) {
    switch (transitionType) {
      case TransitionType.bottomToTop:
        return _buildBottomToTopTransition(animation, child);
      case TransitionType.topToBottom:
        return _buildTopToBottomTransition(animation, child);
      case TransitionType.fade:
        return _buildFadeTransition(animation, child);
      case TransitionType.leftToRight:
        return _buildLeftToRightTransition(animation, child);
      case TransitionType.rightToLeft:
        return _buildRightToLeftTransition(animation, child);
      default:
        return child; // Fallback to no transition
    }
  }

  static Widget _buildBottomToTopTransition(
      Animation<double> animation, Widget child) {
    const begin = Offset(0.0, 1.0); // Start from the bottom
    const end = Offset.zero; // End at the original position
    const curve = Curves.easeInOut;

    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  static Widget _buildTopToBottomTransition(
      Animation<double> animation, Widget child) {
    const begin = Offset(0.0, -1.0); // Start from the top
    const end = Offset.zero; // End at the original position
    const curve = Curves.easeInOut;

    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  static Widget _buildFadeTransition(
          Animation<double> animation, Widget child) =>
      FadeTransition(
        opacity: animation,
        child: child,
      );

  static Widget _buildLeftToRightTransition(
      Animation<double> animation, Widget child) {
    const begin = Offset(-1.0, 0.0); // Start from the left
    const end = Offset.zero; // End at the original position
    const curve = Curves.easeInOut;

    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  static Widget _buildRightToLeftTransition(
      Animation<double> animation, Widget child) {
    const begin = Offset(1.0, 0.0); // Start from the right
    const end = Offset.zero; // End at the original position
    const curve = Curves.easeInOut;

    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    final offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }
}
