import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';
import 'package:portfolio/services/tilt_service.dart' as tilt_service;
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/shared/utils.dart';
import 'package:portfolio/views/about/about_view.dart';
import 'package:portfolio/views/contact/contact_view.dart';
import 'package:portfolio/views/home/home_viewmodel.dart';
import 'package:portfolio/views/home/landing_view.dart';
import 'package:portfolio/views/project/project_view.dart';
import 'package:portfolio/views/skills/skills_view.dart';
import 'package:portfolio/widgets/hover.dart';
import 'package:portfolio/widgets/menu/menu_view.dart';
import 'package:stacked/stacked.dart';

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
                                            MenuView(
                                              boxSize: boxSize,
                                              homeModel: model,
                                            ),
                                            MenuBarrier(
                                              boxSize: boxSize,
                                              homeModel: model,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isPortrait(context))
                                        LandscapeSideBar(
                                          model: model,
                                          boxSize: boxSize,
                                        ),
                                    ],
                                  ),
                                ),
                                if (isPortrait(context))
                                  PortraitSideBarTop(
                                    model: model,
                                    boxSize: boxSize,
                                  ),
                                  if (isPortrait(context))
                                    PortraitSideBarBottom(
                                      model: model,
                                      boxSize: boxSize,
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

class LandscapeSideBar extends StatelessWidget {
  const LandscapeSideBar({
    super.key,
    required this.model,
    required this.boxSize,
  });

  final HomeViewmodel model;
  final double boxSize;

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      double maxHeight = (Constants.yCount(context) * boxSize) + ((Constants.yCount(context) - 3)) * Constants.edgeWidth;
      double menuButtonPadding = 20;
      double menuButtonHeight = model.menuButtonSize(context);
      return SizedBox(
        height: maxHeight,
        width: Constants.sidebarWidth(context),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubicEmphasized,
              height: model.showMenuButton ? menuButtonHeight + menuButtonPadding : 0,
              padding: EdgeInsets.only(bottom: model.showMenuButton ? menuButtonPadding : 0),
              child: Opacity(
                opacity: model.showMenuButton ? 1 : 0,
                child: ClipRRect(
                  child: Hover(
                    showCursor: true,
                    child: (h) => GestureDetector(
                      onTap: model.toggleMenu,
                      child: AnimatedContainer(
                        duration: model.transitionDuration,
                        curve: model.transitionCurve,
                        height: menuButtonHeight,
                        decoration: BoxDecoration(
                          color: model.foregroundColor,
                        ),
                        child: Center(
                          child: Opacity(
                            opacity: h ? 0.5 : 1,
                            child: AnimatedDefaultTextStyle(
                              duration: model.transitionDuration,
                              curve: model.transitionCurve,
                              style: Typos(context).regular(
                                color: model.backgroundColor,
                              ),
                              child: Text(
                                model.showMenu ? 'X' : '/menu',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                final style = Typos(context).regular(
                  color: model.foregroundColor,
                );

                final vousEtesSurPainter = TextPainter(
                  text: TextSpan(text: 'vous étes sur '.toUpperCase(), style: style),
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                )..layout(minWidth: 0, maxWidth: double.infinity);

                final pageTitlePainter = TextPainter(
                  text: TextSpan(text: model.pageTitle, style: style),
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                )..layout(minWidth: 0, maxWidth: double.infinity);

                final topTextWidth = vousEtesSurPainter.width + pageTitlePainter.width;

                final bottomTextPainter = TextPainter(
                  text: TextSpan(text: 'Théo GRILLAT© ${DateTime.now().year} - Made W/FLUTTER'.toUpperCase(), style: style),
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                )..layout(minWidth: 0, maxWidth: double.infinity);

                final bottomTextWidth = bottomTextPainter.width;

                // Height of rotated text is width. Add some spacing.
                final requiredHeight = topTextWidth + bottomTextWidth + 20;

                final canShowBottomText = constraints.maxHeight > requiredHeight;

                return Column(
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
                    if (canShowBottomText)
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
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}

class PortraitSideBarTop extends StatelessWidget {
  const PortraitSideBarTop({
    super.key,
    required this.model,
    required this.boxSize,
  });

  final HomeViewmodel model;
  final double boxSize;

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      double maxWidth = (Constants.xCount(context) * boxSize) + ((Constants.xCount(context) - 3)) * Constants.edgeWidth;
      double gridHeight = boxSize * Constants.yCount(context);
      double viewHeight = MediaQuery.of(context).size.height;
      double topPadding = (viewHeight - gridHeight) / 2;
      double menuButtonPadding = 20;
      double menuButtonHeight = model.menuButtonSize(context);
      return Positioned(
        top: topPadding - menuButtonHeight,
        left: 0,
        right: 0,
        child: Center(
          child: SizedBox(
            // height: Constants.sidebarWidth(context),
            height: menuButtonHeight,
            width: maxWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
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
                      // RotatedBox(
                      //   quarterTurns: 0,
                      //   child: AnimatedDefaultTextStyle(
                      //     duration: model.transitionDuration,
                      //     curve: model.transitionCurve,
                      //     style: Typos(context).regular(
                      //       color: model.foregroundColor,
                      //     ),
                      //     child: Text(
                      //       'Théo GRILLAT© ${DateTime.now().year} - Made W/FLUTTER'.toUpperCase(),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubicEmphasized,
                  height: model.showMenuButton ? menuButtonHeight + menuButtonPadding : 0,
                  child: Opacity(
                    opacity: model.showMenuButton ? 1 : 0,
                    child: ClipRRect(
                      child: Hover(
                        showCursor: true,
                        child: (h) => GestureDetector(
                          onTap: model.toggleMenu,
                          child: AnimatedContainer(
                            duration: model.transitionDuration,
                            curve: model.transitionCurve,
                            height: menuButtonHeight,
                            width: 75,
                            decoration: BoxDecoration(
                              color: model.foregroundColor,
                            ),
                            child: Center(
                              child: Opacity(
                                opacity: h ? 0.5 : 1,
                                child: AnimatedDefaultTextStyle(
                                  duration: model.transitionDuration,
                                  curve: model.transitionCurve,
                                  style: Typos(context).regular(
                                    color: model.backgroundColor,
                                  ),
                                  child: Text(
                                    model.showMenu ? 'X' : '/menu',
                                  ),
                                ),
                              ),
                            ),
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
    });
  }
}

class PortraitSideBarBottom extends StatelessWidget {
  const PortraitSideBarBottom({
    super.key,
    required this.model,
    required this.boxSize,
  });

  final HomeViewmodel model;
  final double boxSize;

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      double maxWidth = (Constants.xCount(context) * boxSize) + ((Constants.xCount(context) - 3)) * Constants.edgeWidth;
      double gridHeight = boxSize * Constants.yCount(context);
      double viewHeight = MediaQuery.of(context).size.height;
      double topPadding = (viewHeight - gridHeight) / 2;
      double menuButtonHeight = model.menuButtonSize(context);
      return Positioned(
        top: topPadding + gridHeight,
        left: 0,
        right: 0,
        child: Center(
          child: SizedBox(
            height: menuButtonHeight,
            width: maxWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: model.transitionDuration,
                        curve: model.transitionCurve,
                        style: Typos(context).regular(
                          color: model.foregroundColor,
                        ),
                        child: Text(
                          'Théo GRILLAT© ${DateTime.now().year}'.toUpperCase(),
                        ),
                      ),
                      AnimatedDefaultTextStyle(
                        duration: model.transitionDuration,
                        curve: model.transitionCurve,
                        style: Typos(context).regular(
                          color: model.foregroundColor,
                        ),
                        child: Text(
                          'Made W/FLUTTER'.toUpperCase(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
