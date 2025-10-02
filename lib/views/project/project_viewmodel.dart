import 'package:flutter/material.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/views/project/project_view.dart';
import 'package:stacked/stacked.dart';

// ============================================================================
// PROJECT VIEWMODEL
// ============================================================================

class ProjectViewModel extends BaseViewModel {
  // ============================================================================
  // PROPERTIES
  // ============================================================================

  late Project _project;
  Project get project => _project;

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

  void openScreenshot(BuildContext context, String url, Box box) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: SizedBox(
                    width: (MediaQuery.of(context).size.height * 0.9) / 2,
                    height: MediaQuery.of(context).size.height * 0.9,
                    child: ProjectScreenshopImage(url: url, box: box),
                  ),
                ),
              ),
            ],
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
