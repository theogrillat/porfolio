import 'package:flutter/material.dart';
import 'package:portfolio/shared/coords.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/shared/utils.dart';
import 'package:portfolio/widgets/animated_skew.dart';
import 'package:portfolio/widgets/boxbutton.dart';
import 'package:portfolio/widgets/cloud/cloud_view.dart';
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
              item: SkillsItems(context).backButton,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              child: (box) => BoxButton(
                box: box,
                mousePositionStream: homeModel.cursorPositionStream,
                onHovering: homeModel.onHovering,
                onTap: model.selectedSkillCategory == null ? goBack : model.unselectSkills,
                invert: false,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    width: box.boxSize,
                    child: Text(
                      '<--',
                      style: Typos(context).large(color: Shades.mainColor).copyWith(fontSize: boxSize * 0.2),
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
                return AnimatedSwitcher(
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
                    onTagClicked: (id, pos) => model.onTagTap(id, pos),
                    initialCursorPosition: model.lastClickPosition,
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
