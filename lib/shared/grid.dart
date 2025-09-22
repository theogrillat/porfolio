import 'package:flutter/material.dart';
import 'package:portfolio/shared/styles.dart';

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
    required Size viewSize,
    required double boxSize,
    required double verticalPadding,
    required double horizontalPadding,
  }) {
    double heightPx = height * boxSize;
    double widthPx = width * boxSize;
    double topFromViewportPx = boxSize * top + verticalPadding;
    double leftFromViewportPx = boxSize * left + horizontalPadding;

    double centerTopFromViewportPx = topFromViewportPx + heightPx / 2;
    double centerLeftFromViewportPx = leftFromViewportPx + widthPx / 2;
    return Offset(centerLeftFromViewportPx, centerTopFromViewportPx);
  }

  bool contains({
    required Offset positionToCheck,
    required double boxSize,
    required Size viewSize,
    required double verticalPadding,
    required double horizontalPadding,
  }) {
    if (positionToCheck.dx <
        getLeftOffsetFromViewport(viewSize: viewSize, boxSize: boxSize, verticalPadding: verticalPadding, horizontalPadding: horizontalPadding)) {
      return false;
    }
    if (positionToCheck.dx >
        getRightOffsetFromViewport(viewSize: viewSize, boxSize: boxSize, verticalPadding: verticalPadding, horizontalPadding: horizontalPadding)) {
      return false;
    }
    if (positionToCheck.dy <
        getTopOffsetFromViewport(viewSize: viewSize, boxSize: boxSize, verticalPadding: verticalPadding, horizontalPadding: horizontalPadding)) {
      return false;
    }
    if (positionToCheck.dy >
        getBottomOffsetFromViewport(viewSize: viewSize, boxSize: boxSize, verticalPadding: verticalPadding, horizontalPadding: horizontalPadding)) {
      return false;
    }
    return true;
  }

  double getLeftOffsetFromViewport({
    required Size viewSize,
    required double boxSize,
    required double verticalPadding,
    required double horizontalPadding,
  }) {
    double leftFromViewportPx = boxSize * left + horizontalPadding;
    return leftFromViewportPx;
  }

  double getTopOffsetFromViewport({
    required Size viewSize,
    required double boxSize,
    required double verticalPadding,
    required double horizontalPadding,
  }) {
    return boxSize * top + verticalPadding;
  }

  double getRightOffsetFromViewport({
    required Size viewSize,
    required double boxSize,
    required double verticalPadding,
    required double horizontalPadding,
  }) {
    return getLeftOffsetFromViewport(
          viewSize: viewSize,
          boxSize: boxSize,
          verticalPadding: verticalPadding,
          horizontalPadding: horizontalPadding,
        ) +
        width * boxSize;
  }

  double getBottomOffsetFromViewport({
    required Size viewSize,
    required double boxSize,
    required double verticalPadding,
    required double horizontalPadding,
  }) {
    return getTopOffsetFromViewport(viewSize: viewSize, boxSize: boxSize, verticalPadding: verticalPadding, horizontalPadding: horizontalPadding) +
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
    required Size viewSize,
    required double verticalPadding,
    required double horizontalPadding,
  }) {
    return position.contains(
        positionToCheck: positionToCheck,
        boxSize: boxSize,
        viewSize: viewSize,
        verticalPadding: verticalPadding,
        horizontalPadding: horizontalPadding);
  }
}

class GridBox extends StatelessWidget {
  const GridBox({
    super.key,
    required this.show,
    required this.transitionDuration,
    required this.transitionCurve,
    required this.boxSize,
    required this.position,
    required this.background,
    required this.foreground,
    required this.child,
  });

  final double boxSize;
  final BoxPosition position;
  final Color background;
  final Color foreground;
  final Function(Box) child;
  final bool show;
  final Duration transitionDuration;
  final Curve transitionCurve;
  @override
  Widget build(BuildContext context) {
    double verticalPadding = (MediaQuery.of(context).size.height - boxSize * Constants.yCount) / 2;
    return Positioned(
      top: verticalPadding + position.top * boxSize,
      left: position.left * boxSize,
      child: AnimatedOpacity(
        opacity: show ? 1 : 0,
        duration: transitionDuration,
        curve: transitionCurve,
        child: SizedBox(
          height: boxSize * position.height,
          width: boxSize * position.width,
          child: AnimatedContainer(
            duration: transitionDuration,
            curve: transitionCurve,
            decoration: BoxDecoration(
              color: background,
              border: Border.all(
                width: Constants.edgeWidth / 2,
                color: foreground,
              ),
            ),
            child: child(Box(
              position: position,
              background: background,
              foreground: foreground,
              boxSize: boxSize,
            )),
          ),
        ),
      ),
    );
  }
}
