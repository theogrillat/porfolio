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

/// Input method tracking to prevent conflicts between mouse and touch
enum InputMethod { mouse, touch }

/// ViewModel for managing and animating tags in a 3D sphere layout
class TagsViewModel extends BaseViewModel {
  // ============================================================================
  // CONSTANTS
  // ============================================================================

  static const String _fillerCharacter = '•';

  // ============================================================================
  // PRIVATE FIELDS
  // ============================================================================

  int _totalTagsCount = 300;
  double _sphereMargin = 50.0;
  late Box _box;
  late double _leftOffset;
  late double _topOffset;
  double _minSize = double.infinity;
  double _maxSize = double.negativeInfinity;
  late List<Tag> _tags;
  late List<Tag> _fillers;
  late double _canvasWidth;
  late double _canvasHeight;
  Ticker? _ticker;

  // ============================================================================
  // PUBLIC GETTERS
  // ============================================================================

  double get minSize => _minSize;
  double get maxSize => _maxSize;
  List<Tag> get allTags => _tags + _fillers;
  double get width => _canvasWidth;
  double get height => _canvasHeight;

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  /// Initializes the tag system with given parameters
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
    // Determine interaction mode based on platform
    _interactionMode = isMobileWebBrowser ? InputMethod.touch : InputMethod.mouse;

    // Only set up cursor stream for desktop browsers
    if (_interactionMode == InputMethod.mouse) {
      _setCursorPositionStream(cursorPositionStream);
    }

    _initializeConfiguration(tags, clickableTags, inverted, fillUpTo);
    _calculateUiConstraints(box, sphereMargin, context);
    _createTicker(vsync);
    _createTagCollections(tags, clickableTags);
    _distributeTagsInSphere();
    _calculateSizeRange();

    // Set initial animation state based on interaction mode
    _initializeAnimationState();

    if (initialCursorPosition != null && _interactionMode == InputMethod.mouse) {
      print('Initial Cursor Position: ${initialCursorPosition.dx}, ${initialCursorPosition.dy}');
      _onNewCursorPostion(initialCursorPosition);
    } else {
      notifyListeners();
    }
  }

  /// Cleans up resources when disposing
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
  // INITIALIZATION METHODS
  // ============================================================================

  void _initializeConfiguration(List<String> tags, List<String> clickableTags, bool? inverted, int? fillUpTo) {
    if (fillUpTo != null) _totalTagsCount = fillUpTo.clamp(tags.length, 100000);
    if (inverted != null) _inverted = inverted;
  }

  void _calculateUiConstraints(Box box, double? sphereMargin, BuildContext context) {
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

  /// Initialize animation state based on interaction mode
  void _initializeAnimationState() {
    // Touch devices: no auto-rotation (user has full control)
    // Desktop devices: auto-rotation enabled (mouse cursor controls rotation)
    _isAnimating = _interactionMode == InputMethod.mouse;
  }

  // ============================================================================
  // Cursor Interactions
  // ============================================================================

  StreamSubscription<Offset?>? _cursorPositionStream;

  Offset? _lastCursorPosition;
  Offset? get lastCursorPosition => _lastCursorPosition;

  void _setCursorPositionStream(Stream<Offset?> cursorPositionStream) {
    _cursorPositionStream?.cancel();
    _cursorPositionStream = cursorPositionStream.listen(_onNewCursorPostion);
  }

  void _onNewCursorPostion(Offset? event) {
    _updatePositionAndRotation(event);
  }

  // ============================================================================
  // PLATFORM-SPECIFIC INTERACTION
  // ============================================================================

  bool _isDragging = false;
  bool get isDragging => _isDragging;
  double _dragSensitivity = 0.005; // Adjust this to control rotation sensitivity

  // Platform-specific interaction mode (determined on init)
  late final InputMethod _interactionMode;
  InputMethod get interactionMode => _interactionMode;

  // ============================================================================
  // CORRECTED IOS-STYLE INERTIA CONSTANTS
  // ============================================================================

  // iOS uses specific time constant for natural feel
  static const double _timeConstant = 325.0; // milliseconds - iOS standard
  static const double _minInertiaSpeed = 0.005; // Lower threshold
  static const Duration _maxInertiaDuration = Duration(milliseconds: 2000); // 2 seconds max

  // Inertia state tracking
  bool _hasInertia = false;
  Vector3 _inertiaVelocity = Vector3.zero();
  Duration? _inertiaStartTime;
  Vector3 _initialInertiaVelocity = Vector3.zero();

  DateTime? _dragStartTime;
  Offset? _dragStartPosition;
  double _totalDragDistance = 0.0;
  int _dragUpdateCount = 0;

  /// Enhanced drag start that tracks gesture timing
  void startDrag(Offset globalPosition) {
    if (_interactionMode != InputMethod.touch) return;

    print('Start drag called');

    _isDragging = true;
    _hasInertia = false;

    // Track gesture characteristics for intensity detection
    _dragStartTime = DateTime.now();
    _dragStartPosition = globalPosition;
    _totalDragDistance = 0.0;
    _dragUpdateCount = 0;

    _isAnimating = false;
    notifyListeners();
  }

  /// Enhanced drag update that accumulates distance
  void updateDrag(Offset globalPosition, Offset delta) {
    if (!_isDragging || _interactionMode != InputMethod.touch) return;

    final localDelta = Offset(delta.dx, delta.dy);

    // Track total distance and update count
    _totalDragDistance += delta.distance;
    _dragUpdateCount++;

    _applyDragRotation(localDelta);

    // final localPosition = _globalToLocal(globalPosition);
    // _hoveredTag = findHoveredTag(localPosition);

    notifyListeners();
  }

  /// Enhanced drag end that calculates real gesture intensity
  void endDrag(Velocity velocity) {
    if (_interactionMode != InputMethod.touch) return;

    final flutterVelocity = velocity.pixelsPerSecond.distance;

    // Calculate our own gesture metrics
    final gestureIntensity = _calculateGestureIntensity(velocity);

    print('Drag end: Flutter velocity=${flutterVelocity.toStringAsFixed(0)} px/s, '
        'Gesture intensity=${gestureIntensity.toStringAsFixed(1)}');

    _isDragging = false;
    _hoveredTag = null;

    // Use enhanced inertia calculation
    _startInertiaWithGestureIntensity(velocity, gestureIntensity);

    notifyListeners();
  }

  /// Calculate gesture intensity beyond Flutter's 8000 px/s limit
  double _calculateGestureIntensity(Velocity velocity) {
    if (_dragStartTime == null || _dragStartPosition == null) {
      return velocity.pixelsPerSecond.distance;
    }

    final gestureDuration = DateTime.now().difference(_dragStartTime!);
    final durationMs = gestureDuration.inMicroseconds / 1000.0;

    // Avoid division by zero
    if (durationMs < 10) return velocity.pixelsPerSecond.distance;

    // Calculate our own speed based on total distance and time
    final ourCalculatedSpeed = _totalDragDistance / (durationMs / 1000.0);

    // Additional intensity factors
    final updateFrequency = _dragUpdateCount / (durationMs / 1000.0); // updates per second
    final flutterVelocity = velocity.pixelsPerSecond.distance;

    // Detect when Flutter is likely clamping (at or near 8000 px/s)
    final isFlutterClamped = flutterVelocity > 7500;

    double adjustedIntensity;
    if (isFlutterClamped) {
      // Use our calculated speed when Flutter is clamped
      adjustedIntensity = math.max(ourCalculatedSpeed, flutterVelocity);

      // Boost for very short, intense gestures (flicks)
      if (durationMs < 150 && _totalDragDistance > 100) {
        adjustedIntensity *= 1.5; // Flick multiplier
      }

      print('Flutter clamped detected: duration=${durationMs.toStringAsFixed(0)}ms, '
          'distance=${_totalDragDistance.toStringAsFixed(0)}px, '
          'our_speed=${ourCalculatedSpeed.toStringAsFixed(0)} vs flutter=${flutterVelocity.toStringAsFixed(0)}');
    } else {
      // Flutter velocity is reliable for slower gestures
      adjustedIntensity = flutterVelocity;
    }

    // Cap at reasonable maximum to prevent jumps
    return math.min(adjustedIntensity, 25000);
  }

  /// Enhanced inertia using gesture intensity instead of clamped Flutter velocity
  void _startInertiaWithGestureIntensity(Velocity velocity, double gestureIntensity) {
    final velocityDirection = velocity.pixelsPerSecond;

    // Use gesture intensity for magnitude, Flutter velocity for direction
    final intensityScale = gestureIntensity / math.max(velocityDirection.distance, 1.0);
    final enhancedVelocity = velocityDirection * intensityScale;

    print('Enhanced velocity: ${enhancedVelocity.distance.toStringAsFixed(0)} px/s '
        '(${intensityScale.toStringAsFixed(2)}x boost)');

    // Use variable scaling based on intensity
    double velocityScale;
    if (gestureIntensity < 2000) {
      velocityScale = 0.004; // High sensitivity for slow gestures
    } else if (gestureIntensity < 8000) {
      velocityScale = 0.003; // Standard sensitivity
    } else {
      // Logarithmic scaling for very fast gestures
      velocityScale = 0.002 * math.log(8000 / gestureIntensity + 1);
    }

    final rotationVelocityX = enhancedVelocity.dy * velocityScale;
    final rotationVelocityY = -enhancedVelocity.dx * velocityScale;

    _initialInertiaVelocity = Vector3(rotationVelocityX, rotationVelocityY, 0);
    _inertiaVelocity = Vector3.copy(_initialInertiaVelocity);

    // Higher limit since we're now detecting true fast swipes
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

      print('Starting enhanced inertia: intensity=${gestureIntensity.toStringAsFixed(0)} → rotation=${_initialInertiaVelocity.length.toStringAsFixed(3)}');
    }
  }

  /// Applies rotation based on drag delta
  void _applyDragRotation(Offset delta) {
    // Convert 2D drag delta to 3D rotation
    // Horizontal drag -> rotation around Y axis
    // Vertical drag -> rotation around X axis

    final rotationX = delta.dy * _dragSensitivity;
    final rotationY = -delta.dx * _dragSensitivity;

    // Create rotation quaternions for each axis
    final qX = Quaternion.axisAngle(Vector3(1, 0, 0), rotationX);
    final qY = Quaternion.axisAngle(Vector3(0, 1, 0), rotationY);

    // Combine rotations
    final combinedRotation = qY * qX;

    // Apply rotation to all tags
    for (final tag in allTags) {
      tag.originalPosition = combinedRotation.rotated(tag.originalPosition);
      final screenPos = _convertToScreenCoordinates(tag.originalPosition, _canvasWidth, _canvasHeight);
      _updateTagPosition(tag, screenPos, tag.originalPosition.z, _calculateSphereRadius(_canvasWidth, _canvasHeight));
    }
  }

  /// Uses proper exponential decay formula: v(t) = v₀ * e^(-t/τ)
  /// Uses proper exponential decay formula with realistic velocity limits
  void _startInertiaFromNativeVelocity(Velocity velocity) {
    final velocityPixelsPerSecond = velocity.pixelsPerSecond;

    // Much higher velocity limits - fast swipes can reach 10,000+ px/s
    if (velocityPixelsPerSecond.distance > 25000) {
      print('Rejecting extreme velocity: ${velocityPixelsPerSecond.distance.toStringAsFixed(1)} px/s');
      return;
    }

    // Enhanced velocity scaling with logarithmic damping for high speeds
    final velocityMagnitude = velocityPixelsPerSecond.distance;

    // Use logarithmic scaling to handle wide velocity range naturally
    // This prevents slow gestures from being too weak and fast ones from being too strong
    double scalingFactor;
    if (velocityMagnitude < 1000) {
      scalingFactor = 0.004; // Higher sensitivity for slow gestures
    } else if (velocityMagnitude < 5000) {
      scalingFactor = 0.003; // Medium sensitivity
    } else {
      // Logarithmic scaling for high velocities to prevent jumps
      scalingFactor = 0.002 * math.log(5000 / velocityMagnitude + 1);
    }

    print('Velocity: ${velocityMagnitude.toStringAsFixed(0)} px/s, scaling: ${scalingFactor.toStringAsFixed(4)}');

    final rotationVelocityX = velocityPixelsPerSecond.dy * scalingFactor;
    final rotationVelocityY = -velocityPixelsPerSecond.dx * scalingFactor;

    _initialInertiaVelocity = Vector3(rotationVelocityX, rotationVelocityY, 0);
    _inertiaVelocity = Vector3.copy(_initialInertiaVelocity);

    // Higher but still safe max velocity
    final maxVelocity = 25.0;
    if (_inertiaVelocity.length > maxVelocity) {
      final scale = maxVelocity / _inertiaVelocity.length;
      _inertiaVelocity *= scale;
      _initialInertiaVelocity *= scale;
      print('Clamped rotation velocity from ${(_inertiaVelocity.length / scale).toStringAsFixed(1)} to ${maxVelocity}');
    }

    // Lower threshold for starting inertia
    if (_inertiaVelocity.length > _minInertiaSpeed) {
      _hasInertia = true;
      _isAnimating = true;
      _inertiaStartTime = null;
      _lastTimestamp = null;

      print('Starting iOS-style inertia: velocity=${velocityMagnitude.toStringAsFixed(0)} px/s → rotation=${_initialInertiaVelocity.length.toStringAsFixed(3)}');
    } else {
      print('Velocity too small: rotation=${_inertiaVelocity.length.toStringAsFixed(3)} < ${_minInertiaSpeed}');
    }
  }

  /// Mouse cursor position updates (only available on desktop browsers)
  void _updatePositionAndRotation(Offset? globalPosition) {
    // Only process mouse input on desktop browsers
    if (_interactionMode != InputMethod.mouse || _isDragging) return;

    _lastCursorPosition = globalPosition;
    Offset? localPosition = _globalToLocal(globalPosition);

    double distance = _calculateCursorDistanceFromCenter(localPosition);
    double normalizedDistance = _normalizeCursorDistance(distance);

    rotationSpeed = normalizedDistance;

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
    return cursorPosition.dx >= 0 && cursorPosition.dx <= _canvasWidth && cursorPosition.dy >= 0 && cursorPosition.dy <= _canvasHeight;
  }

  double _calculateCursorDistanceFromOffset(Offset? cursorPosition, Offset? offset) {
    if (cursorPosition == null || offset == null) return 0.0;
    return math.sqrt(math.pow(cursorPosition.dx - offset.dx, 2) + math.pow(cursorPosition.dy - offset.dy, 2));
  }

  double _calculateCursorDistanceFromCenter(Offset? cursorPosition) {
    if (cursorPosition == null) return 0.0;
    return math.sqrt(math.pow(cursorPosition.dx - _canvasWidth / 2, 2) + math.pow(cursorPosition.dy - _canvasHeight / 2, 2));
  }

  double _normalizeCursorDistance(double distance) {
    double maxDistance = _canvasWidth / 2;
    return interpolate(value: distance, range: [0, maxDistance], outputRange: [0, 1]);
  }

  Vector3? _calculateRotationAxis(Offset? localCursorPosition) {
    if (localCursorPosition == null) return null;

    // Vector centre → cursor in widget space.
    final Offset v = _localToCenter(localCursorPosition)!; // (dx, dy)

    // 90° CCW in the XY plane → (−dy, dx).
    final Vector3 axis = Vector3(-v.dy, v.dx, 0);

    // Avoid divide-by-zero if the cursor is on the centre.
    return axis.length2 == 0 ? null : axis.normalized();
  }

  Tag? _hoveredTag;

  Tag? get hoveredTag => _hoveredTag;

  // Returns the closest tag to the given local position
  Tag? findHoveredTag(Offset? localPosition) {
    if (localPosition == null) return null;
    if (!_isCursorInBounds(localPosition)) return null;

    double minDistance = double.infinity;

    Tag? currentTag;

    List<Tag> ts = allTags.where((tag) => tag.text != '•').toList();

    for (final tag in ts) {
      double distance = _calculateCursorDistanceFromOffset(localPosition, Offset(tag.x, tag.y));
      if (tag.size < 0.5) continue;
      if (distance < minDistance) {
        minDistance = distance;
        currentTag = tag;
      }
    }
    return currentTag;
  }

  // Returns the tag that was tapped at the given local position
  Tag? getTappedTag(Offset? localPosition, double radius) {
    if (localPosition == null) return null;
    if (!_isCursorInBounds(localPosition)) return null;

    List<Tag> ts = allTags.where((tag) => tag.text != '•').toList();

    for (final tag in ts) {
      if (tag.size < 0.5) continue;
      double distance = _calculateCursorDistanceFromOffset(localPosition, Offset(tag.x, tag.y));
      if (distance < radius) return tag;
    }
    return null;
  }

  // ============================================================================
  // ANIMATION METHODS
  // ============================================================================

  bool _isAnimating = false; // Will be set by _initializeAnimationState()
  bool get isAnimating => _isAnimating;

  bool _inverted = false;
  bool get inverted => _inverted;

  double _rotationSpeed = 1.0;
  double get rotationSpeed => _rotationSpeed;

  set rotationSpeed(double value) {
    _rotationSpeed = value;
    notifyListeners();
  }

  Vector3 _rotationAxis = Vector3(1.0, 0.5, 0.2);
  Vector3 get rotationAxis => _rotationAxis;

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

  Duration? _lastTimestamp;

  void _onTick(Duration timestamp) {
    if (!_isAnimating || _isDragging) return;

    final dt = _lastTimestamp == null ? 0.0 : (timestamp - _lastTimestamp!).inMicroseconds / 1e6;
    _lastTimestamp = timestamp;

    // More reasonable dt limit - 60fps minimum
    final maxDt = 1.0 / 60.0; // 60fps (16.67ms)
    final safeDt = math.min(dt, maxDt);

    Quaternion? deltaQ;

    if (_hasInertia) {
      // Update inertia first
      _updateInertiaRotation();

      if (_hasInertia && _inertiaVelocity.length > _minInertiaSpeed) {
        // Calculate rotation for this frame using current velocity
        final angleX = _inertiaVelocity.x * safeDt;
        final angleY = _inertiaVelocity.y * safeDt;

        // More reasonable angle limits - smoother rotation
        final maxAnglePerFrame = math.pi / 8; // 22.5 degrees max per frame (was 45)
        final clampedAngleX = angleX.clamp(-maxAnglePerFrame, maxAnglePerFrame);
        final clampedAngleY = angleY.clamp(-maxAnglePerFrame, maxAnglePerFrame);

        // Debug logging
        if (_inertiaVelocity.length > 0.1) {
          print('Inertia tick: velocity=${_inertiaVelocity.length.toStringAsFixed(3)}, angleX=${clampedAngleX.toStringAsFixed(4)}, angleY=${clampedAngleY.toStringAsFixed(4)}');
        }

        // Create rotation quaternion
        final qX = Quaternion.axisAngle(Vector3(1, 0, 0), clampedAngleX);
        final qY = Quaternion.axisAngle(Vector3(0, 1, 0), clampedAngleY);
        deltaQ = qY * qX;
      } else if (_hasInertia) {
        print('Inertia velocity too low: ${_inertiaVelocity.length.toStringAsFixed(3)} < ${_minInertiaSpeed}');
      }
    } else {
      // Handle mouse cursor rotation (desktop only)
      if (_interactionMode == InputMethod.mouse) {
        final angleDelta = rotationSpeed * safeDt;
        deltaQ = Quaternion.axisAngle(_rotationAxis, angleDelta);
      }
    }

    // Apply rotation if we have one
    if (deltaQ != null) {
      for (final tag in allTags) {
        tag.originalPosition = deltaQ.rotated(tag.originalPosition);
        final screenPos = _convertToScreenCoordinates(tag.originalPosition, _canvasWidth, _canvasHeight);
        _updateTagPosition(tag, screenPos, tag.originalPosition.z, _calculateSphereRadius(_canvasWidth, _canvasHeight));
      }
      notifyListeners();
    }
  }

  /// Corrected iOS-style exponential decay: v(t) = v₀ * e^(-t/τ)
  void _updateInertiaRotation() {
    if (_lastTimestamp == null) return;

    // Set start time on first frame
    if (_inertiaStartTime == null) {
      _inertiaStartTime = _lastTimestamp;
      return; // Use initial velocity on first frame
    }

    // Calculate elapsed time in milliseconds
    final elapsedTime = _lastTimestamp! - _inertiaStartTime!;
    final elapsedMilliseconds = elapsedTime.inMicroseconds / 1000.0; // Convert to milliseconds

    // Proper exponential decay formula: v(t) = v₀ * e^(-t/τ)
    // where τ is the time constant (325ms for iOS)
    final decayFactor = math.exp(-elapsedMilliseconds / _timeConstant);
    _inertiaVelocity = _initialInertiaVelocity * decayFactor;

    // Debug logging for first 500ms
    if (elapsedMilliseconds < 500) {
      print('Decay: t=${elapsedMilliseconds.toStringAsFixed(0)}ms, '
          'factor=${decayFactor.toStringAsFixed(3)}, '
          'velocity=${_inertiaVelocity.length.toStringAsFixed(3)}');
    }

    // Stop when velocity drops below threshold OR max duration reached
    if (_inertiaVelocity.length < _minInertiaSpeed || elapsedTime > _maxInertiaDuration) {
      _hasInertia = false;
      _isAnimating = _interactionMode == InputMethod.mouse; // Resume mouse animation if desktop
      _inertiaStartTime = null;

      print('Inertia stopped: t=${elapsedMilliseconds.toStringAsFixed(0)}ms, '
          'final velocity=${_inertiaVelocity.length.toStringAsFixed(4)}');
    }
  }

  // ============================================================================
  // 3D POSITIONING & DISTRIBUTION METHODS
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

    // Step 1: Generate ALL points using your existing method (perfect distribution)
    final allFibonacciPoints = <Vector3>[];
    final random = math.Random(42);
    final tempOccupiedIndices = <int>{};

    // Generate temporary main tag positions (we'll replace this logic)
    for (int i = 0; i < mainTags.length; i++) {
      final baseSpacing = totalCount / mainTags.length;
      int targetIndex = (i * baseSpacing).round();
      final offset = random.nextInt(20) - 10;
      targetIndex = (targetIndex + offset).clamp(0, totalCount - 1);

      while (tempOccupiedIndices.contains(targetIndex)) {
        targetIndex = (targetIndex + 1) % totalCount;
      }
      tempOccupiedIndices.add(targetIndex);
    }

    // Generate all Fibonacci points in order
    for (int i = 0; i < totalCount; i++) {
      final sphericalCoords = _calculateSphericalCoordinates(i, totalCount, goldenRatio, sphereRadius);
      allFibonacciPoints.add(sphericalCoords);
    }

    // Step 2: Generate optimal main tag positions using Geodesic
    final optimalMainTagPositions = GeodesicDistribution.generateUniformPoints(mainTags.length);

    // Step 3: For each optimal position, find the nearest Fibonacci point
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

    // Step 4: Assign main tags to selected positions
    for (int i = 0; i < mainTags.length; i++) {
      final fibonacciIndex = selectedMainTagIndices[i];
      _assignTagPosition(
        mainTags[i],
        fibonacciIndex,
        totalCount,
        goldenRatio,
        sphereRadius,
        canvasWidth,
        canvasHeight,
      );
    }

    // Step 5: Assign fillers to all remaining positions
    final occupiedIndices = selectedMainTagIndices.toSet();
    int fillerIndex = 0;
    for (int i = 0; i < totalCount && fillerIndex < fillerTags.length; i++) {
      if (!occupiedIndices.contains(i)) {
        _assignTagPosition(
          fillerTags[fillerIndex],
          i,
          totalCount,
          goldenRatio,
          sphereRadius,
          canvasWidth,
          canvasHeight,
        );
        fillerIndex++;
      }
    }
  }

  // Helper method for spherical distance
  double _sphericalDistance(Vector3 a, Vector3 b) {
    return math.acos((a.dot(b)).clamp(-1.0, 1.0));
  }

  // ----------------------------------------------------------------------------
  // Mathematical Calculations
  // ----------------------------------------------------------------------------

  double _calculateGoldenRatio() => (1 + math.sqrt(5)) / 2;

  double _calculateSphereRadius(double canvasWidth, double canvasHeight) {
    return math.min(canvasWidth, canvasHeight) / 2 - _sphereMargin;
  }

  // ----------------------------------------------------------------------------
  // Position Assignment & Coordinate Transformation
  // ----------------------------------------------------------------------------

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

    // STORE THE ORIGINAL 3D POSITION HERE
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

    // Calculate normalized depth for size scaling (0.0 to 1.0)
    final normalizedDepth = (zDepth + sphereRadius) / (2 * sphereRadius);
    tag.size = normalizedDepth;
  }
}
