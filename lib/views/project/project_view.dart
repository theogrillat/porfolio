import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/shared/coords.dart';
import 'package:portfolio/shared/extensions.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/views/home/home_viewmodel.dart';
import 'package:portfolio/views/project/project_viewmodel.dart';
import 'package:portfolio/widgets/animated_skew.dart';
import 'package:portfolio/widgets/box_action.dart';
import 'package:portfolio/widgets/boxbutton.dart';
import 'package:portfolio/widgets/hover.dart';
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
                show: homeModel.currentGridIndex >= 1 && (model.noExpanded || model.tagsExpanded),
                blur: homeModel.blurPage,
                expanded: model.tagsExpanded,
                transitionDuration: homeModel.transitionDuration,
                transitionCurve: homeModel.transitionCurve,
                boxSize: boxSize,
                item: ProjectItems(context).stack,
                background: project.background,
                foreground: project.foreground,
                child: (box) {
                  return Hover(
                    child: (h) => Stack(
                      children: [
                        Center(
                          child: TagsView(
                            key: ValueKey('cloud_${project.title}_${model.tagsExpanded ? 'expanded' : 'collapsed'}_${project.techStack.join('_')}'),
                            tags: project.techStack,
                            box: box,
                            cursorPositionStream: homeModel.cursorPositionStream,
                            foreground: project.foreground,
                            background: project.background,
                          ),
                        ),
                        BoxAction(
                          label: model.tagsExpanded ? 'réduire ><' : 'agrandir <>',
                          h: h,
                          onTap: () => model.toggleTags(),
                          background: project.background,
                          foreground: project.foreground,
                        ),
                      ],
                    ),
                  );
                }),
            GridBox(
              show: homeModel.currentGridIndex >= 3 && model.noExpanded,
              blur: homeModel.blurPage,
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
                    maxWidth: 150 / n,
                    maxWeight: 600,
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
              show: homeModel.currentGridIndex >= 4 && !homeModel.isFirstProject && model.noExpanded,
              blur: homeModel.blurPage,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: ProjectItems(context).previousButton,
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: homeModel.cursorPositionStream,
                onHovering: homeModel.onHovering,
                onTap: () {
                  model.collapseAll();
                  homeModel.previousProject();
                },
                invert: false,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    width: box.boxSize,
                    scale: 1.5,
                    child: Text(
                      '/prev',
                      style: Typos(context).large(color: project.background),
                    ),
                  ),
                ),
              ),
            ),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              show: homeModel.currentGridIndex >= 5 && !homeModel.isLastProject && model.noExpanded,
              blur: homeModel.blurPage,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: ProjectItems(context).nextButton,
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: homeModel.cursorPositionStream,
                onHovering: homeModel.onHovering,
                onTap: () {
                  model.collapseAll();
                  homeModel.nextProject();
                },
                invert: false,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    width: box.boxSize,
                    scale: 1.7,
                    child: Text(
                      '/next',
                      style: Typos(context).large(color: project.background),
                    ),
                  ),
                ),
              ),
            ),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              show: homeModel.currentGridIndex >= 6 && model.noExpanded,
              blur: homeModel.blurPage,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: ProjectItems(context).homeButton,
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: homeModel.cursorPositionStream,
                onHovering: homeModel.onHovering,
                onTap: () {
                  model.collapseAll();
                  homeModel.goToHome();
                },
                invert: true,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    width: box.boxSize,
                    child: Text(
                      '/home',
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
              show: homeModel.currentGridIndex >= 7 && model.noExpanded,
              blur: homeModel.blurPage,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: ProjectItems(context).screenshot(0, project.screenshots.map((e) => e.landscape).toList()),
              child: (box) => ProjectScreenshot(
                url: project.screenshots[0].url,
                box: box,
                onTap: (context, index, box) => model.openScreenshot(context, index, box, project),
                index: 0,
              ),
            ),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              key: ValueKey('screenshot_1_${project.screenshots[1].url}'),
              show: homeModel.currentGridIndex >= 8 && model.noExpanded,
              blur: homeModel.blurPage,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: ProjectItems(context).screenshot(1, project.screenshots.map((e) => e.landscape).toList()),
              child: (box) => ProjectScreenshot(
                url: project.screenshots[1].url,
                box: box,
                onTap: (context, index, box) => model.openScreenshot(context, index, box, project),
                index: 1,
              ),
            ),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              key: ValueKey('screenshot_2_${project.screenshots[2].url}'),
              show: homeModel.currentGridIndex >= 9 && model.noExpanded,
              blur: homeModel.blurPage,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: ProjectItems(context).screenshot(2, project.screenshots.map((e) => e.landscape).toList()),
              child: (box) => ProjectScreenshot(
                url: project.screenshots[2].url,
                box: box,
                onTap: (context, index, box) => model.openScreenshot(context, index, box, project),
                index: 2,
              ),
            ),
            GridBox(
              background: project.background,
              foreground: project.foreground,
              key: ValueKey('screenshot_3_${project.screenshots[3].url}'),
              show: homeModel.currentGridIndex >= 10 && model.noExpanded,
              blur: homeModel.blurPage,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: ProjectItems(context).screenshot(3, project.screenshots.map((e) => e.landscape).toList()),
              child: (box) => ProjectScreenshot(
                url: project.screenshots[3].url,
                box: box,
                onTap: (context, index, box) => model.openScreenshot(context, index, box, project),
                index: 3,
              ),
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 2 && (model.noExpanded || model.descriptionExpanded),
              blur: homeModel.blurPage,
              expanded: model.descriptionExpanded,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: ProjectItems(context).description,
              background: project.background,
              foreground: project.foreground,
              fakeBorders: true,
              extendRight: true,
              extendLeft: true,
              extendBottom: true,
              extendTop: true,
              child: (box) => Hover(
                showCursor: false,
                child: (h) => Stack(
                  children: [
                    MdViewer(
                      md: project.description,
                      foreground: project.foreground,
                      background: project.background,
                    ),
                    BoxAction(
                      label: model.descriptionExpanded ? 'réduire ><' : 'agrandir <>',
                      h: h,
                      onTap: () => model.toggleDescription(),
                      background: project.background,
                      foreground: project.foreground,
                    ),
                  ],
                ),
              ),
            ),
          ],
          // ]..sort((a, b) => (a as GridBox).expanded ? 1 : -1),
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
    required this.index,
  });

  final String url;
  final Box box;
  final Function(BuildContext context, int index, Box box) onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(context, index, box),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ProjectScreenshotImage(url: url, box: box),
      ),
    );
  }
}

class ProjectScreenshotImage extends StatefulWidget {
  const ProjectScreenshotImage({
    super.key,
    required this.url,
    required this.box,
  });

  final String url;
  final Box box;

  @override
  State<ProjectScreenshotImage> createState() => _ProjectScreenshotImageState();
}

class _ProjectScreenshotImageState extends State<ProjectScreenshotImage> {
  VideoPlayerController? _controller;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _checkIfVideo();
  }

  @override
  void didUpdateWidget(covariant ProjectScreenshotImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeController();
      _checkIfVideo();
    }
  }

  void _checkIfVideo() {
    try {
      final uri = Uri.parse(widget.url);
      final path = uri.path.toLowerCase();
      final extension = path.split('.').last;
      _isVideo = ['mp4', 'mov', 'webm'].contains(extension);
    } catch (e) {
      _isVideo = false;
    }

    if (_isVideo) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _controller!.setLooping(true);
            _controller!.setVolume(0);
            _controller!.play();
          }
        });
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) return Container();
    return _buildContent();
  }

  Widget _buildContent() {
    if (_isVideo && _controller != null && _controller!.value.isInitialized) {
      return IgnorePointer(
        child: RotatedBox(
          quarterTurns: 0,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
      );
    }

    if (_isVideo) {
      // Show loading or placeholder while video initializes
      return Container(
        decoration: BoxDecoration(
          color: widget.box.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: widget.box.foreground,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        key: ValueKey('img_0_${widget.url}'),
        widget.url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: widget.box.background,
            child: Center(
              child: Icon(
                Icons.broken_image,
                color: widget.box.foreground,
                size: 50,
              ),
            ),
          );
        },
      ),
    );
  }
}
