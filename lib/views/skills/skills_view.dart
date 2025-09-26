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
                onTap: model.selectedSkillCategory == null
                    ? goBack
                    : model.unselectSkills,
                invert: false,
                child: (hovering) => Center(
                  child: AnimatedSkew(
                    skewed: hovering,
                    translateX: 10,
                    child: Text(
                      '<--',
                      style: Typos(context)
                          .large(color: Shades.mainColor)
                          .copyWith(fontSize: boxSize * 0.2),
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
                Size viewSize = MediaQuery.of(context).size;
                double verticalPadding = (viewSize.height -
                        (box.boxSize * Constants.yCount(context))) /
                    2;
                double horizontalPadding = Constants.mainPadding(context);

                String text =
                    model.selectedSkillCategory?.name.toUpperCase() ?? 'SKILLS';

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
              show: homeModel.currentGridIndex >= 3 &&
                  model.about != null &&
                  model.showSkills,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              item: SkillsItems(context).cloud,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              child: (box) {
                Size viewSize = MediaQuery.of(context).size;
                double verticalPadding = (viewSize.height -
                        (box.boxSize * Constants.yCount(context))) /
                    2;
                double horizontalPadding = Constants.mainPadding(context);

                List<String> actuallTags = distributeEvenly(model.tags, 45);
                actuallTags.shuffle();

                return CloudView(
                  key: ValueKey(
                      '${model.about?.avatar}_${model.tags.join('_')}'),
                  tags: actuallTags,
                  height: boxSize * box.position.height,
                  width: boxSize * box.position.width,
                  mousePositionStream: homeModel.cursorPositionStream,
                  foregroundColor: box.foreground,
                  backgroundColor: box.background,
                  tagBuilder: (tag) {
                    bool clickable = model.isClickable(tag);
                    if (tag == '•') {
                      return Center(
                        child: Container(
                          height: 2,
                          width: 2,
                          decoration: BoxDecoration(
                            color: box.foreground.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }
                    return GestureDetector(
                      onTap: () => clickable ? model.onTagTap(tag) : null,
                      child: Hover(
                        showCursor: clickable,
                        child: (h) {
                          bool hovering = h && clickable;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 0,
                            ),
                            decoration: BoxDecoration(
                              color: hovering
                                  ? box.foreground
                                  : Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                tag,
                                style: Typos(context)
                                    .large(
                                        color: hovering
                                            ? box.background
                                            : box.foreground)
                                    .copyWith(
                                      decoration: hovering
                                          ? TextDecoration.none
                                          : clickable
                                              ? TextDecoration.underline
                                              : TextDecoration.none,
                                      decorationColor: box.foreground,
                                      decorationThickness: 2,
                                      decorationStyle:
                                          TextDecorationStyle.dotted,
                                    ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                // overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  invertDirection: true,
                  topViewportOffset: box.position.getTopOffsetFromViewport(
                      context: context, boxSize: boxSize),
                  leftViewportOffset: box.position.getLeftOffsetFromViewport(
                      context: context, boxSize: boxSize),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
