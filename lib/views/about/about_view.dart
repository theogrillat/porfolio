import 'package:flutter/material.dart';
import 'package:portfolio/shared/coords.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/views/home/home_viewmodel.dart';
import 'package:portfolio/widgets/animated_skew.dart';
import 'package:portfolio/widgets/boxbutton.dart';
import 'package:portfolio/widgets/cloud/cloud_view.dart';
import 'package:portfolio/widgets/md_viewer.dart';
import 'package:portfolio/widgets/pressure/pressure_view.dart';
import 'package:portfolio/widgets/tags/tags_view.dart';
import 'package:rive/rive.dart';
import 'package:stacked/stacked.dart';
import 'about_viewmodel.dart';

class AboutView extends StatelessWidget {
  const AboutView({
    super.key,
    required this.boxSize,
    required this.goHome,
    required this.goSkills,
    required this.homeModel,
  });

  final double boxSize;
  final Function goHome;
  final Function goSkills;
  final HomeViewmodel homeModel;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AboutViewModel>.reactive(
      viewModelBuilder: () => AboutViewModel(),
      onViewModelReady: (model) => model.onInit(),
      onDispose: (model) => model.onDispose(),
      builder: (context, model, child) {
        return Stack(
          children: [
            GridBox(
              show: homeModel.currentGridIndex >= 1,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: AboutItems(context).avatar,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              child: (box) => model.about != null
                  ? Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(model.about?.avatar ?? ''),
                          fit: BoxFit.cover,
                          onError: (error, stackTrace) {
                            print('-----');
                            print(error);
                            print('-----');
                          },
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 2,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              boxSize: boxSize,
              // position: BoxPosition(
              //   start: Coords(0, 3),
              //   end: Coords(2, 3),
              // ),
              item: AboutItems(context).theo,
              child: (box) {
                return ClipRRect(
                  child: PressureView(
                    text: "THEO".toUpperCase(),
                    mousePositionStream: homeModel.cursorPositionStream,
                    width: box.boxSize * box.position.width,
                    height: box.boxSize * box.position.height,
                    box: box,
                    radius: 200,
                    maxWidth: 200,
                    maxWeight: 1000,
                    strength: 2,
                    leftViewportOffset: box.position.getLeftOffsetFromViewport(context: context, boxSize: boxSize),
                  ),
                );
              },
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 3,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              boxSize: boxSize,
              // position: BoxPosition(
              //   start: Coords(6, 0),
              //   end: Coords(6, 0),
              // ),
              item: AboutItems(context).homeButton,
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: homeModel.cursorPositionStream,
                onHovering: homeModel.onHovering,
                onTap: goHome,
                invert: true,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    width: box.boxSize,
                    child: Text(
                      'ACCUEIL',
                      style: Typos(context).large(color: homeModel.backgroundColor),
                    ),
                  ),
                ),
              ),
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 4,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              boxSize: boxSize,
              item: AboutItems(context).skillsButton,
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: homeModel.cursorPositionStream,
                onHovering: homeModel.onHovering,
                onTap: goSkills,
                invert: false,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    width: box.boxSize,
                    child: Text(
                      'COMPETENCES',
                      style: Typos(context).large(color: homeModel.backgroundColor),
                    ),
                  ),
                ),
              ),
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 5,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              boxSize: boxSize,
              // position: BoxPosition(
              //   start: Coords(3, 3),
              //   end: Coords(4, 3),
              // ),
              item: AboutItems(context).wideTriangle,
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
              show: homeModel.currentGridIndex >= 6,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              boxSize: boxSize,
              // position: BoxPosition(
              //   start: Coords(0, 2),
              //   end: Coords(0, 2),
              // ),
              item: AboutItems(context).rotatingTriangle,
              child: (box) => RiveAnimation.asset(
                'assets/triangle.riv',
              ),
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 7,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              // position: BoxPosition(
              //   start: Coords(2, 0),
              //   end: Coords(4, 2),
              // ),
              item: AboutItems(context).bio,
              child: (box) => MdViewer(
                md: model.about?.bio ?? '',
                background: homeModel.backgroundColor,
                foreground: homeModel.foregroundColor,
              ),
            ),
            if (model.about != null)
              GridBox(
                show: homeModel.currentGridIndex >= 8,
                transitionDuration: homeModel.transitionDuration,
                transitionCurve: homeModel.transitionCurve,
                boxSize: boxSize,
                background: homeModel.backgroundColor,
                foreground: homeModel.foregroundColor,
                item: AboutItems(context).skills,
                child: (box) {
                  List<String> tags = model.about?.mainSkills ?? [];
                  return TagsView(
                    tags: tags,
                    box: box,
                    cursorPositionStream: homeModel.cursorPositionStream,
                    background: box.background,
                    foreground: box.foreground,
                    fillUpTo: 0,
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
