import 'package:flutter/material.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/styles.dart';

class Project {
  final String title;
  final String description;
  final List<String> techStack;
  final List<Screenshot> screenshots;
  final Color background;
  final Color foreground;

  Project({
    required this.title,
    required this.description,
    required this.techStack,
    required this.screenshots,
    required this.background,
    required this.foreground,
  });

  Project.fromMap(Map<String, dynamic> data)
      : title = data['title'] ?? '',
        description = data['description'] ?? '',
        techStack = (data['techStack'] ?? []).cast<String>(),
        screenshots = ((data['screenshots'] ?? []) as List<dynamic>).map((e) => Screenshot.fromMap(e as Map<String, dynamic>)).toList(),
        background = hex(data['background']),
        foreground = hex(data['foreground']);
}

class Screenshot {
  final String url;
  final BoxPosition position;

  Screenshot({
    required this.url,
    required this.position,
  });

  Screenshot.fromMap(Map<String, dynamic> data)
      : url = data['url'] ?? '',
        position = BoxPosition(
          start: Coords(data['start'][0], data['start'][1]),
          end: Coords(data['end'][0], data['end'][1]),
        );
}
