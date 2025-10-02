import 'package:flutter/material.dart';
import 'package:portfolio/shared/coords.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/shared/utils.dart';
import 'package:portfolio/widgets/animated_skew.dart';
import 'package:portfolio/widgets/boxbutton.dart';
import 'package:portfolio/widgets/hover.dart';
import 'package:portfolio/widgets/pressure/pressure_view.dart';
import 'package:portfolio/widgets/tags/tags_view.dart';
import 'package:stacked/stacked.dart';
import 'package:portfolio/views/home/home_viewmodel.dart';
import 'skills_viewmodel.dart';

class SkillsView extends StatelessWidget {
  const SkillsView({
    super.key,
    required this.boxSize,
    required this.homeModel,
    required this.goBack,
  });

  final double boxSize;
  final HomeViewmodel homeModel;
  final Function goBack;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SkillsViewModel>.reactive(
      viewModelBuilder: () => SkillsViewModel(),
      onViewModelReady: (model) => model.onInit(
        projects: homeModel.prjs,
      ),
      onDispose: (model) => model.onDispose(),
      builder: (context, model, child) {
        return Stack(
          children: [
            GridBox(
              show: homeModel.currentGridIndex >= 1,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: SkillsItems(context).backButton,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: homeModel.cursorPositionStream,
                onHovering: homeModel.onHovering,
                onTap: goBack,
                invert: false,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    width: box.boxSize,
                    child: Text(
                      '/back',
                      style: Typos(context).large(color: Shades.mainColor),
                    ),
                  ),
                ),
              ),
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 2,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: SkillsItems(context).title,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              child: (box) {
                String text = model.selectedSkillCategory?.name.toUpperCase() ?? 'SKILLS';

                return ClipRRect(
                  child: PressureView(
                    text: text,
                    key: ValueKey(text),
                    mousePositionStream: homeModel.cursorPositionStream,
                    width: box.boxSize * box.position.width,
                    height: box.boxSize * box.position.height,
                    box: box,
                    radius: 200,
                    maxWidth: 200,
                    maxWeight: 1000,
                    strength: 3,
                    leftViewportOffset: box.position.getLeftOffsetFromViewport(
                      context: context,
                      boxSize: boxSize,
                    ),
                  ),
                );
              },
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 3 && model.about != null && model.showSkills,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: SkillsItems(context).cloud,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              child: (box) {
                return Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: homeModel.transitionDuration,
                      switchInCurve: homeModel.transitionCurve,
                      switchOutCurve: homeModel.transitionCurve,
                      child: TagsView(
                        key: ValueKey(model.tags.join('_')),
                        background: box.background,
                        foreground: box.foreground,
                        cursorPositionStream: homeModel.cursorPositionStream,
                        box: box,
                        fillUpTo: 500,
                        tags: model.tags,
                        clickableTags: model.clickableTags,
                        onTagClicked: (id, text, pos) => model.onTagTap(id, text, pos, (skill) => homeModel.filterProjects(skill)),
                        initialCursorPosition: model.lastClickPosition,
                      ),
                    ),
                    if (model.selectedSkillCategory != null)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Hover(
                          showCursor: true,
                          child: (h) => GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: model.unselectSkills,
                            child: Container(
                              height: isPortrait(context) ? 55 : homeModel.menuButtonSize(context) - Constants.edgeWidth * 2,
                              padding: const EdgeInsets.only(left: 15, right: 15),
                              decoration: BoxDecoration(
                                color: homeModel.foregroundColor,
                              ),
                              child: Opacity(
                                opacity: h ? 0.5 : 1,
                                child: Center(
                                  child: Text(
                                    '<- Categories'.toUpperCase(),
                                    style: Typos(context).large(color: homeModel.backgroundColor),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
