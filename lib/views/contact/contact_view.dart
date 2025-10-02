import 'package:flutter/material.dart';
import 'package:portfolio/shared/coords.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/views/home/home_viewmodel.dart';
import 'package:portfolio/widgets/tags/tags_view.dart';
import 'package:stacked/stacked.dart';
import 'contact_viewmodel.dart';

class ContactView extends StatelessWidget {
  const ContactView({
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
    return ViewModelBuilder<ContactViewModel>.reactive(
      viewModelBuilder: () => ContactViewModel(),
      onViewModelReady: (model) => model.onInit(),
      onDispose: (model) => model.onDispose(),
      builder: (context, model, child) {
        return Stack(
          children: [
            GridBox(
              show: homeModel.currentGridIndex >= 1,
              boxSize: boxSize,
              transitionDuration: homeModel.transitionDuration,
              transitionCurve: homeModel.transitionCurve,
              item: ContactItems(context).sphere,
              background: homeModel.backgroundColor,
              foreground: homeModel.foregroundColor,
              child: (box) {
                return TagsView(
                  foreground: box.foreground,
                  background: box.background,
                  cursorPositionStream: homeModel.cursorPositionStream,
                  box: box,
                  fillUpTo: 500,
                  onTagClicked: (int tagID, __, _) {
                    if (tagID >= 0) print('tag clicked: $tagID');
                  },
                  tags: [
                    'Dart',
                    'JavaScript',
                    'TypeScript',
                    'Flutter',
                    'React',
                    'Node',
                    'Python',
                    'C#',
                    'Java',
                    'PHP',
                    'Ruby',
                    'Go',
                    'Rust',
                    'Kotlin',
                    'Swift',
                    'Haskell',
                    'Scala',
                    'SQL',
                    'HTML',
                    'CSS',
                    'JSON',
                    'YAML',
                    'Markdown',
                  ],
                  clickableTags: [
                    'Dart',
                    'JavaScript',
                    'TypeScript',
                    'Flutter',
                    'React',
                    'Node',
                    'Python',
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
