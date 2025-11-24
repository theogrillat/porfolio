import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/shared/extensions.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/shared/utils.dart';
import 'package:portfolio/views/project/project_view.dart';
import 'package:stacked/stacked.dart';
import 'screenshot_viewmodel.dart';

class ScreenshotView extends StatelessWidget {
  const ScreenshotView({
    super.key,
    required this.screenshots,
    this.initialIndex = 0,
    required this.box,
    this.isFullscreen = false,
  });

  final List<Screenshot> screenshots;
  final int initialIndex;
  final Box box;
  final bool isFullscreen;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ScreenshotViewModel>.reactive(
      viewModelBuilder: () => ScreenshotViewModel(),
      onViewModelReady: (model) => model.onInit(
        screenshots: screenshots,
        initialIndex: initialIndex,
      ),
      onDispose: (model) => model.onDispose(),
      builder: (context, model, child) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),
            IgnorePointer(
              ignoring: true,
              child: PageView(
                controller: model.pageController,
                onPageChanged: (index) => model.setCurrentIndex(index),
                children: screenshots.map((screenshot) {
                  double size = screenshot.landscape ? MediaQuery.of(context).size.width * 0.9 : MediaQuery.of(context).size.height * 0.9;
                  double height = !screenshot.landscape ? size : size / 2;
                  double width = !screenshot.landscape ? size / 2 : size;
                  return Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: ProjectScreenshotImage(
                          url: model.currentScreenshot.url,
                          box: box,
                          isFullscreen: isFullscreen,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    NavButton(
                      onTap: () => model.previous(),
                      icon: Text(
                        '<-',
                        style: Typos(context).large(color: box.background),
                      ),
                      color: box.foreground,
                    ),
                    NavButton(
                      onTap: () => model.next(),
                      icon: Text(
                        '->',
                        style: Typos(context).large(color: box.background),
                      ),
                      color: box.foreground,
                    ),
                  ],
                ),
              ),
            ),
            Builder(builder: (context) {
              double size = 20;
              return Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: (screenshots.indexed.map((e) {
                      int i = e.$1;
                      bool isActive = i == model.currentIndex;
                      return SizedBox(
                        height: size,
                        width: size,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => model.goToPage(i),
                            child: SizedBox(
                              height: size,
                              width: size,
                              child: Container(
                                  color: Colors.transparent,
                                  child: Center(
                                    child: Center(
                                      child: AnimatedContainer(
                                        curve: Curves.easeInOutCubicEmphasized,
                                        duration: const Duration(milliseconds: 150),
                                        height: isActive ? size : size / 3,
                                        width: isActive ? size : size / 3,
                                        decoration: BoxDecoration(
                                          color: box.foreground.withValues(alpha: isActive ? 1 : 0.6),
                                          borderRadius: isActive ? BorderRadius.circular(0) : BorderRadius.circular(size / 2),
                                        ),
                                      ),
                                    ),
                                  )),
                            ),
                          ),
                        ),
                      );
                    }).toList() as List<Widget>)
                        .addSeparator(SizedBox(width: 5)),
                  ),
                ),
              );
            }),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: NavButton(
                  onTap: () => Navigator.of(context).pop(),
                  icon: Text(
                    'X',
                    style: Typos(context).large(color: box.background),
                  ),
                  color: box.foreground,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class NavButton extends StatelessWidget {
  const NavButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.color,
  });

  final Function onTap;
  final Widget icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    double size = isMobileWebBrowser ? 40 : 70;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onTap(),
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size / 2),
          ),
          child: Center(
            child: icon,
          ),
        ),
      ),
    );
  }
}
