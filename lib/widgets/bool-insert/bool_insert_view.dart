import 'package:flutter/material.dart';

class BoolInsertView extends StatelessWidget {
  const BoolInsertView({
    required this.child,
    required this.insert,
    required this.widget,
    super.key,
  });

  final Widget child;
  final bool insert;
  final Function(Widget) widget;

  @override
  Widget build(BuildContext context) {
    if (insert) {
      return widget(child);
    } else {
      return child;
    }
  }
}
