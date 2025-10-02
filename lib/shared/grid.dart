import 'package:flutter/material.dart';
import 'package:portfolio/shared/coords.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/shared/utils.dart';
import 'package:portfolio/widgets/animated_blur.dart';

class Coords {
  final int x;
  final int y;

  Coords(
    this.x,
    this.y,
  );
}

class BoxPosition {
  final Coords start;
  final Coords end;

  int get width => end.x - start.x + 1;
  int get height => end.y - start.y + 1;

  int get left => start.x;
  int get top => start.y;

  Offset getCenterPosition({
    required BuildContext context,
    required double boxSize,
  }) {
    double verticalPadding = getTopPadding(context);
    double horizontalPadding = getLeftPadding(context);
    double heightPx = height * boxSize;
    double widthPx = width * boxSize;
    double topFromViewportPx = boxSize * top + verticalPadding;
    double leftFromViewportPx = boxSize * left + horizontalPadding;

    double centerTopFromViewportPx = topFromViewportPx + heightPx / 2;
    double centerLeftFromViewportPx = leftFromViewportPx + widthPx / 2;
    return Offset(centerLeftFromViewportPx, centerTopFromViewportPx);
  }

  bool contains({
    required BuildContext context,
    required double boxSize,
    required Offset positionToCheck,
  }) {
    double leftOffset = getLeftOffsetFromViewport(context: context, boxSize: boxSize);
    double rightOffset = getRightOffsetFromViewport(context: context, boxSize: boxSize);
    double topOffset = getTopOffsetFromViewport(context: context, boxSize: boxSize);
    double bottomOffset = getBottomOffsetFromViewport(context: context, boxSize: boxSize);

    if (positionToCheck.dx < leftOffset) {
      return false;
    }
    if (positionToCheck.dx > rightOffset) {
      return false;
    }
    if (positionToCheck.dy < topOffset) {
      return false;
    }
    if (positionToCheck.dy > bottomOffset) {
      return false;
    }
    return true;
  }

  double getLeftOffsetFromViewport({
    required BuildContext context,
    required double boxSize,
  }) {
    double horizontalPadding = getLeftPadding(context);
    double leftFromViewportPx = boxSize * left + horizontalPadding;
    return leftFromViewportPx;
  }

  double getTopOffsetFromViewport({
    required BuildContext context,
    required double boxSize,
  }) {
    double verticalPadding = getTopPadding(context);
    return boxSize * top + verticalPadding;
  }

  double getRightOffsetFromViewport({
    required BuildContext context,
    required double boxSize,
  }) {
    return getLeftOffsetFromViewport(context: context, boxSize: boxSize) + width * boxSize;
  }

  double getBottomOffsetFromViewport({
    required BuildContext context,
    required double boxSize,
  }) {
    return getTopOffsetFromViewport(
          context: context,
          boxSize: boxSize,
        ) +
        height * boxSize;
  }

  BoxPosition({
    required this.start,
    required this.end,
  });

  BoxPosition.single(int x, int y)
      : start = Coords(x, y),
        end = Coords(x, y);
}

class Box {
  final BoxPosition position;
  final Color background;
  final Color foreground;
  final double boxSize;

  Box({
    required this.position,
    required this.background,
    required this.foreground,
    required this.boxSize,
  });

  bool contains({
    required Offset positionToCheck,
    required BuildContext context,
  }) {
    return position.contains(
      positionToCheck: positionToCheck,
      boxSize: boxSize,
      context: context,
    );
  }
}

class GridBox extends StatelessWidget {
  const GridBox({
    super.key,
    required this.show,
    this.blur = false,
    required this.transitionDuration,
    required this.transitionCurve,
    required this.boxSize,
    required this.background,
    required this.foreground,
    required this.child,
    required this.item,
    this.fakeBorders = false,
    this.extendRight = false,
    this.extendBottom = false,
    this.extendLeft = false,
    this.extendTop = false,
    this.transparent = false,
  });

  final bool show;
  final bool blur;
  final double boxSize;
  final Color background;
  final Color foreground;
  final Function(Box) child;
  final Duration transitionDuration;
  final Curve transitionCurve;
  final BoxItem item;
  final bool fakeBorders;
  final bool extendRight;
  final bool extendBottom;
  final bool extendLeft;
  final bool extendTop;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    double verticalPadding = (MediaQuery.of(context).size.height - boxSize * Constants.yCount(context)) / 2;
    double heightPx = boxSize * item.position.height;
    double widthPx = boxSize * item.position.width;

    double leftPx = item.position.left * boxSize;
    double topPx = verticalPadding + item.position.top * boxSize;

    double borderWidth = Constants.edgeWidth / 2;

    if (fakeBorders) {
      if (extendLeft) leftPx -= Constants.edgeWidth / 2;
      if (extendTop) topPx -= Constants.edgeWidth / 2;
      widthPx += (extendLeft ? borderWidth : 0) + (extendRight ? borderWidth : 0);
      heightPx += (extendTop ? borderWidth : 0) + (extendBottom ? borderWidth : 0);
    }

    return Positioned(
      top: topPx,
      left: leftPx,
      child: IgnorePointer(
        ignoring: !show && !blur,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubicEmphasized,
          opacity: blur ? 0 : 1,
          child: AnimatedOpacity(
            opacity: show ? 1 : 0,
            duration: transitionDuration,
            curve: transitionCurve,
            child: SizedBox(
              height: heightPx,
              width: widthPx,
              child: ClipRect(
                child: AnimatedContainer(
                  duration: transitionDuration,
                  curve: transitionCurve,
                  decoration: BoxDecoration(
                    color: transparent ? Colors.transparent : background,
                    border: Border(
                      top: BorderSide(width: borderWidth * (fakeBorders && extendTop ? 2 : 1), color: foreground),
                      right: BorderSide(width: borderWidth * (fakeBorders && extendRight ? 2 : 1), color: foreground),
                      bottom: BorderSide(width: borderWidth * (fakeBorders && extendBottom ? 2 : 1), color: foreground),
                      left: BorderSide(width: borderWidth * (fakeBorders && extendLeft ? 2 : 1), color: foreground),
                    ),
                  ),
                  child: AnimatedBlur(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubicEmphasized,
                    blurSigma: 75,
                    blur: blur,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubicEmphasized,
                      scale: blur ? 1.05 : 1,
                      child: child(
                        Box(
                          position: item.position,
                          background: background,
                          foreground: foreground,
                          boxSize: boxSize,
                        ),
                      )
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
