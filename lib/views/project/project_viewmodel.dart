import 'package:flutter/material.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/views/project/project_view.dart';
import 'package:stacked/stacked.dart';

class ProjectViewModel extends BaseViewModel {
  late Project _project;
  Project get project => _project;

  void onInit(Project prj) {
    _project = prj;
    notifyListeners();
  }

  void onDispose() {}

  void openScreenshot(BuildContext context, String url, Box box) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Background overlay that dismisses the dialog
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withValues(alpha: 0.8),
                ),
              ),
              // Image content with Hero animation
              Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent dialog from closing when tapping the image
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
        opaque: false, // This is key for transparency
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
