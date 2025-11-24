import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';

class AnimatedSkew extends StatelessWidget {
  const AnimatedSkew({
    required this.child,
    this.skewed = false,
    this.duration = const Duration(milliseconds: 600),
    this.reverseDuration = const Duration(milliseconds: 300),
    this.rotationX = -0.1,
    this.rotationY = -0.1,
    this.rotationZ = 0,
    this.perspective = 0.08,
    this.scale = 1.2,
    this.translateX = 0,
    required this.width,
    super.key,
  });

  final Widget child;
  final bool skewed;
  final Duration duration;
  final Duration reverseDuration;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double perspective;
  final double scale;
  final double translateX;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Tilt(
      fps: 120,
      lightConfig: const LightConfig(disable: true),
      shadowConfig: const ShadowConfig(disable: true),
      lightShadowMode: LightShadowMode.base,
      tiltConfig: const TiltConfig(
        enableGestureSensors: false,
        enableGestureTouch: true,
        enableGestureHover: true,
        filterQuality: FilterQuality.medium,
        moveDuration: Duration(milliseconds: 100),
        angle: 35,
        direction: [
          TiltDirection.topLeft,
          TiltDirection.topRight,
          TiltDirection.bottomLeft,
          TiltDirection.bottomRight,
        ],
      ),
      child: SizedBox(
        width: width,
        height: width,
        child: Center(child: child),
      ),
    );
  }
}
