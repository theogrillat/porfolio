import 'package:flutter/material.dart';
import 'package:portfolio/shared/styles.dart';

class Project {
  final String title;
  final String description;
  final List<String> techStack;
  final List<Screenshot> screenshots;
  final Color background;
  final Color foreground;
  final int priority;
  final String id;

  Project({
    required this.title,
    required this.description,
    required this.techStack,
    required this.screenshots,
    required this.background,
    required this.foreground,
    this.priority = 0,
    required this.id,
  });

  static List<Screenshot> getScreenshots(dynamic data) {
    dynamic screenshots = data['screenshots'];
    if (screenshots == null) return List.generate(4, (i) => Screenshot(url: '', portrait: true));
    if (screenshots is! List) return List.generate(4, (i) => Screenshot(url: '', portrait: true));
    if (screenshots.length < 4) return List.generate(4, (i) => Screenshot(url: '', portrait: true));
    return (screenshots).map((e) => Screenshot.fromMap(e)).toList();
  }

  Project.fromMap(Map<String, dynamic> data)
      : title = data['title'] ?? '',
        description = data['description'] ?? '',
        techStack = (data['techStack'] ?? []).cast<String>(),
        screenshots = getScreenshots(data),
        background = hex(data['background']),
        foreground = hex(data['foreground']),
        priority = data['priority'] ?? 0,
        id = data['id'] ?? '';

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'techStack': techStack,
      'screenshots': screenshots.map((e) => e.toMap()).toList(),
      'background': background.value.toRadixString(16),
      'foreground': foreground.value.toRadixString(16),
      'priority': priority,
      'id': id,
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
