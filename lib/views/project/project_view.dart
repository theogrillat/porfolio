import 'package:flutter/material.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/shared/coords.dart';
import 'package:portfolio/shared/extensions.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/views/home/home_viewmodel.dart';
import 'package:portfolio/views/project/project_viewmodel.dart';
import 'package:portfolio/widgets/animated_skew.dart';
import 'package:portfolio/widgets/boxbutton.dart';
import 'package:portfolio/widgets/md_viewer.dart';
import 'package:portfolio/widgets/pressure/pressure_view.dart';
import 'package:portfolio/widgets/tags/tags_view.dart';
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
                item: ProjectItems(context).stack,
                background: project.background,
                foreground: project.foreground,
                child: (box) {
                  // print('tags: t.techStack: ${project.techStack}');
                  return TagsView(
                    key: ValueKey('cloud_${project.title}_${project.techStack.join('_')}'),
                    tags: project.techStack,
                    box: box,
                    cursorPositionStream: homeModel.cursorPositionStream,
                    foreground: project.foreground,
                    background: project.background,
                  );
                }),
            GridBox(
              show: homeModel.currentGridIndex >= 2,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: ProjectItems(context).description,
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
              item: ProjectItems(context).title,
              background: project.background,
              foreground: project.foreground,
              child: (box) {
                int n = project.title.length;
                return ClipRRect(
                  child: PressureView(
                    key: ValueKey('pressure_${project.title}'),
                    text: project.title.removeDiacritics().toUpperCase(),
                    mousePositionStream: homeModel.cursorPositionStream,
                    width: box.boxSize * box.position.width,
                    height: box.boxSize * box.position.height,
                    box: box,
                    radius: boxSize * 1.5,
                    minWidth: 10,
                    maxWidth: 200 / n,
                    maxWeight: 1000,
                    strength: 1.5,
                    leftViewportOffset: box.position.getLeftOffsetFromViewport(
                      context: context,
                      boxSize: boxSize,
                    ),
                  ),
                );
              },
            ),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              show: homeModel.currentGridIndex >= 4 && !homeModel.isFirstProject,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              // position: position,
              item: ProjectItems(context).previousButton,
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: homeModel.cursorPositionStream,
                onHovering: homeModel.onHovering,
                onTap: () => homeModel.previousProject(),
                invert: false,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    width: box.boxSize,
                    scale: 1.5,
                    child: Text(
                      'PRECEDENT',
                      style: Typos(context).large(color: project.background),
                    ),
                  ),
                ),
              ),
            ),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              show: homeModel.currentGridIndex >= 5 && !homeModel.isLastProject,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              // position: position,
              item: ProjectItems(context).nextButton,
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: homeModel.cursorPositionStream,
                onHovering: homeModel.onHovering,
                onTap: () => homeModel.nextProject(),
                invert: false,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    width: box.boxSize,
                    scale: 1.7,
                    child: Text(
                      'SUIVANT',
                      style: Typos(context).large(color: project.background),
                    ),
                  ),
                ),
              ),
            ),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              show: homeModel.currentGridIndex >= 6,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: ProjectItems(context).homeButton,
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: homeModel.cursorPositionStream,
                onHovering: homeModel.onHovering,
                onTap: () => homeModel.goToHome(),
                invert: true,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    width: box.boxSize,
                    child: Text(
                      'ACCUEIL',
                      style: Typos(context).large(color: project.background),
                    ),
                  ),
                ),
              ),
            ),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              key: ValueKey('screenshot_0_${project.screenshots[0].url}'),
              show: homeModel.currentGridIndex >= 7,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: ProjectItems(context).screenshot(0),
              child: (box) => ProjectScreenshot(
                url: project.screenshots[0].url,
                box: box,
                onTap: model.openScreenshot,
              ),
            ),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              key: ValueKey('screenshot_1_${project.screenshots[1].url}'),
              show: homeModel.currentGridIndex >= 8,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: ProjectItems(context).screenshot(1),
              child: (box) => ProjectScreenshot(url: project.screenshots[1].url, box: box, onTap: model.openScreenshot),
            ),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              key: ValueKey('screenshot_2_${project.screenshots[2].url}'),
              show: homeModel.currentGridIndex >= 9,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: ProjectItems(context).screenshot(2),
              child: (box) => ProjectScreenshot(url: project.screenshots[2].url, box: box, onTap: model.openScreenshot),
            ),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              key: ValueKey('screenshot_3_${project.screenshots[3].url}'),
              show: homeModel.currentGridIndex >= 10,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: ProjectItems(context).screenshot(3),
              child: (box) => ProjectScreenshot(url: project.screenshots[3].url, box: box, onTap: model.openScreenshot),
            ),
          ],
        );
      },
    );
  }
}

class ProjectScreenshot extends StatelessWidget {
  const ProjectScreenshot({
    super.key,
    required this.url,
    required this.box,
    required this.onTap,
  });

  final String url;
  final Box box;
  final Function(BuildContext context, String url, Box box) onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(context, url, box),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ProjectScreenshopImage(url: url, box: box),
      ),
    );
  }
}

class ProjectScreenshopImage extends StatelessWidget {
  const ProjectScreenshopImage({
    super.key,
    required this.url,
    required this.box,
  });

  final String url;
  final Box box;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: url,
      child: Image.network(
        key: ValueKey('img_0_$url'),
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: box.background,
            child: Center(
              child: Icon(
                Icons.broken_image,
                color: box.foreground,
                size: 50,
              ),
            ),
          );
        },
      ),
    );
  }
}
