import 'package:flutter/material.dart';
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


  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'techStack': techStack,
      'screenshots': screenshots.map((e) => e.toMap()).toList(),
      'background': background.value.toRadixString(16),
      'foreground': foreground.value.toRadixString(16),
    };
  }
}

class Screenshot {
  final String url;
  final bool portrait;

  Screenshot({
    required this.url,
    this.portrait = true,
  });

  Screenshot.fromMap(Map<String, dynamic> data)
      : url = data['url'] ?? '',
        portrait = data['portrait'] ?? true;

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'portrait': portrait,
    };
  }
}
