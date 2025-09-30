import 'package:flutter/material.dart';

import 'package:flutter_physics/flutter_physics.dart';

class SkewedText extends StatefulWidget {
  const SkewedText({
    required this.text,
    required this.textStyle,
    this.skewed = false,
    this.duration = const Duration(milliseconds: 600),
    this.reverseDuration = const Duration(milliseconds: 300),
    this.rotationX = -0.1,
    this.rotationY = -0.1,
    this.rotationZ = 0,
    this.perspective = 0.08,
    this.scale = 1.2,
    required this.width,
    super.key,
  });

  final String text;
  final TextStyle textStyle;
  final bool skewed;
  final Duration duration;
  final Duration reverseDuration;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double perspective;
  final double scale;
  final double width;
  @override
  State<SkewedText> createState() => _SkewedText();
}

class _SkewedText extends State<SkewedText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationXAnimation;
  late Animation<double> _rotationYAnimation;
  late Animation<double> _rotationZAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _translateAnimation;

  final Spring inCurve = Spring.boingoingoing;
  final Curve outCurve = Curves.easeInExpo;

  double getTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
    );
    textPainter.layout();
    return textPainter.width;
  }

  double getXTranslate() {
    double textWidth = getTextWidth(widget.text, widget.textStyle);
    double width = widget.width;
    double xAmount = (width - textWidth) / 2;
    print('WIDTH: $width\nTEXT WIDTH: $textWidth\nX AMOUNT: $xAmount');
    return -xAmount;
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
      vsync: this,
    );

    _createAnimations();

    if (widget.skewed) {
      _controller.forward();
    }
  }

  void _createAnimations() {
    _rotationXAnimation = Tween<double>(
      begin: 0.0,
      end: widget.rotationX,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: inCurve,
      reverseCurve: outCurve,
    ));

    _rotationYAnimation = Tween<double>(
      begin: 0.0,
      end: widget.rotationY,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: inCurve,
      reverseCurve: outCurve,
    ));

    _rotationZAnimation = Tween<double>(
      begin: 0.0,
      end: widget.rotationZ,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: inCurve,
      reverseCurve: outCurve,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: inCurve,
      reverseCurve: outCurve,
    ));

    _translateAnimation = Tween<double>(
      begin: 0.0,
      end: getXTranslate(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: inCurve,
      reverseCurve: outCurve,
    ));
  }

  void _switchDirectionSmoothly(bool forward) {
    // Get current animation values
    final currentRotationX = _rotationXAnimation.value;
    final currentRotationY = _rotationYAnimation.value;
    final currentRotationZ = _rotationZAnimation.value;
    final currentScale = _scaleAnimation.value;
    final currentTranslate = _translateAnimation.value;

    // Stop the current animation
    _controller.stop();

    if (forward) {
      // Going forward: create animations from current values to target values
      _rotationXAnimation = Tween<double>(
        begin: currentRotationX,
        end: widget.rotationX,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: inCurve,
      ));

      _rotationYAnimation = Tween<double>(
        begin: currentRotationY,
        end: widget.rotationY,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: inCurve,
      ));

      _rotationZAnimation = Tween<double>(
        begin: currentRotationZ,
        end: widget.rotationZ,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: inCurve,
      ));

      _scaleAnimation = Tween<double>(
        begin: currentScale,
        end: widget.scale,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: inCurve,
      ));

      _translateAnimation = Tween<double>(
        begin: currentTranslate,
        end: getXTranslate(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: inCurve,
      ));

      // Reset controller and go forward
      _controller.reset();
      _controller.forward();
    } else {
      // Going reverse: create animations from current values to initial values
      _rotationXAnimation = Tween<double>(
        begin: currentRotationX,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: outCurve,
      ));

      _rotationYAnimation = Tween<double>(
        begin: currentRotationY,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: outCurve,
      ));

      _rotationZAnimation = Tween<double>(
        begin: currentRotationZ,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: outCurve,
      ));

      _scaleAnimation = Tween<double>(
        begin: currentScale,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: outCurve,
      ));

      _translateAnimation = Tween<double>(
        begin: currentTranslate,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: outCurve,
      ));

      // Reset controller and go forward (which will animate to the "end" values, which are the initial values)
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SkewedText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.skewed != oldWidget.skewed) {
      if (_controller.isAnimating) {
        // Animation is in progress, switch smoothly
        _switchDirectionSmoothly(widget.skewed);
      } else {
        // No animation in progress, use normal animations
        _createAnimations();

        if (widget.skewed) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      }
    }

    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }

    if (widget.reverseDuration != oldWidget.reverseDuration) {
      _controller.reverseDuration = widget.reverseDuration;
    }

    if (widget.rotationX != oldWidget.rotationX || widget.rotationY != oldWidget.rotationY || widget.rotationZ != oldWidget.rotationZ || widget.scale != oldWidget.scale) {
      _createAnimations();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, widget.perspective)
            ..rotateX(_rotationXAnimation.value)
            ..rotateY(_rotationYAnimation.value)
            ..rotateZ(_rotationZAnimation.value)
            ..translate(_translateAnimation.value, 0, 0)
            ..scale(_scaleAnimation.value),
          child: Text(
            widget.text,
            style: widget.textStyle,
          ),
        );
      },
    );
  }
}
