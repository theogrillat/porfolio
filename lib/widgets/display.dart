import 'package:flutter/material.dart';

class Display extends StatelessWidget {
  const Display({
    super.key,
    required this.child,
    required this.show,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeInOut,
    this.minOpacity = 0.0,
    this.maxOpacity = 1.0,
    this.ignorePointer = true,
  })  : assert(minOpacity >= 0.0 && minOpacity <= 1.0, 'minOpacity must be between 0.0 and 1.0'),
        assert(maxOpacity >= 0.0 && maxOpacity <= 1.0, 'maxOpacity must be between 0.0 and 1.0'),
        assert(minOpacity <= maxOpacity, 'minOpacity must be less than or equal to maxOpacity');

  final double minOpacity;
  final double maxOpacity;
  final Widget child;
  final bool show;
  final Duration duration;
  final Curve curve;
  final bool ignorePointer;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: duration,
      curve: curve,
      opacity: show ? 1 : 0,
      child: IgnorePointer(
        ignoring: ignorePointer ? !show : false,
        child: child,
      ),
    );
  }
}
