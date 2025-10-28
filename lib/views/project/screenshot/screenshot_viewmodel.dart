import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/services/analytics.dart';
import 'package:stacked/stacked.dart';

class ScreenshotViewModel extends BaseViewModel {

  final AnalyticsService _anal = AnalyticsService.instance;

  final PageController _pageController = PageController();
  PageController get pageController => _pageController;

  late List<Screenshot> _screenshots;
  List<Screenshot> get screenshots => _screenshots;

  late int _currentIndex;
  int get currentIndex => _currentIndex;

  Screenshot get currentScreenshot => _screenshots[currentIndex];

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  final _transitionCurve = Curves.easeInOutCubicEmphasized;
  final Duration _transitionDuration = const Duration(milliseconds: 500);

  void goToPage(int index) async {
    _pageController.animateToPage(
      index,
      duration: _transitionDuration,
      curve: _transitionCurve,
    );
    await Future.delayed(_transitionDuration);
    _anal.logEvent(
      name: 'project_screenshot_navigated',
      parameters: {
        'screenshot_url': currentScreenshot.url,
      },
    );
  }

  void next() async {
    if (_currentIndex == _screenshots.length - 1) {
      _pageController.animateToPage(
        0,
        duration: _transitionDuration,
        curve: _transitionCurve,
      );
    } else {
      _pageController.nextPage(
        duration: _transitionDuration,
        curve: _transitionCurve,
      );
    }
    await Future.delayed(_transitionDuration);
    _anal.logEvent(
      name: 'project_screenshot_navigated',
      parameters: {
        'screenshot_url': currentScreenshot.url,
      },
    );
  }

  void previous() async {
    if (_currentIndex == 0) {
      _pageController.animateToPage(
        _screenshots.length - 1,
        duration: _transitionDuration,
        curve: _transitionCurve,
      );
    } else {
      _pageController.previousPage(
        duration: _transitionDuration,
        curve: _transitionCurve,
      );
    }
    await Future.delayed(_transitionDuration);
    _anal.logEvent(
      name: 'project_screenshot_navigated',
      parameters: {
        'screenshot_url': currentScreenshot.url,
      },
    );
  }

  void onInit({
    required List<Screenshot> screenshots,
    int initialIndex = 0,
  }) {
    _screenshots = screenshots;
    _currentIndex = initialIndex;
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(initialIndex);
    });
  }
  void onDispose() {}
}
