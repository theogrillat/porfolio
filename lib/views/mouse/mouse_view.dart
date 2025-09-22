import 'dart:math';
import 'package:flutter/material.dart';
import 'package:portfolio/views/mouse/mouse_follower.dart';
import 'package:portfolio/views/mouse/mouse_viewmodel.dart';
import 'package:stacked/stacked.dart';

class MouseView extends StatelessWidget {
  const MouseView({
    super.key,
    required this.hovering,
    required this.hoveringPostion,
    required this.defaultColor,
    required this.hoverColor,
  });

  final bool hovering;
  final Offset? hoveringPostion;
  final Color defaultColor;
  final Color hoverColor;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MouseViewModel>.reactive(
      viewModelBuilder: () => MouseViewModel(),
      onViewModelReady: (model) => model.onInit(),
      onDispose: (model) => model.onDispose(),
      builder: (context, model, child) {
        return MouseRegion(
          // hitTestBehavior: HitTestBehavior.deferToChild,
          cursor: SystemMouseCursors.none,
          opaque: false,
          onEnter: model.onEnter,
          onExit: model.onExit,
          onHover: (event) => model.onHover(event, hoveringPostion),
          child: Stack(
            children: [
              Positioned(
                top: model.y - 10,
                left: model.x - 10,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  opacity: model.isIn ? 1 : 0,
                  child: Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: hovering ? hoverColor : defaultColor,
                    ),
                  ),
                ),
              ),
              ..._buildMouseFollowers(
                model: model,
                count: 5,
                hoveringPostion: hoveringPostion,
                hovering: hovering,
                hoverColor: hoverColor,
                defaultColor: defaultColor,
              ),
            ],
          ),
        );
      },
    );
  }
}

List<Widget> _buildMouseFollowers({
  required MouseViewModel model,
  required int count,
  required Offset? hoveringPostion,
  required bool hovering,
  required Color hoverColor,
  required Color defaultColor,
}) {
  return List.generate(
    count,
    (index) => MouseFollower(
      hoveringPostion: hoveringPostion,
      hovering: hovering,
      hoverColor: hoverColor,
      defaultColor: defaultColor,
      y: model.y,
      x: model.x,
      isIn: model.isIn,
      seed: index,
      count: count,
      trailDelay: 0,
    ),
  );
}
