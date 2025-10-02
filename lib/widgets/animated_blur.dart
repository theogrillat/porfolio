import 'dart:ui';

import 'package:flutter/material.dart';

class AnimatedBlur extends StatelessWidget {
  const AnimatedBlur({
    super.key,
    required this.child,
    required this.blur,
    this.blurSigma = 10,
    required this.duration,
    this.curve = Curves.linear,
  });

  final Widget child;
  final bool blur;
  final double blurSigma;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: blur ? 1.0 : 0.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: value * blurSigma,
            sigmaY: value * blurSigma,
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}