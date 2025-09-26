import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:portfolio/shared/styles.dart';

class MdViewer extends StatelessWidget {
  const MdViewer({
    super.key,
    required this.md,
    required this.foreground,
    required this.background,
  });

  final String md;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    TextStyle baseStyle = Typos(context).large(
      color: foreground,
      height: 1.2,
    );
    ScrollController controller = ScrollController();
    return Theme(
      data: Theme.of(context).copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: WidgetStateProperty.all(true),
          trackVisibility: WidgetStateProperty.all(false),
          thickness: WidgetStateProperty.all(10.0),
          radius: const Radius.circular(0.0),
          thumbColor: WidgetStateProperty.all(foreground),
          trackColor: WidgetStateProperty.all(background),
          trackBorderColor: WidgetStateProperty.all(background),
          crossAxisMargin: 0,
          mainAxisMargin: 0,
          interactive: true,
        ),
      ),
      child: Scrollbar(
        thickness: 25,
        interactive: true,
        controller: controller,
        child: SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: MarkdownBody(
              data: md,
              styleSheet: MarkdownStyleSheet(
                em: baseStyle,
                p: baseStyle,
                h1: baseStyle,
                h2: baseStyle,
                h3: baseStyle,
                h4: baseStyle,
                h5: baseStyle,
                h6: baseStyle,
                listBullet: baseStyle,
                strong: baseStyle.copyWith(
                  backgroundColor: foreground,
                  color: background,
                ),
                blockSpacing: 24.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
