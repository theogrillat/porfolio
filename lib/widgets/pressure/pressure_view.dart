import 'package:flutter/material.dart';
import 'package:portfolio/services/tilt_service.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/utils.dart';
import 'package:stacked/stacked.dart';
import 'pressure_viewmodel.dart';

class PressureView extends StatefulWidget {
  const PressureView({
    super.key,
    required this.text,
    required this.mousePositionStream,
    required this.width,
    required this.height,
    required this.leftViewportOffset,
    required this.box,
    this.radius = 300,
    this.strength = 4,
    this.maxWeight = 1000,
    this.minWidth = 10,
    this.maxWidth = 200,
  })  : assert(minWidth < maxWidth, 'minWidth must be < maxWidth'),
        assert(minWidth >= 10 && minWidth < 200, 'minWidth must be >= 10 and < 200'),
        assert(maxWidth > 10 && maxWidth <= 200, 'maxWidth must be > 10 and <= 200');

  final String text;
  final Stream<Offset?> mousePositionStream;
  final double width;
  final double height;
  final double leftViewportOffset;
  final Box box;
  final double radius;
  final double strength;
  final double maxWeight;
  final double minWidth;
  final double maxWidth;

  @override
  State<PressureView> createState() => _PressureViewState();
}

class _PressureViewState extends State<PressureView> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PressureViewModel>.reactive(
      viewModelBuilder: () => PressureViewModel(),
      onViewModelReady: (model) => model.onInit(
        text: widget.text,
        mousePositionStream: widget.mousePositionStream,
        totalWidth: widget.width,
        leftViewportOffset: widget.leftViewportOffset,
        tickerProvider: this,
        strength: widget.strength,
        radius: widget.radius,
      ),
      onDispose: (model) => model.onDispose(),
      builder: (context, model, child) {
        // Update width when widget dimensions change
        // return Center(
        //   child: Text(model.currentTilt != null ? model.currentTilt!.toStringAsFixed(2) : 'Not supported'),
        // );
        model.updateWidth(
          totalWidth: widget.width,
          leftViewportOffset: widget.leftViewportOffset,
        );
        return Stack(
          children: [
            Stack(
              children: widget.text.split('').asMap().entries.map((entry) {
                final index = entry.key;
                double interpolatedWGHT = interpolate(
                  value: model.amounts[index],
                  range: [1, widget.strength],
                  outputRange: [200, widget.maxWeight.clamp(200.001, 1000)],
                );

                // double widthDiff = (model.widths[index] - model.baseItemWidth) / model.baseItemWidth;

                double interpolatedWDTH = interpolate(
                  value: model.amounts[index],
                  range: [1, widget.strength],
                  outputRange: [widget.minWidth.clamp(10, 199.99), widget.maxWidth.clamp(10.001, 200)],
                );
                double interpolatedITAL = interpolate(
                  value: model.amounts[index],
                  range: [1, widget.strength],
                  outputRange: [0, 1],
                );
                return Transform.translate(
                  offset: Offset(model.getXOffset(index: index, includeDiff: false), -widget.box.boxSize * 0.065),
                  child: Transform.scale(
                    scaleX: 1,
                    scaleY: 1,
                    child: SizedBox(
                      width: model.widths[index],
                      height: widget.height,
                      child: Align(
                        alignment: Alignment(
                          model.alignments[index],
                          0,
                        ),
                        child: Text(
                          widget.text[index],
                          style: TextStyle(
                            fontFamily: 'Compressa VF',
                            fontSize: widget.height * 1.3,
                            height: 0.1,
                            textBaseline: TextBaseline.ideographic,
                            color: widget.box.foreground,
                            fontVariations: [
                              FontVariation('wght', interpolatedWGHT),
                              FontVariation('wdth', interpolatedWDTH),
                              FontVariation('ital', interpolatedITAL),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            // if (isMobileWebBrowser)
            //   GestureDetector(
            //     onTap: () async {
            //       bool granted = await TiltService.instance.requestPermission();
            //       logger.i('Tilt permission granted: $granted');
            //     },
            //   ),
          ],
        );
      },
    );
  }
}
