import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/shared/utils.dart';
import 'package:portfolio/widgets/display.dart';

class BoxAction extends StatelessWidget {
  const BoxAction({
    super.key,
    this.h = false,
    required this.onTap,
    required this.background,
    required this.foreground,
    required this.label,
  });

  final bool h;
  final Function() onTap;
  final Color background;
  final Color foreground;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: Display(
        show: h || isMobileWebBrowser,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap.call();
            },
            child: Container(
                color: foreground,
                child: Text(
                  label,
                  style: Typos(context).regular(color: background),
                )),
          ),
        ),
      ),
    );
  }
}
