import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class Hover extends StatefulWidget {
  const Hover({
    super.key,
    required this.child,
    this.showCursor = false,
  });

  final Function(bool) child;
  final bool showCursor;
  @override
  State<Hover> createState() => _HoverState();
}

class _HoverState extends State<Hover> {
  bool _mouseHovering = false;
  bool _touchPressed = false;

  bool get hovering => _mouseHovering || _touchPressed;

  void setMouseHovering(bool value) {
    if (_mouseHovering == value) return;
    setState(() {
      _mouseHovering = value;
    });
  }

  void setTouchPressed(bool value) {
    if (_touchPressed == value) return;
    setState(() {
      _touchPressed = value;
    });
  }

  @override
  void initState() {
    super.initState();
    setMouseHovering(false);
    setTouchPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        // Only handle touch events, not mouse events
        if (event.kind == PointerDeviceKind.touch) {
          setTouchPressed(true);
        }
      },
      onPointerUp: (event) {
        if (event.kind == PointerDeviceKind.touch) {
          setTouchPressed(false);
        }
      },
      onPointerCancel: (event) {
        if (event.kind == PointerDeviceKind.touch) {
          setTouchPressed(false);
        }
      },
      child: MouseRegion(
        cursor: widget.showCursor ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setMouseHovering(true),
        onExit: (_) => setMouseHovering(false),
        child: widget.child(hovering),
      ),
    );
  }
}
