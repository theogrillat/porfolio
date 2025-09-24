import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/views/about/about_view.dart';
import 'package:portfolio/views/home/home_viewmodel.dart';
import 'package:portfolio/views/project/project_view.dart';
import 'package:portfolio/views/skills/skills_view.dart';
import 'package:portfolio/widgets/animated_skew.dart';
import 'package:portfolio/widgets/boxbutton.dart';
import 'package:portfolio/widgets/pressure_text.dart';
import 'package:stacked/stacked.dart';
import 'package:rive/rive.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, this.isUsingWasm = true});
  final bool isUsingWasm;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late AnimationController _opacityController;

  @override
  void initState() {
    super.initState();
    _opacityController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _opacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double sidebarWidth = 80;
    double edgeWidth = Constants.edgeWidth;

    return ViewModelBuilder<HomeViewmodel>.reactive(
        viewModelBuilder: () => HomeViewmodel(),
        onViewModelReady: (model) {
          double boxSize = (MediaQuery.of(context).size.width - sidebarWidth - Constants.mainPadding * 2) / Constants.xCount;
          model.onInit(boxSize: boxSize);
        },
        onDispose: (model) => model.onDispose(),
        builder: (context, model, child) {
          return AnimatedContainer(
            duration: model.transitionDuration,
            curve: model.transitionCurve,
            color: model.backgroundColor,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: LayoutBuilder(
                builder: (context, constraints) {
                  double boxSize = (constraints.maxWidth - sidebarWidth - Constants.mainPadding * 2) / Constants.xCount;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (model.boxSize != boxSize) model.updateBoxSize(boxSize);
                  });

                  return MouseRegion(
                    onEnter: (event) => model.enteredAppArea(),
                    onExit: (event) => model.exitedAppArea(),
                    onHover: (event) => model.updateCursorPosition(event.position),
                    child: Tilt(
                      fps: 60,
                      // disable: true,
                      disable: model.pauseTilt,
                      tiltStreamController: model.tiltStreamController,
                      lightConfig: LightConfig(disable: true),
                      shadowConfig: ShadowConfig(disable: true),
                      lightShadowMode: LightShadowMode.base,
                      tiltConfig: TiltConfig(
                        enableGestureSensors: false,
                        enableGestureTouch: false,
                        enableGestureHover: true,
                        filterQuality: FilterQuality.medium,
                        moveDuration: const Duration(milliseconds: 0),
                      ),
                      child: AnimatedContainer(
                        duration: model.transitionDuration,
                        color: model.backgroundColor,
                        curve: model.transitionCurve,
                        child: Stack(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: Constants.mainPadding, right: Constants.mainPadding),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        BackgroundGrid(
                                          edgeWidth: edgeWidth,
                                          transitionDuration: model.transitionDuration,
                                          transitionCurve: model.transitionCurve,
                                          color: model.foregroundColor,
                                        ),
                                        if (model.navigationState == NavigationState.home)
                                          LandingView(
                                            model: model,
                                            boxSize: boxSize,
                                            goProjects: model.goToProject,
                                            goAbout: model.goToAbout,
                                          ),
                                        if (model.navigationState == NavigationState.project)
                                          ProjectView(
                                            project: model.currentProject!,
                                            boxSize: boxSize,
                                            homeModel: model,
                                          ),
                                        if (model.navigationState == NavigationState.about)
                                          AboutView(
                                            boxSize: boxSize,
                                            goHome: model.goToHome,
                                            goSkills: model.goToSkills,
                                            homeModel: model,
                                          ),
                                        if (model.navigationState == NavigationState.skills)
                                          SkillsView(
                                            boxSize: boxSize,
                                            homeModel: model,
                                            goBack: model.goToAbout,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Builder(builder: (context) {
                                    double maxHeight = boxSize * 4;
                                    return SizedBox(
                                      height: maxHeight,
                                      width: sidebarWidth,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          RotatedBox(
                                            quarterTurns: 1,
                                            child: Row(
                                              children: [
                                                AnimatedDefaultTextStyle(
                                                  duration: model.transitionDuration,
                                                  curve: model.transitionCurve,
                                                  style: Typos().regular(
                                                    color: model.foregroundColor,
                                                  ),
                                                  child: Text(
                                                    'vous étes sur '.toUpperCase(),
                                                  ),
                                                ),
                                                AnimatedSwitcher(
                                                  duration: model.transitionDuration,
                                                  child: AnimatedDefaultTextStyle(
                                                    duration: model.transitionDuration,
                                                    curve: model.transitionCurve,
                                                    style: Typos().regular(
                                                      color: model.foregroundColor,
                                                    ),
                                                    child: Text(
                                                      model.pageTitle,
                                                      key: ValueKey(model.pageTitle),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          RotatedBox(
                                            quarterTurns: 1,
                                            child: AnimatedDefaultTextStyle(
                                              duration: model.transitionDuration,
                                              curve: model.transitionCurve,
                                              style: Typos().regular(
                                                color: model.foregroundColor,
                                              ),
                                              child: Text(
                                                'Théo GRILLAT Copyright ${DateTime.now().year} - Made W/FLUTTER'.toUpperCase(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            // MouseView(
                            //   hovering: model.isHovering,
                            //   hoveringPostion: model.hoverPosition,
                            //   defaultColor: model.foregroundColor,
                            //   hoverColor: model.backgroundColor,
                            // ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        });
  }
}

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
          transitionDuration: model.transitionDuration,
          transitionCurve: model.transitionCurve,
          background: model.backgroundColor,
          foreground: model.foregroundColor,
          boxSize: boxSize,
          position: BoxPosition(
            start: Coords(0, 0),
            end: Coords(0, 1),
          ),
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
        Builder(
          builder: (context) {
            BoxPosition position = BoxPosition(
              start: Coords(2, 0),
              end: Coords(2, 0),
            );
            return GridBox(
              show: model.currentGridIndex >= 2,
              transitionDuration: model.transitionDuration,
              transitionCurve: model.transitionCurve,
              background: model.backgroundColor,
              foreground: model.foregroundColor,
              boxSize: boxSize,
              position: position,
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: model.cursorPositionStream,
                onHovering: model.onHovering,
                onTap: goProjects,
                invert: true,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    translateX: 15,
                    child: Text(
                      'PROJETS',
                      style: Typos().large(color: Shades.mainColor),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        GridBox(
          show: model.currentGridIndex >= 3,
          transitionDuration: model.transitionDuration,
          transitionCurve: model.transitionCurve,
          background: model.backgroundColor,
          foreground: model.foregroundColor,
          boxSize: boxSize,
          position: BoxPosition(
            start: Coords(1, 1),
            end: Coords(4, 1),
          ),
          child: (box) => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: boxSize,
                  child: ClipRect(
                    child: TextPressure(
                      text: 'GRILLAT',
                      minFontSize: boxSize * 1.3,
                      textColor: box.foreground,
                      strokeColor: box.background,
                      fontFamily: 'Compressa VF',
                      fontUrl: 'https://res.cloudinary.com/dr6lvwubh/raw/upload/v1529908256/CompressaPRO-GX.woff2',
                      width: true,
                      weight: true,
                      italic: true,
                      alpha: false,
                      flex: true,
                      scale: true,
                      boxSize: Size(box.boxSize * box.position.width, box.boxSize),
                      mousePositionStream: model.cursorPositionStream,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        GridBox(
          show: model.currentGridIndex >= 4,
          transitionDuration: model.transitionDuration,
          transitionCurve: model.transitionCurve,
          background: model.backgroundColor,
          foreground: model.foregroundColor,
          boxSize: boxSize,
          position: BoxPosition(
            start: Coords(4, 2),
            end: Coords(6, 2),
          ),
          child: (box) => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: boxSize,
                  child: ClipRect(
                    child: TextPressure(
                      text: 'THEO',
                      minFontSize: boxSize * 1.3,
                      textColor: model.foregroundColor,
                      strokeColor: model.backgroundColor,
                      fontFamily: 'Compressa VF',
                      fontUrl: 'https://res.cloudinary.com/dr6lvwubh/raw/upload/v1529908256/CompressaPRO-GX.woff2',
                      width: true,
                      weight: true,
                      italic: true,
                      alpha: false,
                      flex: true,
                      scale: true,
                      boxSize: Size(box.boxSize * box.position.width, box.boxSize),
                      mousePositionStream: model.cursorPositionStream,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        GridBox(
          show: model.currentGridIndex >= 5,
          transitionDuration: model.transitionDuration,
          transitionCurve: model.transitionCurve,
          background: model.backgroundColor,
          foreground: model.foregroundColor,
          boxSize: boxSize,
          position: BoxPosition(
            start: Coords(6, 0),
            end: Coords(6, 0),
          ),
          child: (box) => RiveAnimation.asset(
            'assets/triangle.riv',
          ),
        ),
        Builder(
          builder: (context) {
            BoxPosition position = BoxPosition(
              start: Coords(3, 2),
              end: Coords(3, 2),
            );
            return GridBox(
              show: model.currentGridIndex >= 6,
              transitionDuration: model.transitionDuration,
              transitionCurve: model.transitionCurve,
              background: model.backgroundColor,
              foreground: model.foregroundColor,
              boxSize: boxSize,
              position: position,
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: model.cursorPositionStream,
                onHovering: model.onHovering,
                onTap: goAbout,
                invert: false,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    translateX: 35,
                    child: Text(
                      'QUI SUIS-JE ?',
                      style: Typos().large(color: model.backgroundColor),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        GridBox(
          show: model.currentGridIndex >= 7,
          transitionDuration: model.transitionDuration,
          transitionCurve: model.transitionCurve,
          background: model.backgroundColor,
          foreground: model.foregroundColor,
          boxSize: boxSize,
          position: BoxPosition(
            start: Coords(0, 3),
            end: Coords(1, 3),
          ),
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
        Builder(
          builder: (context) {
            BoxPosition position = BoxPosition(
              start: Coords(5, 3),
              end: Coords(5, 3),
            );
            return GridBox(
              show: model.currentGridIndex >= 8,
              transitionDuration: model.transitionDuration,
              transitionCurve: model.transitionCurve,
              background: model.backgroundColor,
              foreground: model.foregroundColor,
              boxSize: boxSize,
              position: position,
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: model.cursorPositionStream,
                onHovering: model.onHovering,
                invert: true,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    translateX: 15,
                    child: Text(
                      'CONTACT',
                      style: Typos().large(color: model.backgroundColor),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class BackgroundGrid extends StatelessWidget {
  const BackgroundGrid({
    super.key,
    required this.transitionDuration,
    required this.transitionCurve,
    required this.edgeWidth,
    required this.color,
  });

  final Duration transitionDuration;
  final Curve transitionCurve;
  final double edgeWidth;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(Constants.xCount, (int i) {
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(Constants.yCount, (int j) {
              return AspectRatio(
                aspectRatio: 1,
                child: AnimatedContainer(
                  duration: transitionDuration,
                  curve: transitionCurve,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: color,
                      width: edgeWidth,
                      strokeAlign: BorderSide.strokeAlignCenter,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
