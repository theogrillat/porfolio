import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';

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
  bool get hovering => _hovering;

  StreamSubscription<Offset?>? _mousePositionSubscription;

  double getTopPadding(BuildContext context) {
    double maxHeight = MediaQuery.of(context).size.height;
    return (maxHeight - (widget.box.boxSize * Constants.yCount)) / 2;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _verticalPadding = getTopPadding(context);
    _horizontalPadding = Constants.mainPadding;
    _screenSize = MediaQuery.of(context).size;
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;

    // Check if we're currently in a build phase
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      // We're in build phase, defer the setState
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(fn);
        }
      });
    } else {
      // Safe to call setState immediately
      setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    _mousePositionSubscription = widget.mousePositionStream.listen((position) {
      Offset centerPosition = widget.box.position.getCenterPosition(
          viewSize: screenSize, boxSize: widget.box.boxSize, verticalPadding: verticalPadding, horizontalPadding: horizontalPadding);
      if (position != null) {
        if (widget.box.contains(
          positionToCheck: position,
          viewSize: screenSize,
          verticalPadding: verticalPadding,
          horizontalPadding: horizontalPadding,
        )) {
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
    });
  }

  @override
  void dispose() {
    super.dispose();
    _mousePositionSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onTap != null ? widget.onTap!() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubicEmphasized,
        decoration: BoxDecoration(
          color: widget.box.foreground,
          borderRadius: widget.invert
              ? BorderRadius.circular(hovering ? widget.box.boxSize / 2 : 0)
              : BorderRadius.circular(!hovering ? widget.box.boxSize / 2 : 0),
        ),
        child: widget.child(hovering),
      ),
    );
  }
}
