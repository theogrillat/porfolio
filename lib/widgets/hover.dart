import 'package:flutter/material.dart';

class Hover extends StatefulWidget {
  const Hover({
    super.key,
    required this.child,
  });

  final Function(bool) child;

  @override
  State<Hover> createState() => _HoverState();
}

class _HoverState extends State<Hover> {
  bool _hovering = false;
  bool get hovering => _hovering;

  void setHovering(bool value) {
    if (_hovering == value) return;
    setState(() {
      _hovering = value;
    });
  }

  @override
  void initState() {
    super.initState();
    setHovering(false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => {
        setHovering(true),
      },
      onExit: (_) => {
        setHovering(false),
      },
      child: widget.child(hovering),
    );
  }
}
