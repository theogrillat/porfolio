import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/utils.dart';

class BoxButton extends StatefulWidget {
  const BoxButton({
    super.key,
    required this.box,
    this.invert = false,
    this.onTap,
    required this.child,
    required this.mousePositionStream,
    required this.onHovering,
  });

  final Box box;
  final bool invert;
  final Function? onTap;
  final Function(bool) child;
  final Stream<Offset?> mousePositionStream;
  final Function(bool, Offset) onHovering;

  @override
  State<BoxButton> createState() => _BoxButtonState();
}

class _BoxButtonState extends State<BoxButton> {
  double _verticalPadding = 0;
  double _horizontalPadding = 0;
  Size _screenSize = Size.zero;
  Size get screenSize => _screenSize;
  double get verticalPadding => _verticalPadding;
  double get horizontalPadding => _horizontalPadding;

  bool _hovering = false;
  bool _pressed = false;
  bool _hasMouseConnected = false;

  double get radius => widget.box.boxSize / 2;

  late double _tl = 0;
  late double _tr = 0;
  late double _bl = 0;
  late double _br = 0;

  double get tl => _tl;
  double get tr => _tr;
  double get bl => _bl;
  double get br => _br;

  // Combined state for UI: use hover for mouse, pressed for touch
  bool get isActive {
    return _hasMouseConnected ? _hovering : _pressed;
  }

  final int _totalAnimationDuration = isMobileWebBrowser ? 150 : 300;

  void feedback() async {
    HapticFeedback.selectionClick();
    await Future.delayed(Duration(milliseconds: 100));
    HapticFeedback.selectionClick();
  }

  void _updateRadius() async {
    List<Duration> durations = curveToDuration(
      duration: Duration(milliseconds: _totalAnimationDuration),
      stepCount: 3,
      curve: Curves.easeOut,
    ).reversed.toList();
    if (isCircle()) {
      _safeSetState(() => _tl = radius);
      _safeSetState(() => _br = radius);
      await Future.delayed(Duration(milliseconds: 100));
      // await Future.delayed(durations[0]);
      _safeSetState(() => _tr = radius);
      _safeSetState(() => _bl = radius);
      // await Future.delayed(durations[1]);
      // await Future.delayed(durations[2]);
    } else {
      _safeSetState(() => _tl = 0);
      _safeSetState(() => _br = 0);
      // await Future.delayed(durations[0]);
      await Future.delayed(Duration(milliseconds: 100));
      _safeSetState(() => _tr = 0);
      _safeSetState(() => _bl = 0);
      // await Future.delayed(durations[1]);
      // await Future.delayed(durations[2]);
    }
  }

  StreamSubscription<Offset?>? _mousePositionSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _verticalPadding = getTopPadding(context);
    _horizontalPadding = getLeftPadding(context);
    _screenSize = MediaQuery.of(context).size;
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;

    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(fn);
        }
      });
    } else {
      setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    _safeSetState(() {
      _tl = !widget.invert ? radius : 0;
      _tr = !widget.invert ? radius : 0;
      _bl = !widget.invert ? radius : 0;
      _br = !widget.invert ? radius : 0;
    });
    _mousePositionSubscription = widget.mousePositionStream.listen((position) {
      if (mounted) {
        Offset centerPosition = widget.box.position.getCenterPosition(
          context: context,
          boxSize: widget.box.boxSize,
        );
        if (position != null) {
          bool contains = widget.box.contains(positionToCheck: position, context: context);
          if (contains) {
            _safeSetState(() {
              _hovering = true;
              widget.onHovering(true, centerPosition);
            });
            _updateRadius();
          } else {
            _safeSetState(() {
              _hovering = false;
              widget.onHovering(false, centerPosition);
            });
            _updateRadius();
          }
        }
      }
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    // Immediate response for pressed state - no gesture arena delay
    _safeSetState(() {
      _pressed = true;
    });
    _updateRadius();

    // Trigger onHovering callback for touch devices too
    if (!_hasMouseConnected) {
      Offset centerPosition = widget.box.position.getCenterPosition(
        context: context,
        boxSize: widget.box.boxSize,
      );
      widget.onHovering(true, centerPosition);
      feedback();
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    // Immediate response for released state
    _safeSetState(() {
      _pressed = false;
    });
    _updateRadius();

    // Clear the hovering callback for touch devices
    if (!_hasMouseConnected) {
      Offset centerPosition = widget.box.position.getCenterPosition(
        context: context,
        boxSize: widget.box.boxSize,
      );
      widget.onHovering(false, centerPosition);
      feedback();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    // Immediate response for cancelled state
    _safeSetState(() {
      _pressed = false;
    });
    _updateRadius();

    // Clear the hovering callback for touch devices
    if (!_hasMouseConnected) {
      Offset centerPosition = widget.box.position.getCenterPosition(
        context: context,
        boxSize: widget.box.boxSize,
      );
      widget.onHovering(false, centerPosition);
    }
  }

  void _onMouseEnter(PointerEnterEvent event) {
    // Mouse detected - switch to mouse mode
    _safeSetState(() {
      _hasMouseConnected = true;
      _pressed = false; // Clear any touch state
    });
    _updateRadius();
  }

  void _onMouseExit(PointerExitEvent event) {
    // Keep mouse mode but can be overridden by touch
  }

  @override
  void dispose() {
    super.dispose();
    _mousePositionSubscription?.cancel();
  }

  double getScale(bool invert, bool isActive) {
    if (isCircle()) return 1;
    return 1.01;
  }

  bool isCircle() {
    if ((widget.invert && !isActive) || (!widget.invert && isActive)) {
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: _onMouseEnter,
      onExit: _onMouseExit,
      child: Listener(
        // Immediate pointer event handling for pressed state feedback
        onPointerDown: _handlePointerDown,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        child: GestureDetector(
          // Keep gesture detector for proper tap handling
          onTap: () {
            if (widget.onTap == null) return;
            HapticFeedback.lightImpact();
            widget.onTap!();
          },
          child: AnimatedScale(
            duration: Duration(milliseconds: isMobileWebBrowser ? 150 : 300),
            curve: Curves.easeInOutCubicEmphasized,
            scale: getScale(widget.invert, isActive),
            child: AnimatedContainer(
              duration: Duration(milliseconds: (isMobileWebBrowser ? 150 : 300) ~/ 3),
              curve: Curves.ease,
              decoration: BoxDecoration(
                color: widget.box.foreground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(tl),
                  topRight: Radius.circular(tr),
                  bottomLeft: Radius.circular(bl),
                  bottomRight: Radius.circular(br),
                ),
              ),
              child: widget.child(isActive),
            ),
          ),
        ),
      ),
    );
  }
}
