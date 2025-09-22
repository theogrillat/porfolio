import 'package:flutter/material.dart';
import 'package:portfolio/shared/styles.dart';

class Project {
  final String title;
  final String description;
  final List<String> techStack;
  final List<String> screenshots;
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
        screenshots = (data['screenshots'] ?? []).cast<String>(),
        background = hex(data['background']),
        foreground = hex(data['foreground']);
}
