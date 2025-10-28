import 'package:flutter/material.dart';
import 'package:portfolio/shared/coords.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/views/home/home_viewmodel.dart';
import 'package:portfolio/widgets/animated_skew.dart';
import 'package:portfolio/widgets/boxbutton.dart';
import 'package:portfolio/widgets/pressure/pressure_view.dart';
import 'package:rive/rive.dart';

class LandingView extends StatelessWidget {
  const LandingView({
    super.key,
    required this.model,
    required this.boxSize,
    required this.goProjects,
    required this.goAbout,
  });

  final HomeViewmodel model;
  final double boxSize;
  final Function goProjects;
  final Function goAbout;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GridBox(
          show: model.currentGridIndex >= 1,
          blur: model.showMenu,
          transitionDuration: model.transitionDuration,
          transitionCurve: model.transitionCurve,
          background: model.backgroundColor,
          foreground: model.foregroundColor,
          boxSize: boxSize,
          item: LandingItems(context).semiCircle,
          child: (box) => ClipRect(
            child: Container(
              decoration: BoxDecoration(
                color: box.foreground,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(boxSize),
                  bottomRight: Radius.circular(boxSize),
                ),
              ),
            ),
          ),
        ),
        GridBox(
          show: model.currentGridIndex >= 2,
          blur: model.showMenu,
          transitionDuration: model.transitionDuration,
          transitionCurve: model.transitionCurve,
          background: model.backgroundColor,
          foreground: model.foregroundColor,
          boxSize: boxSize,
          item: LandingItems(context).projectButton,
          child: (box) => BoxButton(
            box: box,
            mousePositionStream: model.cursorPositionStream,
            onHovering: model.onHovering,
            onTap: goProjects,
            invert: true,
            child: (hovering) => Center(
              child: AnimatedSkew(
                skewed: hovering,
                width: box.boxSize,
                child: Text(
                  '/projects',
                  style: Typos(context).large(color: Shades.mainColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        GridBox(
          show: model.currentGridIndex >= 3,
          blur: model.showMenu,
          transitionDuration: model.transitionDuration,
          transitionCurve: model.transitionCurve,
          background: model.backgroundColor,
          foreground: model.foregroundColor,
          boxSize: boxSize,
          item: LandingItems(context).grillat,
          child: (box) {
            return ClipRRect(
              child: PressureView(
                text: "GRILLAT".toUpperCase(),
                mousePositionStream: model.cursorPositionStream,
                width: box.boxSize * box.position.width,
                height: box.boxSize * box.position.height,
                box: box,
                radius: boxSize * 1.5,
                minWidth: 10,
                maxWidth: 200,
                maxWeight: 1000,
                strength: 2,
                leftViewportOffset: box.position.getLeftOffsetFromViewport(
                  context: context,
                  boxSize: boxSize,
                ),
              ),
            );
          },
        ),
        GridBox(
          show: model.currentGridIndex >= 4,
          blur: model.showMenu,
          transitionDuration: model.transitionDuration,
          transitionCurve: model.transitionCurve,
          background: model.backgroundColor,
          foreground: model.foregroundColor,
          boxSize: boxSize,
          item: LandingItems(context).theo,
          child: (box) {
            return ClipRRect(
              child: PressureView(
                text: "THEO".toUpperCase(),
                mousePositionStream: model.cursorPositionStream,
                width: box.boxSize * box.position.width,
                height: box.boxSize * box.position.height,
                box: box,
                radius: boxSize * 1.5,
                maxWidth: 200,
                maxWeight: 1000,
                strength: 2,
                leftViewportOffset: box.position.getLeftOffsetFromViewport(
                  context: context,
                  boxSize: boxSize,
                ),
              ),
            );
          },
        ),
        GridBox(
          show: model.currentGridIndex >= 5,
          blur: model.showMenu,
          transitionDuration: model.transitionDuration,
          transitionCurve: model.transitionCurve,
          background: model.backgroundColor,
          foreground: model.foregroundColor,
          boxSize: boxSize,
          item: LandingItems(context).rotatingTriangle,
          child: (box) => RiveAnimation.asset('assets/triangle.riv'),
        ),
        GridBox(
          show: model.currentGridIndex >= 6,
          blur: model.showMenu,
          transitionDuration: model.transitionDuration,
          transitionCurve: model.transitionCurve,
          background: model.backgroundColor,
          foreground: model.foregroundColor,
          boxSize: boxSize,
          item: LandingItems(context).aboutButton,
          child: (box) => BoxButton(
            box: box,
            mousePositionStream: model.cursorPositionStream,
            onHovering: model.onHovering,
            onTap: goAbout,
            invert: false,
            child: (hovering) => Center(
              child: AnimatedSkew(
                skewed: hovering,
                width: box.boxSize,
                child: Text(
                  '/profile',
                  style: Typos(context).large(color: model.backgroundColor),
                ),
              ),
            ),
          ),
        ),
        GridBox(
          show: model.currentGridIndex >= 7,
          blur: model.showMenu,
          transitionDuration: model.transitionDuration,
          transitionCurve: model.transitionCurve,
          background: model.backgroundColor,
          foreground: model.foregroundColor,
          boxSize: boxSize,
          item: LandingItems(context).wideTriangle,
          child: (box) => Align(
            alignment: Alignment.centerRight,
            child: ClipRect(
              child: RiveAnimation.asset(
                'assets/wide_triangle.riv',
                alignment: Alignment.centerRight,
              ),
            ),
          ),
        ),
        GridBox(
          show: model.currentGridIndex >= 8,
          blur: model.showMenu,
          transitionDuration: model.transitionDuration,
          transitionCurve: model.transitionCurve,
          background: model.backgroundColor,
          foreground: model.foregroundColor,
          boxSize: boxSize,
          item: LandingItems(context).contactButton,
          child: (box) => BoxButton(
            box: box,
            onTap: model.goToContact,
            mousePositionStream: model.cursorPositionStream,
            onHovering: model.onHovering,
            invert: true,
            child: (hovering) => Center(
              child: AnimatedSkew(
                skewed: hovering,
                width: box.boxSize,
                child: Text(
                  '/contact',
                  style: Typos(context).large(color: model.backgroundColor),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
