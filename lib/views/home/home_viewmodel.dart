import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tilt/flutter_tilt.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/services/analytics.dart';
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
const contactBoxCount = 9;

// ============================================================================
// HOME VIEWMODEL
// ============================================================================

class HomeViewmodel extends BaseViewModel {
  // ============================================================================
  // SERVICES
  // ============================================================================

  final AnalyticsService _anal = AnalyticsService.instance;

  AppScreen? _getCurrentScreen() {
    if (_navigationState == NavigationState.home) return AppScreen.home;
    if (_navigationState == NavigationState.project) return AppScreen.projects;
    if (_navigationState == NavigationState.about) return AppScreen.profile;
    if (_navigationState == NavigationState.contact) return AppScreen.contact;
    if (_navigationState == NavigationState.skills) return AppScreen.skills;
    return null;
  }

  // ----------------------------------------------------------------------------
  // NAVIGATION STATE
  // ----------------------------------------------------------------------------

  NavigationState _navigationState = NavigationState.home;
  NavigationState get navigationState => _navigationState;

  String get pageTitle {
    if (_navigationState == NavigationState.home) return 'la page d\'acceuil'.toUpperCase();
    if (_navigationState == NavigationState.project) return 'le projet ${_currentProject?.title ?? ''}'.toUpperCase();
    if (_navigationState == NavigationState.about) return 'la page profile'.toUpperCase();
    if (_navigationState == NavigationState.contact) return 'la page contact'.toUpperCase();
    if (_navigationState == NavigationState.skills) return 'la page skills'.toUpperCase();
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
  Timer? _boxSizeDebounceTimer;
  double? _lastCalculatedBoxSize;
  double _lastKeyboardHeight = 0;
  bool _isKeyboardTransitioning = false;

  late double _topPadding;
  double get topPadding => _topPadding;

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

  final Duration _transitionDuration = const Duration(milliseconds: 500);
  Duration get transitionDuration => _transitionDuration;

  final Duration _itemTransitionDuration = const Duration(milliseconds: 600);
  Duration get itemTransitionDuration => _itemTransitionDuration;

  final Curve _transitionCurve = Curves.easeInOutCubicEmphasized;
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
    required double topPadding,
  }) async {
    try {
      _tiltPermissionGranted = await TiltService.instance.requestPermission();
      notifyListeners();
      _boxSize = boxSize;
      _topPadding = topPadding;
      notifyListeners();
      getProjects();
      // await Future.delayed(const Duration(seconds: 1));
      showGridItems(showGridItemsCount);
      // await waitUntil(() => _prjs.isNotEmpty);
      // goToProject();
      // goToContact();
    } catch (e) {
      print('Error');
      print(e);
    }
  }

  void onDispose() {
    _cursorPositionController.close();
    _boxSizeDebounceTimer?.cancel();
  }

  // ============================================================================
  // NAVIGATION
  // ============================================================================

  void setNavigationState(NavigationState state) {
    _navigationState = state;
    notifyListeners();
  }

  Future<void> goToHome() async {
    _anal.logScreen(AppScreen.home, from: _getCurrentScreen());
    await performTransition(() {
      _currentPrjIndex = null;
      _currentProject = null;
      _navigationState = NavigationState.home;
      notifyListeners();
    });
  }

  Future<void> goToProject() async {
    if (_navigationState == NavigationState.project) return;
    _anal.logScreen(AppScreen.projects, screenInstance: _prjs[0].title, from: _getCurrentScreen());
    await performTransition(() {
      _currentPrjIndex = 0;
      _currentProject = _prjs[0];
      _navigationState = NavigationState.project;
      notifyListeners();
    });
  }

  Future<void> goToAbout() async {
    _anal.logScreen(AppScreen.profile, from: _getCurrentScreen());
    await performTransition(() {
      _navigationState = NavigationState.about;
      notifyListeners();
    });
  }

  Future<void> goToSkills() async {
    _anal.logScreen(AppScreen.skills, from: _getCurrentScreen());
    await performTransition(() {
      _navigationState = NavigationState.skills;
      notifyListeners();
    });
  }

  Future<void> goToContact() async {
    _anal.logScreen(AppScreen.contact, from: _getCurrentScreen());
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

    String? fromInstance = _currentProject?.title;

    _currentPrjIndex = _currentPrjIndex != null ? _currentPrjIndex! + 1 : 0;
    _currentProject = _prjs[_currentPrjIndex!];
    notifyListeners();

    _anal.logScreen(
      AppScreen.projects,
      screenInstance: _currentProject?.title,
      from: _getCurrentScreen(),
      fromInstance: fromInstance,
    );

    await Future.delayed(_transitionDuration);

    showGridItems(showGridItemsCount);
  }

  Future<void> previousProject() async {
    if (_prjs.isEmpty) return;
    if (_currentPrjIndex == 0) return;

    await hideGridItems();

    String? fromInstance = _currentProject?.title;

    _currentPrjIndex = _currentPrjIndex != null ? _currentPrjIndex! - 1 : 0;
    _currentProject = _prjs[_currentPrjIndex!];
    notifyListeners();

    _anal.logScreen(
      AppScreen.projects,
      screenInstance: _currentProject?.title,
      from: _getCurrentScreen(),
      fromInstance: fromInstance,
    );

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
    _anal.logEvent(
      name: 'filter_cleared',
      parameters: {
        'cleared_skills': _filterSkills,
      },
    );
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

    AppScreen? from = _getCurrentScreen();
    String? fromInstance = _currentProject?.title;

    _currentPrjIndex = index;
    _currentProject = project;
    notifyListeners();

    _anal.logScreen(
      AppScreen.projects,
      screenInstance: project.title,
      from: from,
      fromInstance: fromInstance,
    );

    await Future.delayed(_transitionDuration);

    showGridItems(showGridItemsCount);
  }

  // ============================================================================
  // UI & ANIMATION
  // ============================================================================

  void checkKeyboardState(double keyboardHeight) {
    // Detect keyboard state changes
    if (keyboardHeight != _lastKeyboardHeight) {
      _isKeyboardTransitioning = true;
      _lastKeyboardHeight = keyboardHeight;

      // Reset transition flag after keyboard animation completes
      _boxSizeDebounceTimer?.cancel();
      _boxSizeDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        _isKeyboardTransitioning = false;
      });
    }
  }

  void updateBoxSize(double boxSize, {bool force = false}) {
    // During keyboard transitions, ignore box size changes to prevent flickering
    if (_isKeyboardTransitioning && !force) {
      return;
    }

    // Ignore small changes that occur during keyboard transitions
    const threshold = 2.0; // pixels
    if (_lastCalculatedBoxSize != null && (boxSize - _lastCalculatedBoxSize!).abs() < threshold) {
      return;
    }

    _lastCalculatedBoxSize = boxSize;

    // Cancel any pending updates
    _boxSizeDebounceTimer?.cancel();

    // Immediate update when not transitioning, debounced otherwise
    if (!_isKeyboardTransitioning || force) {
      if (_boxSize != boxSize) {
        _boxSize = boxSize;
        notifyListeners();
      }
    } else {
      _boxSizeDebounceTimer = Timer(const Duration(milliseconds: 100), () {
        if (_boxSize != boxSize) {
          _boxSize = boxSize;
          notifyListeners();
        }
      });
    }
  }

  void updateTopPadding(double topPadding) {
    // During keyboard transitions, ignore top padding changes to prevent flickering
    if (_isKeyboardTransitioning) {
      return;
    }

    if (_topPadding != topPadding) {
      _topPadding = topPadding;
      notifyListeners();
    }
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

  bool _isTransitioning = false;
  bool get isTransitioning => _isTransitioning;

  void showGridItems(int count) async {
    if (_isTransitioning) return;
    _isTransitioning = true;
    notifyListeners();
    final durations = _calculateCurvedDurations(false, count + 1);
    for (int i = 0; i <= count; i++) {
      await Future.delayed(durations[i]);
      _currentGridIndex = i;
      print(_currentGridIndex);
      notifyListeners();
    }
    _isTransitioning = false;
    notifyListeners();
  }

  Future<void> hideGridItems() async {
    if (_isTransitioning) return;
    _isTransitioning = true;
    notifyListeners();
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
    _isTransitioning = false;
    notifyListeners();
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

  // ============================================================================
  // TOAST
  // ============================================================================

  final Duration _toastDuration = const Duration(seconds: 2);
  Duration get toastDuration => _toastDuration;

  final Duration _toastTransitionDuration = const Duration(milliseconds: 300);
  Duration get toastTransitionDuration => _toastTransitionDuration;

  String? _toastMessage;
  String? get toastMessage => _toastMessage;

  bool _showToast = false;
  bool get showToast => _showToast;

  final List<String> _toastQueue = [];
  bool _isProcessingToast = false;

  void triggerToast(String message) {
    _toastQueue.add(message);
    _processToastQueue();
  }

  Future<void> _processToastQueue() async {
    // If already processing or queue is empty, return
    if (_isProcessingToast || _toastQueue.isEmpty) return;

    _isProcessingToast = true;

    while (_toastQueue.isNotEmpty) {
      // Get the next message from the queue
      final message = _toastQueue.removeAt(0);

      // Set the message and show the toast
      _toastMessage = message;
      notifyListeners();

      _showToast = true;
      notifyListeners();

      // Wait for the toast duration
      await Future.delayed(_toastDuration);

      // Hide the toast
      _showToast = false;
      notifyListeners();

      // Wait for the transition to complete
      await Future.delayed(_toastTransitionDuration);

      // Clear the message
      _toastMessage = null;
      notifyListeners();
    }

    _isProcessingToast = false;
  }
}
