import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/services/db.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:stacked/stacked.dart';

enum NavigationState {
  home,
  project,
  about,
  contact,
  skills,
}

const landingBoxCount = 8;
const projectBoxCount = 10;
const aboutBoxCount = 8;
const skillsBoxCount = 8;

class HomeViewmodel extends BaseViewModel {
  // NAVIGATION
  NavigationState _navigationState = NavigationState.home;
  NavigationState get navigationState => _navigationState;

  String get pageTitle {
    if (_navigationState == NavigationState.home) return 'la page d\'acceuil'.toUpperCase();
    if (_navigationState == NavigationState.project) return 'le projet ${_currentProject?.title ?? ''}'.toUpperCase();
    if (_navigationState == NavigationState.about) return 'la page qui suis-je ?'.toUpperCase();
    if (_navigationState == NavigationState.contact) return 'la page contact'.toUpperCase();
    if (_navigationState == NavigationState.skills) return 'la page compétences'.toUpperCase();
    return '';
  }

  int get showGridItemsCount {
    if (_navigationState == NavigationState.home) return landingBoxCount;
    if (_navigationState == NavigationState.project) return projectBoxCount;
    if (_navigationState == NavigationState.about) return aboutBoxCount;
    if (_navigationState == NavigationState.skills) return skillsBoxCount;
    return 0;
  }

  Future<void> goToHome() async {
    await performTransition(() {
      _currentPrjIndex = null;
      _currentProject = null;
      _navigationState = NavigationState.home;
      notifyListeners();
    });
  }

  Future<void> goToProject() async {
    await performTransition(() {
      _currentPrjIndex = 0;
      _currentProject = _prjs[0];
      _navigationState = NavigationState.project;
      notifyListeners();
    });
  }

  Future<void> goToAbout() async {
    await performTransition(() {
      _navigationState = NavigationState.about;
      notifyListeners();
    });
  }

  Future<void> goToSkills() async {
    await performTransition(() {
      _navigationState = NavigationState.skills;
      notifyListeners();
    });
  }

  Future<void> performTransition(Function callback) async {
    await hideGridItems();
    callback();
    await Future.delayed(_transitionDuration);
    showGridItems(showGridItemsCount);
  }

  void setNavigationState(NavigationState state) {
    _navigationState = state;
    notifyListeners();
  }

  // TRANSITIONS

  final Duration _transitionDuration = const Duration(milliseconds: 600);
  Duration get transitionDuration => _transitionDuration;

  // final Duration _itemTransitionDuration = const Duration(milliseconds: 1000);
  final Duration _itemTransitionDuration = const Duration(milliseconds: 100);
  Duration get itemTransitionDuration => _itemTransitionDuration;

  final Curve _transitionCurve = Curves.easeInOut;
  Curve get transitionCurve => _transitionCurve;

  /// Calculates durations for grid items using a curve where each item gets
  /// an increasingly greater duration while maintaining the same total duration.
  ///
  /// The curve uses a quadratic function: duration[i] = baseDuration * (i + 1)^2
  /// This ensures the sum equals _itemTransitionDuration while each item
  /// gets progressively longer durations.
  List<Duration> _calculateCurvedDurations(bool invert, int count) {
    if (count < 0) return [Duration.zero];
    if (count == 0) return [Duration.zero];

    // Calculate the sum of squares: 1^2 + 2^2 + 3^2 + ... + count^2
    int sumOfSquares = 0;
    for (int i = 1; i <= count; i++) {
      sumOfSquares += i * i;
    }

    // Calculate base duration to ensure total equals _itemTransitionDuration
    final totalMilliseconds = _itemTransitionDuration.inMilliseconds;
    final baseDuration = totalMilliseconds / sumOfSquares;

    // Generate durations using quadratic curve
    List<Duration> durations = [];
    for (int i = 1; i <= count; i++) {
      final durationMs = (baseDuration * i * i).round();
      durations.add(Duration(milliseconds: durationMs));
    }

    if (invert) {
      durations = durations.reversed.toList();
    }

    return durations;
  }

  // bool _showGridItems = false;
  // bool get showGridItems => _showGridItems;

  int _currentGridIndex = 0;
  int get currentGridIndex => _currentGridIndex;

  void showGridItems(int count) async {
    final durations = _calculateCurvedDurations(false, count + 1);
    for (int i = 0; i <= count; i++) {
      await Future.delayed(durations[i]);
      _currentGridIndex = i;
      print(_currentGridIndex);
      notifyListeners();
    }
  }

  Future<void> hideGridItems() async {
    print('Start --------- hideGridItems ----------------');
    final initialGridIndex = _currentGridIndex;
    final durations = _calculateCurvedDurations(true, initialGridIndex);
    int durationIndex = 0;
    while (_currentGridIndex > 0) {
      await Future.delayed(durations[durationIndex]);
      _currentGridIndex--;
      durationIndex++;
      print(_currentGridIndex);
      notifyListeners();
    }
    notifyListeners();
    await Future.delayed(_transitionDuration);
    print('End --------- hideGridItems --------------------------------');
  }

  // Future<void> setShowGridItems(bool value) async {
  //   // _showGridItems = value;
  //   notifyListeners();
  //   await Future.delayed(_transitionDuration);
  //   notifyListeners();
  // }

  late double _boxSize;
  double get boxSize => _boxSize;

  bool _isHovering = false;
  bool get isHovering => _isHovering;

  Offset? _hoverPosition;
  Offset? get hoverPosition => _hoverPosition;

  Color get backgroundColor {
    if (_navigationState == NavigationState.project) return _currentProject?.background ?? Shades.mainColor;
    return Shades.mainColor;
  }

  Color get foregroundColor {
    if (_navigationState == NavigationState.project) return _currentProject?.foreground ?? Colors.black;
    return Colors.black;
  }

  void onHovering(bool value, Offset position) {
    // No box is hovering
    if (_hoverPosition == null && value) {
      _hoverPosition = position;
      _isHovering = true;
      notifyListeners();
      return;
    }

    // The current box is no longer being hovered
    if (_hoverPosition == position && !value) {
      _hoverPosition = null;
      _isHovering = false;
      notifyListeners();
      return;
    }

    if (_hoverPosition != position && value) {
      _hoverPosition = position;
      _isHovering = true;
      notifyListeners();
      return;
    }
  }

  void updateBoxSize(double boxSize) {
    _boxSize = boxSize;
    notifyListeners();
  }

  void onInit({
    required double boxSize,
  }) async {
    try {
      _boxSize = boxSize;
      notifyListeners();
      getProjects();
      _sensorSubscription = gyroscopeEventStream().listen(sensorHandler, onError: onSensorHandlerError);
      await Future.delayed(const Duration(seconds: 1));
      showGridItems(showGridItemsCount);
    } catch (e) {
      print('Error');
      print(e);
    }
  }

  void getProjects() async {
    _prjs = await DbService().getAllProjects();
    print('---------------');
    print("${_prjs.length} projects loaded");
    print('---------------');
    notifyListeners();
  }

  void onDispose() {
    _cursorPositionController.close();
    _sensorSubscription.cancel();
  }

  // PROJECTS

  int? _currentPrjIndex = -1;
  int? get currentPrjIndex => _currentPrjIndex;

  Project? _currentProject;
  Project? get currentProject => _currentProject;

  List<Project> _prjs = [];
  List<Project> get prjs => _prjs;

  Future<void> nextProject() async {
    if (_prjs.isEmpty) return;

    bool wasLastProject = _currentPrjIndex == _prjs.length - 1;

    await hideGridItems();
    if (_currentProject == null) {
      // From home view
      _currentPrjIndex = 0;
    } else {
      // From project view
      _currentPrjIndex = wasLastProject ? 0 : _currentPrjIndex! + 1;
    }
    if (_currentPrjIndex != null) {
      // From home view
      _currentProject = _prjs[_currentPrjIndex!];
    } else {
      // From project view
      _currentProject = null;
    }
    notifyListeners();
    await Future.delayed(_transitionDuration);
    showGridItems(showGridItemsCount);
  }

  void previousProject() {
    if (_currentProject == null) {
      _currentPrjIndex = 0;
    } else {
      _currentPrjIndex = _currentPrjIndex! - 1;
    }
    if (_currentPrjIndex != null) {
      _currentProject = _prjs[_currentPrjIndex!];
    } else {
      _currentProject = null;
    }
    notifyListeners();
  }

  // MOUSE POSITION

  final StreamController<Offset?> _cursorPositionController = StreamController<Offset?>.broadcast();
  Stream<Offset?> get cursorPositionStream => _cursorPositionController.stream;

  late StreamSubscription _sensorSubscription;

  void enteredAppArea() => _cursorPositionController.add(null);
  void exitedAppArea() => _cursorPositionController.add(null);
  void updateCursorPosition(Offset? position) => _cursorPositionController.add(position);
  void clearCursorPosition() => updateCursorPosition(null);

  void globalMouseRegionEventHandler(PointerEvent event) {
    updateCursorPosition(event.position);
  }

  // TILT

  final StreamController<TiltStreamModel> _tiltStreamController = StreamController<TiltStreamModel>.broadcast();
  StreamController<TiltStreamModel> get tiltStreamController => _tiltStreamController;

  void sensorHandler(GyroscopeEvent event) {
    print('sensorHandler');
  }

  void onSensorHandlerError(Object error) {
    print('onSensorHandlerError');
    print(error);
  }

  // void updateTiltStream(TiltStreamModel tiltStream) => _tiltStreamController.add(tiltStream);
  // void clearTiltStream() => updateTiltStream(TiltStreamModel(position: Offset(0, 0)));

  // void centerTilt() => updateTiltStream(TiltStreamModel(position: Offset(0, 0)));

  bool _pauseTilt = false;
  bool get pauseTilt => _pauseTilt;

  // void setPauseTilt(bool value) {
  //   _pauseTilt = value;
  //   notifyListeners();
  // }
}
