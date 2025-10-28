import 'package:flutter/material.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/services/analytics.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/utils.dart';
import 'package:portfolio/views/project/project_view.dart';
import 'package:portfolio/views/project/screenshot/screenshot_view.dart';
import 'package:stacked/stacked.dart';

// ============================================================================
// PROJECT VIEWMODEL
// ============================================================================

class ProjectViewModel extends BaseViewModel {
  // ============================================================================
  // SERVICES
  // ============================================================================

  final AnalyticsService _anal = AnalyticsService.instance;

  // ============================================================================
  // PROPERTIES
  // ============================================================================

  late Project _project;
  Project get project => _project;

  // ============================================================================
  // ITEM EXPANDED
  // ============================================================================

  bool _descriptionExpanded = false;
  bool get descriptionExpanded => _descriptionExpanded;

  void toggleDescription() {
    _descriptionExpanded = !_descriptionExpanded;
    notifyListeners();
  }

  bool _tagsExpanded = false;
  bool get tagsExpanded => _tagsExpanded;

  void toggleTags() {
    _tagsExpanded = !_tagsExpanded;
    notifyListeners();
  }

  void collapseAll() {
    _descriptionExpanded = false;
    _tagsExpanded = false;
    notifyListeners();
  }

  bool get anyExpanded => _descriptionExpanded || _tagsExpanded;
  bool get noExpanded => !anyExpanded;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  void onInit(Project prj) {
    _project = prj;
    notifyListeners();
  }

  void onDispose() {}

  // ============================================================================
  // PUBLIC METHODS
  // ============================================================================

  void openScreenshot(BuildContext context, int index, Box box) {
    _anal.logEvent(
      name: 'project_screenshot_opened',
      parameters: {
        'project_title': project.title,
        'screenshot_url': project.screenshots[index].url,
      },
    );
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.transparent,
          body: ScreenshotView(
            screenshots: project.screenshots,
            initialIndex: index,
            box: box,
          ),
        ),
        opaque: false,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
}
