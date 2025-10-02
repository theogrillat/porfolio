import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/services/db.dart';
import 'package:portfolio/services/tilt_service.dart';
import 'package:portfolio/shared/styles.dart';
import 'package:portfolio/shared/utils.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:stacked/stacked.dart';

// ============================================================================
// ENUMS & CONSTANTS
// ============================================================================

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
const contactBoxCount = 1;

// ============================================================================
// HOME VIEWMODEL
// ============================================================================

class HomeViewmodel extends BaseViewModel {
  // ============================================================================
  // PROPERTIES
  // ============================================================================

  // ----------------------------------------------------------------------------
  // NAVIGATION STATE
  // ----------------------------------------------------------------------------

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
    if (_navigationState == NavigationState.contact) return contactBoxCount;
    return 0;
  }

  // ----------------------------------------------------------------------------
  // PROJECT MANAGEMENT
  // ----------------------------------------------------------------------------

  int? _currentPrjIndex = -1;
  int? get currentPrjIndex => _currentPrjIndex;

  Project? _currentProject;
  Project? get currentProject => _currentProject;

  bool get isLastProject => _prjs.isEmpty || _currentPrjIndex == _prjs.length - 1;
  bool get isFirstProject => _prjs.isEmpty || _currentPrjIndex == 0;

  List<Project> _prjs = [];
  List<Project> get prjs => _prjs;

  // ----------------------------------------------------------------------------
  // UI STATE
  // ----------------------------------------------------------------------------

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

  // ----------------------------------------------------------------------------
  // TRANSITION & ANIMATION
  // ----------------------------------------------------------------------------

  final Duration _transitionDuration = const Duration(milliseconds: 100);
  Duration get transitionDuration => _transitionDuration;

  final Duration _itemTransitionDuration = const Duration(milliseconds: 100);
  Duration get itemTransitionDuration => _itemTransitionDuration;

  final Curve _transitionCurve = Curves.easeInOut;
  Curve get transitionCurve => _transitionCurve;

  int _currentGridIndex = 0;
  int get currentGridIndex => _currentGridIndex;

  // ----------------------------------------------------------------------------
  // CURSOR & TILT
  // ----------------------------------------------------------------------------

  final StreamController<Offset?> _cursorPositionController = StreamController<Offset?>.broadcast();
  Stream<Offset?> get cursorPositionStream => _cursorPositionController.stream;

  final StreamController<TiltStreamModel> _tiltStreamController = StreamController<TiltStreamModel>.broadcast();
  StreamController<TiltStreamModel> get tiltStreamController => _tiltStreamController;

  bool? _tiltPermissionGranted;
  bool? get isTiltPermissionGranted => _tiltPermissionGranted;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  void onInit({
    required double boxSize,
  }) async {
    try {
      _tiltPermissionGranted = await TiltService.instance.requestPermission();
      notifyListeners();
      _boxSize = boxSize;
      notifyListeners();
      getProjects();
      await Future.delayed(const Duration(seconds: 1));
      showGridItems(showGridItemsCount);
    } catch (e) {
      print('Error');
      print(e);
    }
  }

  void onDispose() {
    _cursorPositionController.close();
  }

  // ============================================================================
  // NAVIGATION
  // ============================================================================

  void setNavigationState(NavigationState state) {
    _navigationState = state;
    notifyListeners();
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
    if (_navigationState == NavigationState.project) return;
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

  Future<void> goToContact() async {
    await performTransition(() {
      _navigationState = NavigationState.contact;
      notifyListeners();
    });
  }

  // ============================================================================
  // PROJECT MANAGEMENT
  // ============================================================================

  bool get anyProjectIsSelected => _currentPrjIndex != null && _currentPrjIndex! >= 0;

  void getProjects() async {
    _prjs = await DbService().getAllProjects();
    _prjs.sort((a, b) => a.priority.compareTo(b.priority));
    print('---------------');
    print("\${_prjs.length} projects loaded");
    print('---------------');
    notifyListeners();
  }

  Future<void> nextProject() async {
    if (_prjs.isEmpty) return;
    if (_currentPrjIndex == _prjs.length - 1) return;

    await hideGridItems();

    _currentPrjIndex = _currentPrjIndex != null ? _currentPrjIndex! + 1 : 0;
    _currentProject = _prjs[_currentPrjIndex!];
    notifyListeners();

    await Future.delayed(_transitionDuration);

    showGridItems(showGridItemsCount);
  }

  Future<void> previousProject() async {
    if (_prjs.isEmpty) return;
    if (_currentPrjIndex == 0) return;

    await hideGridItems();

    _currentPrjIndex = _currentPrjIndex != null ? _currentPrjIndex! - 1 : 0;
    _currentProject = _prjs[_currentPrjIndex!];
    notifyListeners();

    await Future.delayed(_transitionDuration);

    showGridItems(showGridItemsCount);
  }

  // ============================================================================
  // MENU
  // ============================================================================

  bool _showMenu = false;
  bool get showMenu => _showMenu;

  bool get blurPage => false;

  bool get showMenuButton => _navigationState == NavigationState.project || _navigationState == NavigationState.skills;

  List<Project> get filteredProjects => _filterSkills.isEmpty ? _prjs : _prjs.where((p) => p.techStack.any((t) => _filterSkills.contains(t))).toList();

  List<String> _filterSkills = [];
  List<String> get filterSkills => _filterSkills;

  double menuButtonSize(BuildContext context) {
    if (isPortrait(context)) return 40;
    return 75;
  }

  void toggleMenu() {
    _showMenu = !_showMenu;
    notifyListeners();
  }

  void openMenu() {
    _showMenu = true;
    notifyListeners();
  }

  void closeMenu() {
    _showMenu = false;
    notifyListeners();
  }

  void filterProjects(String skill) {
    _filterSkills = [skill];
    notifyListeners();
    openMenu();
  }

  void clearFilter() {
    _filterSkills = [];
    notifyListeners();
    openMenu();
  }

  void goToThisProject(Project project) async {
    if (project == _currentProject) return;
    await goToProject();
    int index = _prjs.indexWhere((p) => p.id == p.id);

    closeMenu();

    await hideGridItems();

    _currentPrjIndex = index;
    _currentProject = project;
    notifyListeners();

    await Future.delayed(_transitionDuration);

    showGridItems(showGridItemsCount);
  }

  // ============================================================================
  // UI & ANIMATION
  // ============================================================================

  void updateBoxSize(double boxSize) {
    _boxSize = boxSize;
    notifyListeners();
  }

  void onHovering(bool value, Offset position) {
    if (_hoverPosition == null && value) {
      _hoverPosition = position;
      _isHovering = true;
      notifyListeners();
      return;
    }

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

  Future<void> performTransition(Function callback) async {
    await hideGridItems();
    callback();
    await Future.delayed(_transitionDuration);
    showGridItems(showGridItemsCount);
  }

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

  List<Duration> _calculateCurvedDurations(bool invert, int count) {
    if (count < 0) return [Duration.zero];
    if (count == 0) return [Duration.zero];

    int sumOfSquares = 0;
    for (int i = 1; i <= count; i++) {
      sumOfSquares += i * i;
    }

    final totalMilliseconds = _itemTransitionDuration.inMilliseconds;
    final baseDuration = totalMilliseconds / sumOfSquares;

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

  // ============================================================================
  // EVENT HANDLERS
  // ============================================================================

  void enteredAppArea() {
    _cursorPositionController.add(null);
  }

  void exitedAppArea() {
    _cursorPositionController.add(null);
  }

  void updateCursorPosition(Offset? position) {
    _cursorPositionController.add(position);
  }

  void clearCursorPosition() => updateCursorPosition(null);

  void globalMouseRegionEventHandler(PointerEvent event) {
    updateCursorPosition(event.position);
  }

  // ============================================================================
  // TILT & SENSOR HANDLING
  // ============================================================================

  void updateTiltPermissionGranted(bool value) {
    _tiltPermissionGranted = value;
    notifyListeners();
  }
}
