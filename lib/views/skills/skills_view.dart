import 'package:flutter/material.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/widgets/animated_skew.dart';
import 'package:portfolio/widgets/boxbutton.dart';
import 'package:portfolio/widgets/cloud/cloud_view.dart';
import 'package:portfolio/widgets/hover.dart';
import 'package:portfolio/widgets/pressure_text.dart';
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
              position: BoxPosition(
                start: Coords(0, 3),
                end: Coords(0, 3),
              ),
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
                    translateX: 10,
                    child: Text(
                      '<--',
                      style: Typos().large(color: Shades.mainColor).copyWith(fontSize: boxSize * 0.2),
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
              position: BoxPosition(
                start: Coords(0, 0),
                end: Coords(6, 0),
              ),
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              child: (box) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: boxSize,
                      child: ClipRect(
                        child: TextPressure(
                          text: model.selectedSkillCategory?.name.toUpperCase() ?? 'COMPETENCES',
                          minFontSize: boxSize * 1.3,
                          textColor: box.foreground,
                          strokeColor: box.background,
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
                  ),
                ],
              ),
            ),
            GridBox(
              show: homeModel.currentGridIndex >= 3 && model.about != null && model.showSkills,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              boxSize: boxSize,
              position: BoxPosition(
                start: Coords(2, 1),
                end: Coords(6, 3),
              ),
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              child: (box) {
                Size viewSize = MediaQuery.of(context).size;
                double verticalPadding = (viewSize.height - (box.boxSize * Constants.yCount)) / 2;
                double horizontalPadding = Constants.mainPadding;
                return CloudView(
                  key: ValueKey('${model.about?.avatar}_${model.tags.join('_')}'),
                  tags: model.tags,
                  height: boxSize * box.position.height,
                  width: boxSize * box.position.width,
                  mousePositionStream: homeModel.cursorPositionStream,
                  foregroundColor: box.foreground,
                  backgroundColor: box.background,
                  tagBuilder: (tag) {
                    bool clickable = model.isClickable(tag);
                    return Hover(
                      showCursor: clickable,
                      child: (h) {
                        bool hovering = h && clickable;
                        return GestureDetector(
                          onTap: () => clickable ? model.onTagTap(tag) : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                            decoration: BoxDecoration(
                              color: hovering ? box.foreground : Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                tag,
                                style: Typos().large(color: hovering ? box.background : box.foreground).copyWith(
                                      decoration: hovering
                                          ? TextDecoration.none
                                          : clickable
                                              ? TextDecoration.underline
                                              : TextDecoration.none,
                                      decorationColor: box.foreground,
                                      decorationThickness: 2,
                                      decorationStyle: TextDecorationStyle.dotted,
                                    ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                // overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  invertDirection: true,
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
