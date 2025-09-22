import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/views/home/home_viewmodel.dart';
import 'package:portfolio/views/project/project_viewmodel.dart';
import 'package:portfolio/widgets/animated_skew.dart';
import 'package:portfolio/widgets/boxbutton.dart';
import 'package:portfolio/widgets/cloud/cloud_view.dart';
import 'package:portfolio/widgets/forge.dart';
import 'package:portfolio/widgets/md_viewer.dart';
import 'package:portfolio/widgets/pressure_text.dart';
import 'package:stacked/stacked.dart';

class ProjectView extends StatelessWidget {
  const ProjectView({
    super.key,
    required this.project,
    required this.boxSize,
    required this.homeModel,
  });

  final Project project;
  final double boxSize;
  final HomeViewmodel homeModel;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder.reactive(
      viewModelBuilder: () => ProjectViewModel(),
      onViewModelReady: (model) => model.onInit(project),
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
                start: Coords(2, 0),
                end: Coords(3, 1),
              ),
              background: project.background,
              foreground: project.foreground,
              child: (box) => CloudView(
                tags: project.techStack,
                height: boxSize * box.position.height,
                width: boxSize * box.position.width,
                mousePositionStream: homeModel.cursorPositionStream,
                foregroundColor: project.foreground,
                backgroundColor: project.background,
                tagSize: 26,
                blur: false,
                topViewportOffset: box.position.getTopOffsetFromViewport(
                  viewSize: MediaQuery.of(context).size,
                  boxSize: boxSize,
                  verticalPadding: 0,
                  horizontalPadding: 0,
                ),
                leftViewportOffset: box.position.getLeftOffsetFromViewport(
                  viewSize: MediaQuery.of(context).size,
                  boxSize: boxSize,
                  verticalPadding: 0,
                  horizontalPadding: 0,
                ),
              ),
              // child: (box) => ClipRect(
              //   child: Stack(
              //     children: [
              //       ForgeWidget(
              //         tags: project.techStack,
              //         color: project.foreground,
              //         controller: model.forgeController,
              //       ),
              //       GestureDetector(
              //         onTap: () => model.explode(),
              //         child: Container(
              //           color: Colors.transparent,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 2,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              position: BoxPosition(
                start: Coords(3, 2),
                end: Coords(5, 3),
              ),
              background: project.background,
              foreground: project.foreground,
              child: (box) => MdViewer(
                md: project.description,
                foreground: project.foreground,
                background: project.background,
              ),
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 3,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              position: BoxPosition(
                start: Coords(4, 0),
                end: Coords(6, 0),
              ),
              background: project.background,
              foreground: project.foreground,
              child: (box) => ClipRect(
                child: TextPressure(
                  text: project.title,
                  minFontSize: boxSize * 1.3,
                  textColor: project.foreground,
                  strokeColor: project.background,
                  fontFamily: 'Compressa VF',
                  fontUrl: 'https://res.cloudinary.com/dr6lvwubh/raw/upload/v1529908256/CompressaPRO-GX.woff2',
                  width: true,
                  weight: true,
                  italic: true,
                  alpha: false,
                  flex: true,
                  scale: false,
                  boxSize: Size(box.boxSize * box.position.width, box.boxSize),
                  mousePositionStream: homeModel.cursorPositionStream,
                ),
              ),
            ),
            Builder(builder: (context) {
              BoxPosition position = BoxPosition(
                start: Coords(2, 3),
                end: Coords(2, 3),
              );
              return GridBox(
                background: project.background,
                foreground: project.foreground,
                show: homeModel.currentGridIndex >= 4,
                transitionDuration: homeModel.transitionDuration,
                transitionCurve: homeModel.transitionCurve,
                boxSize: boxSize,
                position: position,
                child: (box) => BoxButton(
                  box: box,
                  mousePositionStream: homeModel.cursorPositionStream,
                  onHovering: homeModel.onHovering,
                  onTap: () => homeModel.previousProject(),
                  invert: false,
                  child: (hovering) => Center(
                    child: AnimatedSkew(
                      skewed: hovering,
                      translateX: 30,
                      scale: 1.5,
                      child: Text(
                        'PRECEDENT',
                        style: Typos().large(color: project.background),
                      ),
                    ),
                  ),
                ),
              );
            }),
            Builder(builder: (context) {
              BoxPosition position = BoxPosition(
                start: Coords(6, 2),
                end: Coords(6, 2),
              );
              return GridBox(
                background: project.background,
                foreground: project.foreground,
                show: homeModel.currentGridIndex >= 5,
                transitionDuration: homeModel.transitionDuration,
                transitionCurve: homeModel.transitionCurve,
                boxSize: boxSize,
                position: position,
                child: (box) => BoxButton(
                  box: box,
                  mousePositionStream: homeModel.cursorPositionStream,
                  onHovering: homeModel.onHovering,
                  onTap: () => homeModel.nextProject(),
                  invert: false,
                  child: (hovering) => Center(
                    child: AnimatedSkew(
                      skewed: hovering,
                      translateX: 20,
                      scale: 1.7,
                      child: Text(
                        'SUIVANT',
                        style: Typos().large(color: project.background),
                      ),
                    ),
                  ),
                ),
              );
            }),
            Builder(builder: (context) {
              BoxPosition position = BoxPosition(
                start: Coords(4, 1),
                end: Coords(4, 1),
              );
              return GridBox(
                background: project.background,
                foreground: project.foreground,
                show: homeModel.currentGridIndex >= 6,
                transitionDuration: homeModel.transitionDuration,
                transitionCurve: homeModel.transitionCurve,
                boxSize: boxSize,
                position: position,
                child: (box) => BoxButton(
                  box: box,
                  mousePositionStream: homeModel.cursorPositionStream,
                  onHovering: homeModel.onHovering,
                  onTap: () => homeModel.goToHome(),
                  invert: true,
                  child: (hovering) => Center(
                    child: AnimatedSkew(
                      skewed: hovering,
                      translateX: 20,
                      scale: 1.7,
                      child: Text(
                        'ACCUEIL',
                        style: Typos().large(color: project.background),
                      ),
                    ),
                  ),
                ),
              );
            }),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              show: homeModel.currentGridIndex >= 7,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              position: BoxPosition(
                start: Coords(0, 0),
                end: Coords(0, 1),
              ),
              child: (box) => Image.network(
                model.project.screenshots[0],
                fit: BoxFit.cover,
              ),
            ),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              show: homeModel.currentGridIndex >= 8,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              position: BoxPosition(
                start: Coords(1, 0),
                end: Coords(1, 1),
              ),
              child: (box) => Image.network(
                model.project.screenshots[1],
                fit: BoxFit.cover,
              ),
            ),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              show: homeModel.currentGridIndex >= 9,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              position: BoxPosition(
                start: Coords(0, 2),
                end: Coords(0, 3),
              ),
              child: (box) => Image.network(
                model.project.screenshots[2],
                fit: BoxFit.cover,
              ),
            ),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              show: homeModel.currentGridIndex >= 10,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              position: BoxPosition(
                start: Coords(1, 2),
                end: Coords(1, 3),
              ),
              child: (box) => Image.network(
                model.project.screenshots[3],
                fit: BoxFit.cover,
              ),
            ),
          ],
        );
      },
    );
  }
}
