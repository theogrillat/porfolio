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

  // Combined state for UI: use hover for mouse, pressed for touch
  bool get isActive => _hasMouseConnected ? _hovering : _pressed;

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
          } else {
            _safeSetState(() {
              _hovering = false;
              widget.onHovering(false, centerPosition);
            });
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

    // Trigger onHovering callback for touch devices too
    if (!_hasMouseConnected) {
      Offset centerPosition = widget.box.position.getCenterPosition(
        context: context,
        boxSize: widget.box.boxSize,
      );
      widget.onHovering(true, centerPosition);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    // Immediate response for released state
    _safeSetState(() {
      _pressed = false;
    });

    // Clear the hovering callback for touch devices
    if (!_hasMouseConnected) {
      Offset centerPosition = widget.box.position.getCenterPosition(
        context: context,
        boxSize: widget.box.boxSize,
      );
      widget.onHovering(false, centerPosition);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    // Immediate response for cancelled state
    _safeSetState(() {
      _pressed = false;
    });

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
  }

  void _onMouseExit(PointerExitEvent event) {
    // Keep mouse mode but can be overridden by touch
  }

  @override
  void dispose() {
    super.dispose();
    _mousePositionSubscription?.cancel();
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
          child: AnimatedContainer(
            duration: Duration(milliseconds: isMobileWebBrowser ? 150 : 300),
            curve: Curves.easeInOutCubicEmphasized,
            decoration: BoxDecoration(
              color: widget.box.foreground,
              borderRadius: widget.invert ? BorderRadius.circular(isActive ? widget.box.boxSize / 2 : 0) : BorderRadius.circular(!isActive ? widget.box.boxSize / 2 : 0),
            ),
            child: widget.child(isActive),
          ),
        ),
      ),
    );
  }
}
