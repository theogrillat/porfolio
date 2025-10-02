import 'package:flutter/material.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/shared/utils.dart';
import 'package:portfolio/widgets/tags/tag_model.dart';
import 'package:stacked/stacked.dart';
import 'tags_viewmodel.dart';

class TagsView extends StatefulWidget {
  const TagsView({
    super.key,
    required this.tags,
    this.clickableTags = const [],
    this.onTagClicked,
    required this.foreground,
    required this.background,
    required this.cursorPositionStream,
    required this.box,
    this.fillUpTo,
    this.inverted = false,
    this.sphereMargin,
    this.initialCursorPosition,
  });

  final List<String> tags;
  final List<String> clickableTags;
  final Function(int, String, Offset?)? onTagClicked;
  final Color foreground;
  final Color background;
  final double? sphereMargin;
  final Stream<Offset?> cursorPositionStream;
  final Box box;
  final bool inverted;
  final int? fillUpTo;
  final Offset? initialCursorPosition;

  @override
  State<TagsView> createState() => _TagsViewState();
}

class _TagsViewState extends State<TagsView> with SingleTickerProviderStateMixin {
  TagsViewModel? _viewModel;

  @override
  void didUpdateWidget(TagsView oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool tagsChanged = !listEquals(widget.tags, oldWidget.tags);
    bool clickableTagsChanged = !listEquals(widget.clickableTags, oldWidget.clickableTags);
    bool fillUpToChanged = widget.fillUpTo != oldWidget.fillUpTo;
    bool invertedChanged = widget.inverted != oldWidget.inverted;
    bool sphereMarginChanged = widget.sphereMargin != oldWidget.sphereMargin;
    bool foregroundChanged = widget.foreground != oldWidget.foreground;
    bool backgroundChanged = widget.background != oldWidget.background;

    if (tagsChanged || clickableTagsChanged || fillUpToChanged || invertedChanged || sphereMarginChanged || foregroundChanged || backgroundChanged) {
      _viewModel?.updateTags(
        tags: widget.tags,
        clickableTags: widget.clickableTags,
        sphereMargin: widget.sphereMargin,
        fillUpTo: widget.fillUpTo,
        inverted: widget.inverted,
        context: context,
      );
    }
  }

  /// Builds platform-specific widget based on browser type
  Widget _buildPlatformSpecificWidget(TagsViewModel model) {
    final canvas = ClipRRect(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(model.width, model.height),
          painter: OptimizedTagsPainter(
            tags: model.allTags,
            minSize: model.minSize,
            maxSize: model.maxSize,
            foregroundColor: widget.foreground,
            backgroundColor: widget.background,
            textStyle: Typos(context).tag(color: widget.foreground),
            breakpoints: Breakpoints(context),
            hoveredTag: isMobileWebBrowser ? null : model.hoveredTag,
            boxSize: widget.box.boxSize,
          ),
        ),
      ),
    );

    if (isDesktopWebBrowser) {
      // Desktop: Use MouseRegion for cursor interaction
      return MouseRegion(
        cursor: model.hoveredTag != null && model.hoveredTag!.isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: () {
            print('Click detected');
            if (widget.onTagClicked != null) {
              final tag = model.hoveredTag;
              if (tag != null) {
                widget.onTagClicked!(tag.clickID!, tag.text, model.lastCursorPosition);
              }
            }
          },
          child: canvas,
        ),
      );
    } else {
      // Mobile: Use GestureDetector for touch interaction
      return GestureDetector(
        onTapDown: (event) {
          if (widget.onTagClicked != null) {
            print('Tap detected at: ${event.localPosition}');
            final tag = model.getTappedTag(event.localPosition, 45);
            if (tag != null) {
              print('Tag tapped: ${tag.clickID} ${tag.text}');
              widget.onTagClicked!(tag.clickID!, tag.text, model.lastCursorPosition);
            }
          }
        },
        onPanStart: (details) {
          model.startDrag(details.globalPosition);
        },
        onPanUpdate: (details) {
          model.updateDrag(details.globalPosition, details.delta);
        },
        onPanEnd: (details) {
          model.endDrag(details.velocity);
        },
        child: canvas,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ViewModelBuilder<TagsViewModel>.reactive(
          viewModelBuilder: () => TagsViewModel(),
          onViewModelReady: (model) {
            _viewModel = model;
            model.onInit(
              vsync: this,
              tags: widget.tags,
              clickableTags: widget.clickableTags,
              sphereMargin: widget.sphereMargin,
              cursorPositionStream: widget.cursorPositionStream,
              box: widget.box,
              inverted: widget.inverted,
              fillUpTo: widget.fillUpTo,
              initialCursorPosition: widget.initialCursorPosition,
              context: context,
            );
          },
          onDispose: (model) => model.onDispose(),
          builder: (context, model, child) {
            // Update layout when constraints change
            WidgetsBinding.instance.addPostFrameCallback((_) {
              model.onResize(widget.box, widget.sphereMargin, context);
            });
            return _buildPlatformSpecificWidget(model);
          },
        );
      },
    );
  }
}

class OptimizedTagsPainter extends CustomPainter {
  final List<Tag> tags;
  final double minSize;
  final double maxSize;
  final Color foregroundColor;
  final Color backgroundColor;
  final TextStyle textStyle;
  final Breakpoints breakpoints;
  final Tag? hoveredTag;
  final double boxSize;

  static final Map<String, TextPainter> _textPainterCache = {};

  static final Paint _circlePaint = Paint()..style = PaintingStyle.fill;

  OptimizedTagsPainter({
    required this.tags,
    required this.minSize,
    required this.maxSize,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.textStyle,
    required this.breakpoints,
    required this.hoveredTag,
    required this.boxSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final minSizeValue = minSize;
    final sizeRange = maxSize - minSizeValue;

    // First, paint all non-hovered tags
    tags.sort((a, b) => a.size.compareTo(b.size));
    for (final tag in tags) {
      if (tag == hoveredTag) continue; // Skip hovered tag for now

      _paintTag(canvas, tag, minSizeValue, sizeRange, isHovered: false);
    }

    // Then paint the hovered tag on top (if it exists)
    if (hoveredTag != null) {
      _paintTag(canvas, hoveredTag!, minSizeValue, sizeRange, isHovered: true);
    }
  }

  void _paintTag(Canvas canvas, Tag tag, double minSizeValue, double sizeRange, {required bool isHovered}) {
    final normalizedSize = (tag.size - minSizeValue) / sizeRange;
    final scale = 1.0 + (normalizedSize * 2.0); // 1.0 to 3.0
    final opacity = (0.1 + (normalizedSize * 0.9)).clamp(0.5, 1.0); // 0.0 to 1 to 1.0

    canvas.save();
    canvas.translate(tag.x, tag.y);
    canvas.scale(scale);

    if (tag.text == '•') {
      _circlePaint.color = foregroundColor.withValues(alpha: opacity);
      double radius = 0.5;
      if (breakpoints.isMobile()) {
        radius = 0.5;
      }
      canvas.drawCircle(
        Offset(radius, radius),
        radius / 2,
        _circlePaint,
      );
    } else {
      final TextPainter textPainter;

      if (opacity < 1.0) {
        textPainter = _createTextPainter(
          text: tag.text,
          isClickable: tag.isClickable,
          isHovered: isHovered,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          opacity: opacity,
          style: isMobileWebBrowser
              ? textStyle.copyWith(
                  color: tag.isClickable ? backgroundColor : textStyle.color?.withValues(alpha: opacity),
                  backgroundColor: tag.isClickable ? foregroundColor : null,
                  decoration: TextDecoration.none,
                  fontSize: boxSize * 0.03 * 2,
                )
              : textStyle.copyWith(
                  color: isHovered && tag.isClickable ? backgroundColor : textStyle.color?.withValues(alpha: opacity),
                  backgroundColor: isHovered && tag.isClickable ? foregroundColor : null,
                  decorationStyle: TextDecorationStyle.dotted,
                  decoration: tag.isClickable && !isHovered ? TextDecoration.underline : null,
                  decorationThickness: 2,
                  fontSize: boxSize * 0.03 * 2,
                ),
        );
      } else {
        final cacheKey = '${tag.text}_${textStyle.hashCode}_foreground_$foregroundColor';
        textPainter = _textPainterCache[cacheKey] ??= _createTextPainter(
          isClickable: tag.isClickable,
          isHovered: isHovered,
          text: tag.text,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          opacity: 1,
          style: isMobileWebBrowser
              ? textStyle.copyWith(
                  color: tag.isClickable ? backgroundColor : textStyle.color,
                  backgroundColor: tag.isClickable ? foregroundColor : null,
                  decoration: TextDecoration.none,
                  fontSize: boxSize * 0.03 * 2,
                )
              : textStyle.copyWith(
                  color: isHovered && tag.isClickable ? backgroundColor : textStyle.color,
                  backgroundColor: isHovered && tag.isClickable ? foregroundColor : null,
                  decorationStyle: TextDecorationStyle.dotted,
                  decorationThickness: 2,
                  decoration: tag.isClickable && !isHovered ? TextDecoration.underline : null,
                  fontSize: boxSize * 0.03 * 2,
                ),
        );
        if (_textPainterCache.length > 1000) {
          _textPainterCache.remove(_textPainterCache.keys.first);
        }
      }

      final textWidth = textPainter.width;
      final textHeight = textPainter.height;
      final textX = -textWidth / 2;
      final textY = -textHeight / 2;

      canvas.translate(textX, textY);
      textPainter.paint(canvas, Offset.zero);
    }

    canvas.restore();
  }

  TextPainter _createTextPainter({
    required String text,
    required TextStyle style,
    required bool isClickable,
    required bool isHovered,
    required Color backgroundColor,
    required Color foregroundColor,
    required double opacity,
  }) {
    return TextPainter(
      text: TextSpan(
        text: '',
        children: [
          if (isClickable && !isMobileWebBrowser)
            TextSpan(
              text: isClickable && isHovered ? '/' : ' ',
              style: style.copyWith(
                color: backgroundColor,
                decoration: TextDecoration.none,
                backgroundColor: isClickable && isHovered ? foregroundColor : style.color?.withValues(alpha: opacity),
                fontWeight: FontWeight.w900,
              ),
            ),
          if (isClickable && !isMobileWebBrowser)
            TextSpan(
              text: ' ',
            ),
          if (isClickable && isMobileWebBrowser)
            TextSpan(
              text: 'X',
              style: style.copyWith(color: Colors.transparent),
            ),
          TextSpan(
            text: text,
            style: style,
          ),
          if (isClickable && isMobileWebBrowser)
            TextSpan(
              text: 'X',
              style: style.copyWith(color: Colors.transparent),
            ),
        ],
      ),
      // text: TextSpan(
      //   text: text,
      //   style: style,
      //   children: isClickable ? [
      //     TextSpan(
      //       text: '/',
      //       style: style.copyWith(
      //         color: isHovered ? backgroundColor : foregroundColor,
      //         decorationStyle: TextDecorationStyle.dotted,
      //         decoration: isHovered ? TextDecoration.underline : null,
      //         decorationThickness: 2,
      //       ),
      //     ),
      //   ] : [],
      // ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(OptimizedTagsPainter oldDelegate) {
    return true;
  }

  static void clearTextCache() {
    _textPainterCache.clear();
  }
}
