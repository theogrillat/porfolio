import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:portfolio/shared/grid.dart';
import 'package:portfolio/shared/utils.dart';
import 'package:portfolio/widgets/tags/geodesic_distribution.dart';
import 'package:portfolio/widgets/tags/tag_model.dart';
import 'package:stacked/stacked.dart';
import 'package:vector_math/vector_math.dart';

// ============================================================================
// ENUMS & CONSTANTS
// ============================================================================

enum InputMethod { mouse, touch }

// ============================================================================
// TAGS VIEWMODEL
// ============================================================================

/// ViewModel for managing and animating tags in a 3D sphere layout
class TagsViewModel extends BaseViewModel {
  // ============================================================================
  // PROPERTIES
  // ============================================================================

  // ----------------------------------------------------------------------------
  // CONFIGURATION
  // ----------------------------------------------------------------------------

  static const String _fillerCharacter = '•';
  int _totalTagsCount = 300;
  double _sphereMargin = 50.0;
  bool _inverted = false;
  bool get inverted => _inverted;

  // ----------------------------------------------------------------------------
  // UI & LAYOUT
  // ----------------------------------------------------------------------------

  late Box _box;
  late double _leftOffset;
  late double _topOffset;
  double _minSize = double.infinity;
  double get minSize => _minSize;
  double _maxSize = double.negativeInfinity;
  double get maxSize => _maxSize;
  late double _canvasWidth;
  double get width => _canvasWidth;
  late double _canvasHeight;
  double get height => _canvasHeight;

  // ----------------------------------------------------------------------------
  // TAGS DATA
  // ----------------------------------------------------------------------------

  late List<Tag> _tags;
  late List<Tag> _fillers;
  List<Tag> get allTags => _tags + _fillers;
  Tag? _hoveredTag;
  Tag? get hoveredTag => _hoveredTag;

  // ----------------------------------------------------------------------------
  // ANIMATION & TICKER
  // ----------------------------------------------------------------------------

  Ticker? _ticker;
  Duration? _lastTimestamp;
  bool _isAnimating = false;
  bool get isAnimating => _isAnimating;
  double _rotationSpeed = 1.0;
  double get rotationSpeed => _rotationSpeed;
  Vector3 _rotationAxis = Vector3(1.0, 0.5, 0.2);
  Vector3 get rotationAxis => _rotationAxis;

  // ----------------------------------------------------------------------------
  // INTERACTION STATE
  // ----------------------------------------------------------------------------

  late final InputMethod _interactionMode;
  InputMethod get interactionMode => _interactionMode;
  StreamSubscription<Offset?>? _cursorPositionStream;
  Offset? _lastCursorPosition;
  Offset? get lastCursorPosition => _lastCursorPosition;
  bool _isDragging = false;
  bool get isDragging => _isDragging;
  double _dragSensitivity = 0.005;

  // ----------------------------------------------------------------------------
  // INERTIA
  // ----------------------------------------------------------------------------

  static const double _timeConstant = 325.0;
  static const double _minInertiaSpeed = 0.005;
  static const Duration _maxInertiaDuration = Duration(milliseconds: 2000);
  bool _hasInertia = false;
  Vector3 _inertiaVelocity = Vector3.zero();
  Duration? _inertiaStartTime;
  Vector3 _initialInertiaVelocity = Vector3.zero();
  DateTime? _dragStartTime;
  Offset? _dragStartPosition;
  double _totalDragDistance = 0.0;
  int _dragUpdateCount = 0;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  void onInit({
    required TickerProvider vsync,
    required List<String> tags,
    required List<String> clickableTags,
    required Stream<Offset?> cursorPositionStream,
    required Box box,
    double? sphereMargin,
    bool? inverted,
    int? fillUpTo,
    Offset? initialCursorPosition,
    required BuildContext context,
  }) {
    _interactionMode = isMobileWebBrowser ? InputMethod.touch : InputMethod.mouse;

    if (_interactionMode == InputMethod.mouse) {
      _setCursorPositionStream(cursorPositionStream);
    }

    _initializeConfiguration(tags, clickableTags, inverted, fillUpTo);
    _calculateUiConstraints(box, sphereMargin, context);
    _createTicker(vsync);
    _createTagCollections(tags, clickableTags);
    _distributeTagsInSphere();
    _calculateSizeRange();
    _initializeAnimationState();

    if (initialCursorPosition != null &&
        _interactionMode == InputMethod.mouse) {
      _onNewCursorPostion(initialCursorPosition);
    } else {
      notifyListeners();
    }
  }

  void onDispose() {
    _ticker?.dispose();
    _cursorPositionStream?.cancel();
  }

  void onResize(Box box, double? sphereMargin, BuildContext context) {
    if (_box.boxSize == box.boxSize) return;
    _box = box;

    _calculateUiConstraints(box, sphereMargin, context);
    _distributeTagsInSphere();
  }

  void updateTags({
    required List<String> tags,
    required List<String> clickableTags,
    double? sphereMargin,
    int? fillUpTo,
    bool? inverted,
    required BuildContext context,
  }) {
    _initializeConfiguration(tags, clickableTags, inverted, fillUpTo);
    _calculateUiConstraints(_box, sphereMargin, context);
    _createTagCollections(tags, clickableTags);
    _distributeTagsInSphere();
    notifyListeners();
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  void _initializeConfiguration(
      List<String> tags, List<String> clickableTags, bool? inverted, int? fillUpTo) {
    if (fillUpTo != null) _totalTagsCount = fillUpTo.clamp(tags.length, 100000);
    if (inverted != null) _inverted = inverted;
  }

  void _calculateUiConstraints(
      Box box, double? sphereMargin, BuildContext context) {
    _leftOffset = box.position.getLeftOffsetFromViewport(
      context: context,
      boxSize: box.boxSize,
    );

    _topOffset = box.position.getTopOffsetFromViewport(
      context: context,
      boxSize: box.boxSize,
    );

    _canvasWidth = box.boxSize * box.position.width;
    _canvasHeight = box.boxSize * box.position.height;

    if (sphereMargin == null) {
      Breakpoints breakpoints = Breakpoints(context);
      if (breakpoints.isMobile()) {
        _sphereMargin = box.boxSize * 0.2;
      } else {
        _sphereMargin = box.boxSize * 0.4;
      }
    }

    _box = box;
  }

  void _createTicker(TickerProvider vsync) {
    _ticker = vsync.createTicker(_onTick)..start();
  }

  void _createTagCollections(List<String> tags, List<String> clickableTags) {
    _tags = _createMainTags(tags, clickableTags);
    _fillers = _createFillerTags(tags.length);
  }

  List<Tag> _createMainTags(List<String> tags, List<String> clickableTags) {
    return tags
        .map((tagText) => Tag(
              id: tagText,
              text: tagText,
              x: 0,
              y: 0,
              size: 0,
              originalPosition: Vector3.zero(),
              isClickable: clickableTags.contains(tagText),
              clickID: clickableTags.indexOf(tagText),
            ))
        .toList();
  }

  List<Tag> _createFillerTags(int mainTagsCount) {
    final fillerCount = _totalTagsCount - mainTagsCount;
    return List.generate(
        fillerCount,
        (index) => Tag(
              id: index.toString(),
              text: _fillerCharacter,
              x: 0,
              y: 0,
              size: 0,
              originalPosition: Vector3.zero(),
            ));
  }

  void _distributeTagsInSphere() {
    _distributeAllObjectsOptimized(
      _tags,
      _fillers,
      _canvasWidth,
      _canvasHeight,
    );
  }

  void _calculateSizeRange() {
    for (final tag in allTags) {
      _minSize = math.min(_minSize, tag.size);
      _maxSize = math.max(_maxSize, tag.size);
    }
  }

  void _initializeAnimationState() {
    _isAnimating = _interactionMode == InputMethod.mouse;
  }

  // ============================================================================
  // INTERACTION & EVENT HANDLERS
  // ============================================================================

  void _setCursorPositionStream(Stream<Offset?> cursorPositionStream) {
    _cursorPositionStream?.cancel();
    _cursorPositionStream = cursorPositionStream.listen(_onNewCursorPostion);
  }

  void _onNewCursorPostion(Offset? event) {
    _updatePositionAndRotation(event);
  }

  void startDrag(Offset globalPosition) {
    if (_interactionMode != InputMethod.touch) return;

    _isDragging = true;
    _hasInertia = false;
    _dragStartTime = DateTime.now();
    _dragStartPosition = globalPosition;
    _totalDragDistance = 0.0;
    _dragUpdateCount = 0;
    _isAnimating = false;
    notifyListeners();
  }

  void updateDrag(Offset globalPosition, Offset delta) {
    if (!_isDragging || _interactionMode != InputMethod.touch) return;

    final localDelta = Offset(delta.dx, delta.dy);
    _totalDragDistance += delta.distance;
    _dragUpdateCount++;
    _applyDragRotation(localDelta);
    notifyListeners();
  }

  void endDrag(Velocity velocity) {
    if (_interactionMode != InputMethod.touch) return;

    final gestureIntensity = _calculateGestureIntensity(velocity);
    _isDragging = false;
    _hoveredTag = null;
    _startInertiaWithGestureIntensity(velocity, gestureIntensity);
    notifyListeners();
  }

  Tag? getTappedTag(Offset? localPosition, double radius) {
    if (localPosition == null || !_isCursorInBounds(localPosition)) return null;

    List<Tag> ts = allTags.where((tag) => tag.text != '•').toList();

    for (final tag in ts) {
      if (tag.size < 0.5) continue;
      double distance = _calculateCursorDistanceFromOffset(localPosition, Offset(tag.x, tag.y));
      if (distance < radius) return tag;
    }
    return null;
  }

  // ============================================================================
  // ANIMATION
  // ============================================================================

  set rotationSpeed(double value) {
    _rotationSpeed = value;
    notifyListeners();
  }

  set rotationAxis(Vector3 value) {
    _rotationAxis = _inverted ? -value : value;
    notifyListeners();
  }

  void startAnimation() {
    _isAnimating = true;
    notifyListeners();
  }

  void stopAnimation() {
    _isAnimating = false;
    notifyListeners();
  }

  void _onTick(Duration timestamp) {
    if (!_isAnimating || _isDragging) return;

    final dt = _lastTimestamp == null ? 0.0 : (timestamp - _lastTimestamp!).inMicroseconds / 1e6;
    _lastTimestamp = timestamp;
    final safeDt = math.min(dt, 1.0 / 60.0);

    Quaternion? deltaQ;

    if (_hasInertia) {
      _updateInertiaRotation();
      if (_hasInertia && _inertiaVelocity.length > _minInertiaSpeed) {
        final angleX = _inertiaVelocity.x * safeDt;
        final angleY = _inertiaVelocity.y * safeDt;
        final maxAnglePerFrame = math.pi / 8;
        final clampedAngleX = angleX.clamp(-maxAnglePerFrame, maxAnglePerFrame);
        final clampedAngleY = angleY.clamp(-maxAnglePerFrame, maxAnglePerFrame);
        final qX = Quaternion.axisAngle(Vector3(1, 0, 0), clampedAngleX);
        final qY = Quaternion.axisAngle(Vector3(0, 1, 0), clampedAngleY);
        deltaQ = qY * qX;
      }
    } else if (_interactionMode == InputMethod.mouse) {
      final angleDelta = rotationSpeed * safeDt;
      deltaQ = Quaternion.axisAngle(_rotationAxis, angleDelta);
    }

    if (deltaQ != null) {
      for (final tag in allTags) {
        tag.originalPosition = deltaQ.rotated(tag.originalPosition);
        final screenPos = _convertToScreenCoordinates(tag.originalPosition, _canvasWidth, _canvasHeight);
        _updateTagPosition(tag, screenPos, tag.originalPosition.z, _calculateSphereRadius(_canvasWidth, _canvasHeight));
      }
      notifyListeners();
    }
  }

  void _updateInertiaRotation() {
    if (_lastTimestamp == null) return;
    if (_inertiaStartTime == null) {
      _inertiaStartTime = _lastTimestamp;
      return;
    }

    final elapsedMilliseconds = (_lastTimestamp! - _inertiaStartTime!).inMicroseconds / 1000.0;
    final decayFactor = math.exp(-elapsedMilliseconds / _timeConstant);
    _inertiaVelocity = _initialInertiaVelocity * decayFactor;

    if (_inertiaVelocity.length < _minInertiaSpeed ||
        (_lastTimestamp! - _inertiaStartTime!) > _maxInertiaDuration) {
      _hasInertia = false;
      _isAnimating = _interactionMode == InputMethod.mouse;
      _inertiaStartTime = null;
    }
  }

  // ============================================================================
  // 3D & POSITIONING
  // ============================================================================

  void _distributeAllObjectsOptimized(
    List<Tag> mainTags,
    List<Tag> fillerTags,
    double canvasWidth,
    double canvasHeight,
  ) {
    final totalCount = mainTags.length + fillerTags.length;
    final goldenRatio = _calculateGoldenRatio();
    final sphereRadius = _calculateSphereRadius(canvasWidth, canvasHeight);
    final allFibonacciPoints = <Vector3>[];
    for (int i = 0; i < totalCount; i++) {
      final sphericalCoords = _calculateSphericalCoordinates(i, totalCount, goldenRatio, sphereRadius);
      allFibonacciPoints.add(sphericalCoords);
    }

    final optimalMainTagPositions = GeodesicDistribution.generateUniformPoints(mainTags.length);
    final selectedMainTagIndices = <int>[];
    final usedIndices = <int>{};

    for (final optimalPoint in optimalMainTagPositions) {
      int nearestIndex = -1;
      double minDistance = double.infinity;
      for (int i = 0; i < allFibonacciPoints.length; i++) {
        if (usedIndices.contains(i)) continue;
        final distance = _sphericalDistance(optimalPoint, allFibonacciPoints[i].normalized());
        if (distance < minDistance) {
          minDistance = distance;
          nearestIndex = i;
        }
      }
      if (nearestIndex >= 0) {
        selectedMainTagIndices.add(nearestIndex);
        usedIndices.add(nearestIndex);
      }
    }

    for (int i = 0; i < mainTags.length; i++) {
      final fibonacciIndex = selectedMainTagIndices[i];
      _assignTagPosition(mainTags[i], fibonacciIndex, totalCount, goldenRatio, sphereRadius, canvasWidth, canvasHeight);
    }

    final occupiedIndices = selectedMainTagIndices.toSet();
    int fillerIndex = 0;
    for (int i = 0; i < totalCount && fillerIndex < fillerTags.length; i++) {
      if (!occupiedIndices.contains(i)) {
        _assignTagPosition(fillerTags[fillerIndex], i, totalCount, goldenRatio, sphereRadius, canvasWidth, canvasHeight);
        fillerIndex++;
      }
    }
  }

  double _sphericalDistance(Vector3 a, Vector3 b) {
    return math.acos((a.dot(b)).clamp(-1.0, 1.0));
  }

  double _calculateGoldenRatio() => (1 + math.sqrt(5)) / 2;

  double _calculateSphereRadius(double canvasWidth, double canvasHeight) {
    return math.min(canvasWidth, canvasHeight) / 2 - _sphereMargin;
  }

  void _assignTagPosition(
    Tag tag,
    int index,
    int totalCount,
    double goldenRatio,
    double sphereRadius,
    double canvasWidth,
    double canvasHeight,
  ) {
    final sphericalCoordinates = _calculateSphericalCoordinates(index, totalCount, goldenRatio, sphereRadius);
    tag.originalPosition = Vector3.copy(sphericalCoordinates);
    final screenPosition = _convertToScreenCoordinates(sphericalCoordinates, canvasWidth, canvasHeight);
    _updateTagPosition(tag, screenPosition, sphericalCoordinates.z, sphereRadius);
  }

  Vector3 _calculateSphericalCoordinates(
    int index,
    int totalCount,
    double goldenRatio,
    double sphereRadius,
  ) {
    final theta = 2 * math.pi * index / goldenRatio;
    final phi = math.acos(1 - 2 * (index + 0.5) / totalCount);
    final x = sphereRadius * math.sin(phi) * math.cos(theta);
    final y = sphereRadius * math.sin(phi) * math.sin(theta);
    final z = sphereRadius * math.cos(phi);
    return Vector3(x, y, z);
  }

  Vector3 _convertToScreenCoordinates(
    Vector3 sphericalCoords,
    double canvasWidth,
    double canvasHeight,
  ) {
    return Vector3(
      sphericalCoords.x + canvasWidth / 2,
      sphericalCoords.y + canvasHeight / 2,
      sphericalCoords.z,
    );
  }

  void _updateTagPosition(Tag tag, Vector3 screenPos, double zDepth, double sphereRadius) {
    tag.x = screenPos.x;
    tag.y = screenPos.y;
    final normalizedDepth = (zDepth + sphereRadius) / (2 * sphereRadius);
    // print('normalizedDepth: $normalizedDepth');
    tag.size = normalizedDepth;
  }

  void _updatePositionAndRotation(Offset? globalPosition) {
    if (_interactionMode != InputMethod.mouse || _isDragging) return;

    _lastCursorPosition = globalPosition;
    Offset? localPosition = _globalToLocal(globalPosition);
    double distance = _calculateCursorDistanceFromCenter(localPosition);
    double normalizedDistance = _normalizeCursorDistance(distance);
    rotationSpeed = normalizedDistance * (_isCursorInBounds(localPosition) ? 6.0 : 3);

    Vector3? calculatedRotationAxis = _calculateRotationAxis(localPosition);
    if (calculatedRotationAxis != null) {
      rotationAxis = Vector3(calculatedRotationAxis.x, calculatedRotationAxis.y, 0);
    }

    _hoveredTag = findHoveredTag(localPosition);
    notifyListeners();
  }

  Offset? _globalToLocal(Offset? globalPosition) {
    if (globalPosition == null) return null;
    return Offset(
      globalPosition.dx - _leftOffset,
      globalPosition.dy - _topOffset,
    );
  }

  Offset? _localToCenter(Offset? localPosition) {
    if (localPosition == null) return null;
    return Offset(
      localPosition.dx - _canvasWidth / 2,
      localPosition.dy - _canvasHeight / 2,
    );
  }

  bool _isCursorInBounds(Offset? cursorPosition) {
    if (cursorPosition == null) return false;
    return cursorPosition.dx >= 0 &&
        cursorPosition.dx <= _canvasWidth &&
        cursorPosition.dy >= 0 &&
        cursorPosition.dy <= _canvasHeight;
  }

  double _calculateCursorDistanceFromOffset(Offset? cursorPosition, Offset? offset) {
    if (cursorPosition == null || offset == null) return 0.0;
    return math.sqrt(math.pow(cursorPosition.dx - offset.dx, 2) +
        math.pow(cursorPosition.dy - offset.dy, 2));
  }

  double _calculateCursorDistanceFromCenter(Offset? cursorPosition) {
    if (cursorPosition == null) return 0.0;
    return math.sqrt(math.pow(cursorPosition.dx - _canvasWidth / 2, 2) +
        math.pow(cursorPosition.dy - _canvasHeight / 2, 2));
  }

  double _normalizeCursorDistance(double distance) {
    double maxDistance = _canvasWidth / 2;
    return interpolate(value: distance, range: [0, maxDistance], outputRange: [0, 1]);
  }

  Vector3? _calculateRotationAxis(Offset? localCursorPosition) {
    if (localCursorPosition == null) return null;
    final Offset v = _localToCenter(localCursorPosition)!;
    final Vector3 axis = Vector3(-v.dy, v.dx, 0);
    return axis.length2 == 0 ? null : axis.normalized();
  }

  Tag? findHoveredTag(Offset? localPosition) {
    if (localPosition == null || !_isCursorInBounds(localPosition)) return null;

    double minDistance = double.infinity;
    Tag? currentTag;
    List<Tag> ts = allTags.where((tag) => tag.text != '•').toList();

    for (final tag in ts) {
      if (tag.size < 0.5) continue;
      double distance = _calculateCursorDistanceFromOffset(localPosition, Offset(tag.x, tag.y));
      if (distance < minDistance) {
        minDistance = distance;
        currentTag = tag;
      }
    }
    return currentTag;
  }

  double _calculateGestureIntensity(Velocity velocity) {
    if (_dragStartTime == null || _dragStartPosition == null) {
      return velocity.pixelsPerSecond.distance;
    }

    final durationMs = DateTime.now().difference(_dragStartTime!).inMicroseconds / 1000.0;
    if (durationMs < 10) return velocity.pixelsPerSecond.distance;

    final ourCalculatedSpeed = _totalDragDistance / (durationMs / 1000.0);
    final flutterVelocity = velocity.pixelsPerSecond.distance;
    final isFlutterClamped = flutterVelocity > 7500;

    double adjustedIntensity;
    if (isFlutterClamped) {
      adjustedIntensity = math.max(ourCalculatedSpeed, flutterVelocity);
      if (durationMs < 150 && _totalDragDistance > 100) {
        adjustedIntensity *= 1.5;
      }
    } else {
      adjustedIntensity = flutterVelocity;
    }

    return math.min(adjustedIntensity, 25000);
  }

  void _startInertiaWithGestureIntensity(Velocity velocity, double gestureIntensity) {
    final velocityDirection = velocity.pixelsPerSecond;
    final intensityScale = gestureIntensity / math.max(velocityDirection.distance, 1.0);
    final enhancedVelocity = velocityDirection * intensityScale;

    double velocityScale;
    if (gestureIntensity < 2000) {
      velocityScale = 0.004;
    } else if (gestureIntensity < 8000) {
      velocityScale = 0.003;
    } else {
      velocityScale = 0.002 * math.log(8000 / gestureIntensity + 1);
    }

    final rotationVelocityX = enhancedVelocity.dy * velocityScale;
    final rotationVelocityY = -enhancedVelocity.dx * velocityScale;

    _initialInertiaVelocity = Vector3(rotationVelocityX, rotationVelocityY, 0);
    _inertiaVelocity = Vector3.copy(_initialInertiaVelocity);

    final maxVelocity = 35.0;
    if (_inertiaVelocity.length > maxVelocity) {
      final scale = maxVelocity / _inertiaVelocity.length;
      _inertiaVelocity *= scale;
      _initialInertiaVelocity *= scale;
    }

    if (_inertiaVelocity.length > _minInertiaSpeed) {
      _hasInertia = true;
      _isAnimating = true;
      _inertiaStartTime = null;
      _lastTimestamp = null;
    }
  }

  void _applyDragRotation(Offset delta) {
    final rotationX = delta.dy * _dragSensitivity;
    final rotationY = -delta.dx * _dragSensitivity;
    final qX = Quaternion.axisAngle(Vector3(1, 0, 0), rotationX);
    final qY = Quaternion.axisAngle(Vector3(0, 1, 0), rotationY);
    final combinedRotation = qY * qX;

    for (final tag in allTags) {
      tag.originalPosition = combinedRotation.rotated(tag.originalPosition);
      final screenPos = _convertToScreenCoordinates(tag.originalPosition, _canvasWidth, _canvasHeight);
      _updateTagPosition(tag, screenPos, tag.originalPosition.z, _calculateSphereRadius(_canvasWidth, _canvasHeight));
    }
  }
}
