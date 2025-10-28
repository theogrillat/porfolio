import 'package:flutter/material.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/views/home/home_viewmodel.dart';
import 'package:stacked/stacked.dart';
import 'tooltips_viewmodel.dart';

class TooltipsView extends StatelessWidget {
  const TooltipsView({
    super.key,
    required this.cursorPositionStream,
    required this.background,
    required this.foreground,
    required this.navState,
    required this.boxSize,
  });

  final Stream<Offset?> cursorPositionStream;
  final Color background;
  final Color foreground;
  final NavigationState navState;
  final double boxSize;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<TooltipsViewModel>.reactive(
      viewModelBuilder: () => TooltipsViewModel(),
      onViewModelReady: (model) => model.onInit(
        cursorPositionStream: cursorPositionStream,
        context: context,
        boxSize: boxSize,
      ),
      onDispose: (model) => model.onDispose(),
      builder: (context, model, child) {
        return Stack(
          children: [
            Positioned(
              top: (model.cursorPosition?.dy ?? 0) + 10,
              left: (model.cursorPosition?.dx ?? 0) + 10,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: model.cursorPosition != null && model.tooltip != null && model.tooltip!.isNotEmpty ? 1 : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: foreground,
                  ),
                  child: Text(
                    model.tooltip ?? '',
                    style: Typos(context).regular(color: background),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
