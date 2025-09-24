import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:stacked/stacked.dart';
import 'cloud_viewmodel.dart';

class CloudView extends StatefulWidget {
  const CloudView({
    super.key,
    required this.tags,
    required this.height,
    required this.width,
    required this.mousePositionStream,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.topViewportOffset,
    required this.leftViewportOffset,
    this.invertDirection = false,
    this.tagSize = 16,
    this.blur = true,
    this.tagBuilder,
  });

  final List<String> tags;
  final double height;
  final double width;
  final Stream<Offset?> mousePositionStream;
  final Color foregroundColor;
  final Color backgroundColor;

  final double topViewportOffset;
  final double leftViewportOffset;
  final double? tagSize;
  final bool blur;
  final bool invertDirection;
  final Widget Function(String tag)? tagBuilder;
  @override
  State<CloudView> createState() => _CloudViewState();
}

class _CloudViewState extends State<CloudView> {
  @override
  void didUpdateWidget(CloudView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if tags have changed and update the viewmodel
    if (widget.tags != oldWidget.tags) {
      // We need to access the viewmodel to update tags
      // This will be handled by the key change forcing a rebuild
    }
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<CloudViewModel>.reactive(
      viewModelBuilder: () => CloudViewModel(),
      onViewModelReady: (model) => model.onInit(
        tags: widget.tags,
        height: widget.height,
        width: widget.width,
        mousePositionStream: widget.mousePositionStream,
        topViewportOffset: widget.topViewportOffset,
        leftViewportOffset: widget.leftViewportOffset,
        foregroundColor: widget.foregroundColor,
        tagSize: widget.tagSize ?? 16,
        invertDirection: widget.invertDirection,
      ),
      onDispose: (model) => model.onDispose(),
      builder: (context, model, child) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: AnimatedOpacity(
            opacity: model.showCloud ? 1 : 0,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubicEmphasized,
            child: Stack(
              children: model.sphereTags.map((tag) {
                // Calculate opacity based on depth (closer = more opaque) with safety checks
                final double depthRange = 2 * model.sphereRadius;
                final double normalizedDepth = depthRange > 0 ? ((tag.depth + model.sphereRadius) / depthRange).clamp(0.0, 1.0) : 0.5;

                // Ensure normalized depth is finite
                final double safeNormalizedDepth = normalizedDepth.isFinite ? normalizedDepth : 0.5;

                final double opacity = (0.3 + (safeNormalizedDepth * 0.7)).clamp(0.1, 1.0); // Opacity between 0.1-1.0
                final double inverseNormalizedDepth = 1 - safeNormalizedDepth;
                final double blurThreshold = 0.3;

                // Calculate blur radius with safety bounds
                double blurRadius = 0.0;
                if (inverseNormalizedDepth > blurThreshold) {
                  blurRadius = (inverseNormalizedDepth - blurThreshold) * 10;
                }
                // Clamp blur radius to safe values for WASM
                blurRadius = blurRadius.clamp(0.0, 20.0);
                if (!blurRadius.isFinite) blurRadius = 0.0;

                // Calculate scale factor based on depth
                final double baseScale = 1.0;
                final double depthScale = (0.5 + (safeNormalizedDepth * 0.8)).clamp(0.5, 1.3);
                final double scale = baseScale * depthScale;

                // Use pre-calculated text dimensions
                final double textWidth = tag.textWidth;
                final double textHeight = tag.textHeight;

                // Fixed base text style
                final textStyle = Typos().large(color: widget.foregroundColor).copyWith(
                      fontSize: widget.tagSize ?? 16.0, // Fixed size - we use scale for variations
                      height: 1,
                      fontWeight: FontWeight.w700,
                    );

                // Calculate position with safety checks
                final double posX = tag.position2D.dx;
                final double posY = tag.position2D.dy;

                if (!posX.isFinite || !posY.isFinite) {
                  return const SizedBox.shrink(); // Skip invalid positioned widgets
                }

                final double left = (posX - textWidth / 2).clamp(-textWidth, widget.width + textWidth);
                final double top = (posY - textHeight / 2).clamp(-textHeight, widget.height + textHeight);

                // Additional safety checks for WASM compatibility
                if (textWidth <= 0 || textHeight <= 0 || !textWidth.isFinite || !textHeight.isFinite) {
                  return const SizedBox.shrink();
                }

                return Positioned(
                  left: left,
                  top: top,
                  width: textWidth,
                  height: textHeight,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: widget.tagBuilder != null
                          ? widget.tagBuilder!(tag.text)
                          : Container(
                              width: textWidth,
                              height: textHeight,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ClipRect(
                                child: widget.blur && blurRadius > 0
                                    ? ImageFiltered(
                                        imageFilter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
                                        child: Text(
                                          tag.text,
                                          style: textStyle,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    : Text(
                                        tag.text,
                                        style: textStyle,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                            ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
