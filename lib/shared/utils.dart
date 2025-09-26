import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:portfolio/shared/styles.dart';

double interpolate({
  required num value,
  required List<num> range,
  required List<num> outputRange,
}) {
  if (range.length != 2) throw ArgumentError('The range must have exactly 2 values.');
  if (outputRange.length != 2) throw ArgumentError('The output range must have exactly 2 values.');
  num min = range[0];
  num max = range[1];
  if (min == max) throw ArgumentError('The min and max values cannot be the same.');
  if (min >= max) throw ArgumentError('The min value cannot be greater than the max value.');
  num minOutput = outputRange[0];
  num maxOutput = outputRange[1];
  if (minOutput == maxOutput) throw ArgumentError('The min and max output values cannot be the same.');
  if (minOutput >= maxOutput) throw ArgumentError('The min output value cannot be greater than the max output value.');

  // Clamp the value to ensure it's within the min-max range
  final clampedValue = value.clamp(min, max);

  // Normalize the value to the 0-1 range and return it as a double
  return (clampedValue - min) / (max - min) * (maxOutput - minOutput) + minOutput;
}

/// Distributes a list of [tags] evenly within a new list of a given [totalLength],
/// padded with the specified [filler] character.
List<String> distributeEvenly(List<String> tags, int totalLength, {String filler = '•'}) {
  final nTags = tags.length;

  // If there are no tags, return a list full of fillers.
  if (nTags == 0) {
    return List.filled(totalLength, filler);
  }

  // If the tags already fill or exceed the desired length, return a truncated list of tags.
  if (nTags >= totalLength) {
    return tags.sublist(0, totalLength);
  }

  final nFillers = totalLength - nTags;

  // We have nTags + 1 sections to place fillers into (including before the first tag and after the last).
  // For example: [fillers] TAG [fillers] TAG [fillers]
  final numFillerSections = nTags + 1;

  // Calculate the base number of fillers per section and how many sections get an extra one.
  final baseFillersPerSection = nFillers ~/ numFillerSections;
  final extraFillersToDistribute = nFillers % numFillerSections;

  final result = <String>[];
  int tagIndex = 0;

  for (int i = 0; i < numFillerSections; i++) {
    // Determine how many fillers to add in this section.
    final numFillersInSection = baseFillersPerSection + (i < extraFillersToDistribute ? 1 : 0);
    result.addAll(List.filled(numFillersInSection, filler));

    // Add a tag after the filler section, but not after the last one.
    if (i < nTags) {
      result.add(tags[tagIndex]);
      tagIndex++;
    }
  }

  return result;
}

bool isPortrait(BuildContext context) {
  double w = MediaQuery.of(context).size.width;
  double h = MediaQuery.of(context).size.height;
  return w < h;
}

double calcBoxSize(BuildContext context) {
  int xCount = Constants.xCount(context);
  int yCount = Constants.yCount(context);
  double w = MediaQuery.of(context).size.width;
  double h = MediaQuery.of(context).size.height;
  double sidebar = Constants.sidebarWidth(context);
  double padding = Constants.mainPadding(context);
  double boxSize = (w - sidebar - padding * 2) / xCount;
  if ((boxSize * yCount) + padding * 2 > h) {
    boxSize = (h - padding * 2) / yCount;
  }
  return boxSize;
}

double getTopPadding(BuildContext context) {
  double maxHeight = MediaQuery.of(context).size.height;
  return (maxHeight - (Constants.yCount(context) * calcBoxSize(context))) / 2;
}

double getLeftPadding(BuildContext context) {
  double maxWidth = MediaQuery.of(context).size.width;
  return (maxWidth - ((Constants.xCount(context) * calcBoxSize(context)) + Constants.sidebarWidth(context))) / 2;
}

class Breakpoints {
  //
  //
  // Mobile
  //
  //
  static const double tablet = 480;
  //
  //
  // Tablet
  //
  //
  static const double desktop = 769;
  //
  //
  // Desktop
  //
  //
  static const double wide = 1025;
  //
  //
  //
  //
  //

  double minSize(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    return min(w, h);
  }

  bool isMobile(BuildContext context) {
    double size = minSize(context);
    return size <= tablet;
  }

  bool isTablet(BuildContext context) {
    double size = minSize(context);
    return size >= tablet && size < desktop;
  }

  bool isDesktop(BuildContext context) {
    double size = minSize(context);
    return size >= desktop && size < wide;
  }

  bool isWide(BuildContext context) {
    double size = minSize(context);
    return size >= wide;
  }
}
