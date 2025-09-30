import 'dart:math';

import 'package:flutter/material.dart';

class MouseFollower extends StatefulWidget {
  const MouseFollower({
    super.key,
    required this.hoveringPostion,
    required this.hovering,
    required this.hoverColor,
    required this.defaultColor,
    required this.y,
    required this.x,
    required this.isIn,
    required this.seed,
    required this.count,
    this.trailDelay = 50,
  });

  final Offset? hoveringPostion;
  final bool hovering;
  final Color hoverColor;
  final Color defaultColor;
  final double y;
  final double x;
  final bool isIn;
  final int seed;
  final int count;
  final int trailDelay;

  @override
  State<MouseFollower> createState() => _MouseFollowerState();
}

class _MouseFollowerState extends State<MouseFollower> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _amplitudeController;
  late AnimationController _positionXController;
  late AnimationController _positionYController;
  late Animation<double> _waveAnimation;
  late Animation<double> _amplitudeAnimation;
  late Animation<double> _positionXAnimation;
  late Animation<double> _positionYAnimation;

  double _currentX = 0;
  double _currentY = 0;
  double _targetX = 0;
  double _targetY = 0;

  @override
  void initState() {
    super.initState();

    // Initialize position
    _currentX = widget.x - 40;
    _currentY = widget.y - 40;
    _targetX = _currentX;
    _targetY = _currentY;

    _waveController = AnimationController(
      duration: Duration(milliseconds: widget.hovering ? 100 : 1000),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(_waveController);

    _amplitudeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _amplitudeAnimation = Tween<double>(
      begin: 1,
      end: 6,
    ).animate(_amplitudeController);

    // Physics-based position controllers
    _positionXController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _positionYController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Initialize animations with current position
    _positionXAnimation = Tween<double>(
      begin: _currentX,
      end: _currentX,
    ).animate(_positionXController);

    _positionYAnimation = Tween<double>(
      begin: _currentY,
      end: _currentY,
    ).animate(_positionYController);

    // Add listeners to trigger rebuilds
    _positionXController.addListener(() {
      if (mounted) setState(() {});
    });
    _positionYController.addListener(() {
      if (mounted) setState(() {});
    });

    _waveController.repeat();

    // Start with initial animation to target position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialTargetX = (widget.hoveringPostion?.dx ?? widget.x) - 40;
      final initialTargetY = (widget.hoveringPostion?.dy ?? widget.y) - 40;
      print('Initial animation for follower ${widget.seed}: target ($initialTargetX, $initialTargetY)');
      _animateToPosition(initialTargetX, initialTargetY);
    });
  }

  void _animateToPosition(double targetX, double targetY) {
    // Don't animate if targets haven't changed significantly
    if ((targetX - _targetX).abs() < 1.0 && (targetY - _targetY).abs() < 1.0) {
      return;
    }

    _currentX = _positionXAnimation.value;
    _currentY = _positionYAnimation.value;
    _targetX = targetX;
    _targetY = targetY;

    // Stop any existing animations
    _positionXController.stop();
    _positionYController.stop();

    // Reset controllers
    _positionXController.reset();
    _positionYController.reset();

    // Create new animations
    _positionXAnimation = Tween<double>(
      begin: _currentX,
      end: _targetX,
    ).animate(CurvedAnimation(
      parent: _positionXController,
      curve: Curves.elasticOut,
    ));

    _positionYAnimation = Tween<double>(
      begin: _currentY,
      end: _targetY,
    ).animate(CurvedAnimation(
      parent: _positionYController,
      curve: Curves.elasticOut,
    ));

    // Set duration based on distance and hover state
    final distance = ((targetX - _currentX).abs() + (targetY - _currentY).abs()) / 2;
    final baseDuration = widget.hovering ? 300 : 800;
    final duration = Duration(milliseconds: (baseDuration + widget.count * widget.trailDelay - (widget.seed * widget.trailDelay)).round());

    _positionXController.duration = duration;
    _positionYController.duration = duration;

    // Start animations
    _positionXController.forward();
    _positionYController.forward();

    // print('Animating mouse follower ${widget.seed} from ($_currentX, $_currentY) to ($_targetX, $_targetY) in ${duration.inMilliseconds}ms');
  }

  @override
  void didUpdateWidget(MouseFollower oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if position changed
    final newTargetX = (widget.hoveringPostion?.dx ?? widget.x) - 40;
    final newTargetY = (widget.hoveringPostion?.dy ?? widget.y) - 40;

    // Always animate to new position when it changes
    if (newTargetX != _targetX || newTargetY != _targetY) {
      _animateToPosition(newTargetX, newTargetY);
    }

    if (widget.hovering != oldWidget.hovering) {
      if (widget.hovering) {
        _waveController.duration = Duration(milliseconds: 300);
        _waveController.repeat();
        _amplitudeController.animateTo(6, duration: Duration(milliseconds: 3000));
      } else {
        _waveController.duration = Duration(milliseconds: 2000);
        _waveController.repeat();
        _amplitudeController.animateTo(0, duration: Duration(milliseconds: 600));
      }

      // Update spring characteristics when hover state changes
      _animateToPosition(_targetX, _targetY);
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _amplitudeController.dispose();
    _positionXController.dispose();
    _positionYController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _positionYAnimation.value,
      left: _positionXAnimation.value,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 600),
        opacity: widget.isIn ? 1 : 0,
        child: AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return SizedBox(
              height: 80,
              width: 80,
              child: AnimatedScale(
                duration: widget.hovering ? const Duration(milliseconds: 200) : const Duration(milliseconds: 1000),
                scale: widget.hovering ? 1.7 : 0.3,
                curve: Curves.easeOutCubic,
                child: Builder(builder: (context) {
                  double hoveringOpacity = (widget.seed / widget.count);
                  double interpolatedOpacity = hoveringOpacity * 0.3;
                  double restInterpolatedOpacity = hoveringOpacity * 0.5;
                  return CustomPaint(
                    painter: WavyCirclePainter(
                      color: (widget.hovering ? widget.hoverColor : widget.defaultColor)
                          .withValues(alpha: widget.hovering ? interpolatedOpacity : restInterpolatedOpacity),
                      waveOffset: _waveAnimation.value,
                      hovering: widget.hovering,
                      seed: widget.seed,
                      amplitude: _amplitudeAnimation.value,
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}

class WavyCirclePainter extends CustomPainter {
  final Color color;
  final double waveOffset;
  final bool hovering;
  final int seed;
  final double amplitude;
  WavyCirclePainter({
    required this.color,
    required this.waveOffset,
    required this.hovering,
    required this.seed,
    required this.amplitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = hovering ? 4 : 22;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5; // Leave some padding for the waves
    final path = Path();

    // Create wavy circle
    const int points = 120; // Number of points to create smooth circle
    double waveAmplitude = (amplitude * (seed * 1.5)); // How "wavy" the circle is

    for (int i = 0; i <= points; i++) {
      final angle = (i / points) * 2 * pi;
      final baseWaveIntensity = hovering ? 1.2 : 1;

      // Create pseudo-random phase offset that loops seamlessly
      final randomPhase1 = sin(angle * 7 + seed) * 0.5;
      final randomPhase2 = sin(angle * 11 + seed) * 0.3;
      final randomPhase3 = sin(angle * 5 + seed) * 0.2;
      final randomPhaseOffset = randomPhase1 + randomPhase2 + randomPhase3;

      final timeDelay = angle + randomPhaseOffset;
      final delayedWaveIntensity = baseWaveIntensity * (0.5 + 0.5 * sin(waveOffset + timeDelay));

      // Multiple wave layers with different speeds and directions for organic randomness
      final wave1 = sin(angle * 6 + waveOffset * 1) * 1.2; // Forward, slow
      final wave2 = sin(angle * 4 + waveOffset * -2) * 0.9; // Backward, medium
      final wave3 = sin(angle * 3 + waveOffset * 3) * 0.7; // Forward, fast

      final combinedWave = (wave1 + wave2 + wave3) / 3;
      final waveRadius = radius + (waveAmplitude * combinedWave * delayedWaveIntensity);

      final x = center.dx + waveRadius * cos(angle);
      final y = center.dy + waveRadius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavyCirclePainter oldDelegate) {
    return oldDelegate.waveOffset != waveOffset || oldDelegate.color != color || oldDelegate.hovering != hovering;
  }
}
