import 'package:flutter/material.dart';
import 'package:flame/extensions.dart';
import 'package:portfolio/models/about.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/views/home/home_viewmodel.dart';
import 'package:portfolio/widgets/animated_skew.dart';
import 'package:portfolio/widgets/boxbutton.dart';
import 'package:portfolio/widgets/cloud/cloud_view.dart';
import 'package:portfolio/widgets/forge.dart';
import 'package:portfolio/widgets/md_viewer.dart';
import 'package:portfolio/widgets/pressure_text.dart';
import 'package:portfolio/widgets/tagcloud.dart';
import 'package:rive/rive.dart';
import 'package:stacked/stacked.dart';
import 'about_viewmodel.dart';

class AboutView extends StatelessWidget {
  const AboutView({
    super.key,
    required this.boxSize,
    required this.goHome,
    required this.homeModel,
  });

  final double boxSize;
  final Function goHome;
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
              position: BoxPosition(
                start: Coords(0, 0),
                end: Coords(1, 1),
              ),
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
              position: BoxPosition(
                start: Coords(0, 3),
                end: Coords(2, 3),
              ),
              child: (box) => Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    height: boxSize,
                    child: ClipRect(
                      child: TextPressure(
                        text: 'THEO',
                        minFontSize: boxSize * 1.3,
                        textColor: homeModel.foregroundColor,
                        strokeColor: homeModel.backgroundColor,
                        fontFamily: 'Compressa VF',
                        fontUrl: 'https://res.cloudinary.com/dr6lvwubh/raw/upload/v1529908256/CompressaPRO-GX.woff2',
                        width: true,
                        weight: true,
                        italic: true,
                        alpha: false,
                        flex: true,
                        scale: true,
                        boxSize: Size(box.boxSize * box.position.width, box.boxSize),
                        mousePositionStream: homeModel.cursorPositionStream,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 3,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              boxSize: boxSize,
              position: BoxPosition(
                start: Coords(6, 0),
                end: Coords(6, 0),
              ),
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: homeModel.cursorPositionStream,
                onHovering: homeModel.onHovering,
                onTap: goHome,
                invert: true,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    translateX: 15,
                    child: Text(
                      'ACCUEIL',
                      style: Typos().large(color: homeModel.backgroundColor),
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
              position: BoxPosition(
                start: Coords(5, 1),
                end: Coords(5, 1),
              ),
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: homeModel.cursorPositionStream,
                onHovering: homeModel.onHovering,
                onTap: goHome,
                invert: false,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    translateX: 35,
                    child: Text(
                      'COMPETENCES',
                      style: Typos().large(color: homeModel.backgroundColor),
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
              position: BoxPosition(
                start: Coords(3, 3),
                end: Coords(4, 3),
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
            GridBox(
              show: homeModel.currentGridIndex >= 6,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              boxSize: boxSize,
              position: BoxPosition(
                start: Coords(0, 2),
                end: Coords(0, 2),
              ),
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
              position: BoxPosition(
                start: Coords(2, 0),
                end: Coords(4, 2),
              ),
              child: (box) => MdViewer(
                md: model.about?.bio ?? '',
                background: homeModel.backgroundColor,
                foreground: homeModel.foregroundColor,
              ),
            ),
            // if (model.about != null)
            //   GridBox(
            //     show: homeModel.showGridItems,
            //     transitionDuration: homeModel.transitionDuration,
            //     transitionCurve: homeModel.transitionCurve,
            //     boxSize: boxSize,
            //     position: BoxPosition(
            //       start: Coords(0, 3),
            //       end: Coords(5, 3),
            //     ),
            //     background: homeModel.backgroundColor,
            //     foreground: homeModel.foregroundColor,
            //     child: (box) => ClipRect(
            //       child: Stack(
            //         children: [
            //           ForgeWidget(
            //             tags: (model.about?.mainSkills ?? []).map((e) => e.toUpperCase()).toList(),
            //             color: homeModel.foregroundColor,
            //             controller: model.forgeController,
            //             fontSize: 35,
            //           ),
            //           GestureDetector(
            //             onTap: () => model.explode(),
            //             child: Container(
            //               color: Colors.transparent,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            if (model.about != null)
              GridBox(
                show: homeModel.currentGridIndex >= 8,
                transitionDuration: homeModel.transitionDuration,
                transitionCurve: homeModel.transitionCurve,
                boxSize: boxSize,
                background: homeModel.backgroundColor,
                foreground: homeModel.foregroundColor,
                position: BoxPosition(
                  start: Coords(5, 2),
                  end: Coords(6, 3),
                ),
                child: (box) {
                  Size viewSize = MediaQuery.of(context).size;
                  double verticalPadding = (viewSize.height - (box.boxSize * Constants.yCount)) / 2;
                  double horizontalPadding = Constants.mainPadding;
                  List<String> tags = model.about?.mainSkills ?? [];
                  return CloudView(
                    tags: tags,
                    height: box.boxSize * box.position.height,
                    width: box.boxSize * box.position.width,
                    mousePositionStream: homeModel.cursorPositionStream,
                    foregroundColor: box.foreground,
                    backgroundColor: box.background,
                    topViewportOffset: box.position.getTopOffsetFromViewport(
                      viewSize: viewSize,
                      boxSize: boxSize,
                      verticalPadding: verticalPadding,
                      horizontalPadding: horizontalPadding,
                    ),
                    leftViewportOffset: box.position.getLeftOffsetFromViewport(
                      viewSize: viewSize,
                      boxSize: boxSize,
                      verticalPadding: verticalPadding,
                      horizontalPadding: horizontalPadding,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
