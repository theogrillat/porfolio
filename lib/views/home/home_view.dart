import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';
import 'package:portfolio/services/tilt_service.dart' as tilt_service;
import 'package:portfolio/shared/coords.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/shared/utils.dart';
import 'package:portfolio/views/about/about_view.dart';
import 'package:portfolio/views/contact/contact_view.dart';
import 'package:portfolio/views/home/home_viewmodel.dart';
import 'package:portfolio/views/project/project_view.dart';
import 'package:portfolio/views/skills/skills_view.dart';
import 'package:portfolio/widgets/animated_skew.dart';
import 'package:portfolio/widgets/boxbutton.dart';
import 'package:portfolio/widgets/hover.dart';
import 'package:portfolio/widgets/pressure/pressure_view.dart';
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
    double edgeWidth = Constants.edgeWidth;

    return ViewModelBuilder<HomeViewmodel>.reactive(
        viewModelBuilder: () => HomeViewmodel(),
        onViewModelReady: (model) {
          model.onInit(boxSize: calcBoxSize(context));
        },
        onDispose: (model) => model.onDispose(),
        builder: (context, model, child) {
          if (model.isTiltPermissionGranted != null && !model.isTiltPermissionGranted!) {
            return Container(
              color: model.backgroundColor,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ce site nécessite\nun accès au capteur\nde mouvement pour fonctionner',
                        style: Typos(context).regular(color: model.foregroundColor),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),
                      GestureDetector(
                        onTap: () async {
                          await tilt_service.TiltService.instance.requestPermission();
                          model.updateTiltPermissionGranted(true);
                        },
                        child: Hover(
                          child: (hover) => AnimatedContainer(
                            height: 200,
                            width: 200,
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeInOutCubicEmphasized,
                            decoration: BoxDecoration(
                              color: model.foregroundColor,
                              borderRadius: hover ? BorderRadius.circular(100) : BorderRadius.zero,
                            ),
                            child: Center(
                              child: AnimatedScale(
                                scale: hover ? 0.9 : 1,
                                duration: const Duration(milliseconds: 100),
                                curve: Curves.easeInOutCubicEmphasized,
                                child: Text(
                                  'Autoriser\nl\'access',
                                  style: Typos(context).regular(color: model.backgroundColor),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return AnimatedContainer(
            duration: model.transitionDuration,
            curve: model.transitionCurve,
            color: model.backgroundColor,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double boxSize = calcBoxSize(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (model.boxSize != boxSize) model.updateBoxSize(boxSize);
                      });

                      return MouseRegion(
                        onEnter: (event) => model.enteredAppArea(),
                        onExit: (event) => model.exitedAppArea(),
                        // onHover: (event) => model.updateCursorPosition(event.position),
                        onHover: model.globalMouseRegionEventHandler,
                        child: Tilt(
                          fps: 120,
                          tiltStreamController: model.tiltStreamController,
                          lightConfig: LightConfig(disable: true),
                          shadowConfig: ShadowConfig(disable: true),
                          lightShadowMode: LightShadowMode.base,
                          tiltConfig: TiltConfig(
                            enableGestureSensors: true,
                            enableGestureTouch: false,
                            enableGestureHover: true,
                            filterQuality: FilterQuality.medium,
                            moveDuration: const Duration(milliseconds: 0),
                            angle: Breakpoints(context).isMobile() ? 15 : 10,
                          ),
                          child: AnimatedContainer(
                            duration: model.transitionDuration,
                            color: model.backgroundColor,
                            curve: model.transitionCurve,
                            child: Stack(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: Constants.mainPadding(context), right: Constants.mainPadding(context)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: boxSize * Constants.xCount(context),
                                        child: Stack(
                                          children: [
                                            BackgroundGrid(
                                              edgeWidth: edgeWidth,
                                              transitionDuration: model.transitionDuration,
                                              transitionCurve: model.transitionCurve,
                                              color: model.foregroundColor,
                                              boxSize: boxSize,
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
                                            if (model.navigationState == NavigationState.contact)
                                              ContactView(
                                                boxSize: boxSize,
                                                goHome: model.goToHome,
                                                homeModel: model,
                                              ),
                                          ],
                                        ),
                                      ),
                                      Builder(builder: (context) {
                                        double maxHeight = Constants.yCount(context) * boxSize;
                                        return SizedBox(
                                          height: maxHeight,
                                          width: Constants.sidebarWidth(context),
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
                                                      style: Typos(context).regular(
                                                        color: model.foregroundColor,
                                                      ),
                                                      child: Text('vous étes sur '.toUpperCase()),
                                                    ),
                                                    AnimatedSwitcher(
                                                      duration: model.transitionDuration,
                                                      child: AnimatedDefaultTextStyle(
                                                        duration: model.transitionDuration,
                                                        curve: model.transitionCurve,
                                                        style: Typos(context).regular(
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
                                                  style: Typos(context).regular(
                                                    color: model.foregroundColor,
                                                  ),
                                                  child: Text(
                                                    'Théo GRILLAT© ${DateTime.now().year} - Made W/FLUTTER'.toUpperCase(),
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
                  // UiDebug(model: model),
                ],
              ),
            ),
          );
        });
  }
}

class UiDebug extends StatelessWidget {
  final HomeViewmodel model;

  const UiDebug({
    super.key,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        String type = 'Unknown';
        bool isWide = Breakpoints(context).isWide();
        bool isDesktop = Breakpoints(context).isDesktop();
        bool isTablet = Breakpoints(context).isTablet();
        bool isMobile = Breakpoints(context).isMobile();

        if (isWide) type = 'Wide';
        if (isDesktop) type = 'Desktop';
        if (isTablet) type = 'Tablet';
        if (isMobile) type = 'Mobile';

        return Container(
          color: model.foregroundColor,
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(type.toUpperCase(), style: Typos(context).large(color: model.backgroundColor)),
              Text(
                'Width: ${MediaQuery.of(context).size.width.toString()}',
                style: Typos(context).regular(color: model.backgroundColor),
              ),
              Text(
                'Height: ${MediaQuery.of(context).size.height.toString()}',
                style: Typos(context).regular(color: model.backgroundColor),
              ),
              Text(''),
              Text(
                'Wide',
                style: Typos(context).regular(color: model.backgroundColor.withValues(alpha: isWide ? 1 : 0.4)),
              ),
              Text(
                'Desktop',
                style: Typos(context).regular(color: model.backgroundColor.withValues(alpha: isDesktop ? 1 : 0.4)),
              ),
              Text(
                'Tablet',
                style: Typos(context).regular(color: model.backgroundColor.withValues(alpha: isTablet ? 1 : 0.4)),
              ),
              Text(
                'Mobile',
                style: Typos(context).regular(color: model.backgroundColor.withValues(alpha: isMobile ? 1 : 0.4)),
              ),
            ],
          ),
        );
      },
    );
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
                  'PROJETS',
                  style: Typos(context).large(color: Shades.mainColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        GridBox(
          show: model.currentGridIndex >= 3,
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
                  'QUI SUIS-JE ?',
                  style: Typos(context).large(color: model.backgroundColor),
                ),
              ),
            ),
          ),
        ),
        GridBox(
          show: model.currentGridIndex >= 7,
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
                  'CONTACT',
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

class BackgroundGrid extends StatelessWidget {
  const BackgroundGrid({
    super.key,
    required this.transitionDuration,
    required this.transitionCurve,
    required this.edgeWidth,
    required this.color,
    required this.boxSize,
  });

  final Duration transitionDuration;
  final Curve transitionCurve;
  final double edgeWidth;
  final Color color;
  final double boxSize;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: boxSize * Constants.yCount(context),
        width: boxSize * Constants.xCount(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(Constants.xCount(context), (int i) {
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(Constants.yCount(context), (int j) {
                  return SizedBox(
                    width: boxSize,
                    height: boxSize,
                    child: AspectRatio(
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
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}
