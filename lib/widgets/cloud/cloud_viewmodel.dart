import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:stacked/stacked.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

// ============================================================================
// SPHERE TAG MODEL
// ============================================================================

class SphereTag {
  final int id;
  final String text;
  final vm.Vector3 position3D;
  Offset position2D;
  final double size;
  double depth;
  final double textWidth;
  final double textHeight;
  final double tagSize;

  SphereTag({
    required this.id,
    required this.text,
    required this.position3D,
    required this.position2D,
    required this.size,
    required this.depth,
    required this.textWidth,
    required this.textHeight,
    required this.tagSize,
  });
}

// ============================================================================
// CLOUD VIEWMODEL
// ============================================================================

class CloudViewModel extends BaseViewModel {
  // ============================================================================
  // PROPERTIES
  // ============================================================================

  // ----------------------------------------------------------------------------
  // STATE
  // ----------------------------------------------------------------------------

  bool _showCloud = false;
  bool get showCloud => _showCloud;

  bool _mounted = true;
  bool get mounted => _mounted;

  // ----------------------------------------------------------------------------
  // CONFIGURATION
  // ----------------------------------------------------------------------------

  late List<String> _tags;
  late double _height;
  late double _width;
  late double _topViewportOffset;
  late double _leftViewportOffset;
  late double _tagSize;
  late bool _invertDirection;

  List<String> get tags => _tags;
  double get height => _height;
  double get width => _width;
  double get topViewportOffset => _topViewportOffset;
  double get leftViewportOffset => _leftViewportOffset;
  double get tagSize => _tagSize;
  bool get invertDirection => _invertDirection;

  // ----------------------------------------------------------------------------
  // MOUSE & INTERACTION
  // ----------------------------------------------------------------------------

  StreamSubscription<Offset?>? _mousePositionStream;
  Offset? _globalMousePosition;
  Offset? get globalMousePosition => _globalMousePosition;
  Offset? _localMousePosition;
  Offset? get localMousePosition => _localMousePosition;

  double get maxVectorLength => _width / 2;

  double get vectorLength {
    if (_localMousePosition == null) return 0;
    final double dx = _localMousePosition!.dx;
    final double dy = _localMousePosition!.dy;
    final double length = math.sqrt(dx * dx + dy * dy);
    return length.isFinite ? length : 0.0;
  }

  double get vectorLengthPercentage {
    final double length = vectorLength;
    final double maxLength = maxVectorLength;
    if (maxLength == 0 || !length.isFinite || !maxLength.isFinite) return 0.0;
    return (length / maxLength).clamp(0.0, 1.0);
  }

  double get vectorAngle {
    if (_localMousePosition == null) return 0.0;
    final double dx = _localMousePosition!.dx;
    final double dy = _localMousePosition!.dy;
    if (!dx.isFinite || !dy.isFinite) return 0.0;
    final double angle = math.atan2(dy, dx);
    return angle.isFinite ? angle : 0.0;
  }

  // ----------------------------------------------------------------------------
  // 3D SPHERE
  // ----------------------------------------------------------------------------

  double _sphereRadius = 100.0;
  double get sphereRadius => _sphereRadius;
  final List<SphereTag> _sphereTags = [];
  List<SphereTag> get sphereTags => _sphereTags;

  // ----------------------------------------------------------------------------
  // ANIMATION
  // ----------------------------------------------------------------------------

  Timer? _animationTimer;
  double _targetRotationSpeed = 0.0;
  double get targetRotationSpeed => _targetRotationSpeed;
  double _targetRotationAngle = 0.0;
  double get targetRotationAngle => _targetRotationAngle;
  static const double _maxRotationSpeed = 2.0;
  vm.Matrix3 _rotationMatrix = vm.Matrix3.identity();
  double _moveX = 0;
  double get moveX => _moveX;
  double _moveY = 0;
  double get moveY => _moveY;

  // ----------------------------------------------------------------------------
  // THROTTLING & DEBOUNCING
  // ----------------------------------------------------------------------------

  DateTime _lastRotationUpdate = DateTime.now();
  static const Duration _rotationUpdateInterval = Duration(milliseconds: 33);
  Timer? _debounceTimer;
  Timer? _notificationTimer;
  static const Duration _debounceInterval = Duration(milliseconds: 16);
  bool _notificationPending = false;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  void onInit({
    required List<String> tags,
    required double height,
    required double width,
    required Stream<Offset?> mousePositionStream,
    required double topViewportOffset,
    required double leftViewportOffset,
    required Color foregroundColor,
    required double tagSize,
    required bool invertDirection,
  }) {
    _tags = tags;
    _height = height;
    _width = width;
    _topViewportOffset = topViewportOffset;
    _leftViewportOffset = leftViewportOffset;
    _tagSize = tagSize;
    _invertDirection = invertDirection;
    _mousePositionStream = mousePositionStream.listen(updateMousePosition);
    _sphereRadius = math.min(height, width) * 0.37;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mounted) {
        _distributeTagsOnSphere();
        _startAnimationTimer();
      }
    });
  }

  void onDispose() {
    _mounted = false;
    _mousePositionStream?.cancel();
    _animationTimer?.cancel();
    _debounceTimer?.cancel();
    _notificationTimer?.cancel();
    _sphereTags.clear();
    _rotationMatrix = vm.Matrix3.identity();
    _globalMousePosition = null;
    _localMousePosition = null;
    _notificationPending = false;
  }

  void onResize(double width, double height) {
    _width = width;
    _height = height;
    _sphereRadius = math.min(height, width) * 0.37;
  }

  void updateTags(List<String> newTags) {
    if (_tags != newTags) {
      _tags = newTags;
      _rotationMatrix = vm.Matrix3.identity();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mounted) {
          _distributeTagsOnSphere();
        }
      });
    }
  }

  // ============================================================================
  // EVENT HANDLERS
  // ============================================================================

  void updateMousePosition(Offset? position) {
    double globalX = position?.dx ?? 0;
    double globalY = position?.dy ?? 0;
    double localX = globalX - _leftViewportOffset - _width / 2;
    double localY = globalY - _topViewportOffset - _height / 2;
    _globalMousePosition = Offset(globalX, globalY);
    _localMousePosition = Offset(localX, localY);

    final DateTime now = DateTime.now();
    if (now.difference(_lastRotationUpdate) >= _rotationUpdateInterval) {
      if (_localMousePosition != null) {
        _targetRotationAngle = vectorAngle;
        _targetRotationSpeed = vectorLengthPercentage * _maxRotationSpeed;
      } else {
        _targetRotationSpeed = 0.0;
      }
      _lastRotationUpdate = now;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceInterval, () {
      if (_mounted) {
        _safeNotifyListeners();
      }
    });
  }

  // ============================================================================
  // ANIMATION
  // ============================================================================

  void _startAnimationTimer() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!_mounted) {
        timer.cancel();
        return;
      }
      _updateRotation();
    });
  }

  void _updateRotation() {
    try {
      if (!_mounted || _sphereTags.isEmpty) return;

      if (_targetRotationSpeed > 0 && _localMousePosition != null) {
        final double deltaTime = 1.0 / 30.0;
        final double rotationAmount = _targetRotationSpeed * deltaTime;

        if (rotationAmount < 0.001 || !rotationAmount.isFinite || rotationAmount > 1.0) return;

        final double angle = vectorAngle;
        if (!angle.isFinite) return;

        _moveX = math.cos(angle);
        _moveY = math.sin(angle);

        if (!_moveX.isFinite || !_moveY.isFinite) return;

        final vm.Vector3 rotationAxis = _invertDirection ? vm.Vector3(-_moveY, _moveX, 0) : vm.Vector3(_moveY, -_moveX, 0);
        if (rotationAxis.length == 0 || !rotationAxis.length.isFinite) return;

        final vm.Vector3 normalizedAxis = rotationAxis.normalized();
        final vm.Matrix3 frameRotation = _createRotationMatrix(normalizedAxis, rotationAmount);

        if (frameRotation == vm.Matrix3.identity() && rotationAmount > 0.001) return;

        try {
          final vm.Matrix3 newMatrix = frameRotation * _rotationMatrix;
          bool isValidMatrix = true;
          for (int i = 0; i < 9; i++) {
            if (!newMatrix.storage[i].isFinite) {
              isValidMatrix = false;
              break;
            }
          }

          if (isValidMatrix) {
            _rotationMatrix = newMatrix;
          } else {
            _rotationMatrix = vm.Matrix3.identity();
            return;
          }
        } catch (e) {
          _rotationMatrix = vm.Matrix3.identity();
          return;
        }

        _updateSpherePositions();
        _safeNotifyListeners();
      }
    } catch (e) {
      _rotationMatrix = vm.Matrix3.identity();
    }
  }

  void _updateSpherePositions() {
    if (_sphereTags.isEmpty) return;

    for (final tag in _sphereTags) {
      try {
        final vm.Vector3 rotated = _rotatePoint(tag.position3D);
        final double depth = rotated.z;
        final double x2D = rotated.x + _width / 2;
        final double y2D = rotated.y + _height / 2;

        if (!x2D.isFinite || !y2D.isFinite || !depth.isFinite) continue;

        final Offset position2D = Offset(x2D.clamp(-_width, _width * 2), y2D.clamp(-_height, _height * 2));
        tag.position2D = position2D;
        tag.depth = depth.clamp(-_sphereRadius * 2, _sphereRadius * 2);
      } catch (e) {
        continue;
      }
    }

    try {
      _sphereTags.sort((a, b) {
        if (!a.depth.isFinite || !b.depth.isFinite) return 0;
        return a.depth.compareTo(b.depth);
      });
    } catch (e) {
      // ignore
    }
  }

  // ============================================================================
  // 3D & POSITIONING
  // ============================================================================

  void _distributeTagsOnSphere() {
    try {
      _sphereTags.clear();
      if (_tags.isEmpty) return;

      final textDimensions = _estimateTextDimensions(_tags);

      for (int i = 0; i < _tags.length; i++) {
        try {
          final double y = _tags.length == 1 ? 0.0 : 1 - (i / (_tags.length - 1)) * 2;
          final double radiusAtY = math.sqrt(1 - y * y);
          final double theta = math.pi * (1 + math.sqrt(5)) * i;
          final double x = math.cos(theta) * radiusAtY;
          final double z = math.sin(theta) * radiusAtY;

          if (!x.isFinite || !y.isFinite || !z.isFinite) continue;

          final vm.Vector3 position3D = vm.Vector3(x, y, z) * _sphereRadius;
          final double depth = position3D.z;
          final double x2D = position3D.x + _width / 2;
          final double y2D = position3D.y + _height / 2;

          if (!x2D.isFinite || !y2D.isFinite || !depth.isFinite) continue;

          final Offset position2D = Offset(x2D.clamp(0.0, _width), y2D.clamp(0.0, _height));
          final double normalizedDepth = (depth + _sphereRadius) / (2 * _sphereRadius);
          final double size = 5 + (normalizedDepth * 8);
          final dimensions = textDimensions[_tags[i]] ?? const Size(50, 20);

          if (dimensions.width <= 0 || dimensions.height <= 0 || !dimensions.width.isFinite || !dimensions.height.isFinite) continue;

          _sphereTags.add(SphereTag(
            id: i,
            text: _tags[i],
            position3D: position3D,
            position2D: position2D,
            size: size,
            depth: depth,
            textWidth: dimensions.width,
            textHeight: dimensions.height,
            tagSize: _tagSize,
          ));
        } catch (e) {
          continue;
        }
      }

      try {
        _sphereTags.sort((a, b) {
          if (!a.depth.isFinite || !b.depth.isFinite) return 0;
          return a.depth.compareTo(b.depth);
        });
      } catch (e) {
        // ignore
      }

      setShowCloud(true);
    } catch (e) {
      setShowCloud(true);
    }
  }

  vm.Matrix3 _createRotationMatrix(vm.Vector3 axis, double angle) {
    if (!angle.isFinite || angle.abs() > math.pi * 2) return vm.Matrix3.identity();
    if (!axis.x.isFinite || !axis.y.isFinite || !axis.z.isFinite) return vm.Matrix3.identity();

    final double axisLength = axis.length;
    if (axisLength == 0 || !axisLength.isFinite) return vm.Matrix3.identity();

    final vm.Vector3 normalizedAxis = axis / axisLength;
    final double cos = math.cos(angle);
    final double sin = math.sin(angle);

    if (!cos.isFinite || !sin.isFinite) return vm.Matrix3.identity();

    final double oneMinusCos = 1 - cos;
    final double x = normalizedAxis.x;
    final double y = normalizedAxis.y;
    final double z = normalizedAxis.z;

    final List<double> elements = [
      cos + x * x * oneMinusCos,
      x * y * oneMinusCos - z * sin,
      x * z * oneMinusCos + y * sin,
      y * x * oneMinusCos + z * sin,
      cos + y * y * oneMinusCos,
      y * z * oneMinusCos - x * sin,
      z * x * oneMinusCos - y * sin,
      z * y * oneMinusCos + x * sin,
      cos + z * z * oneMinusCos,
    ];

    for (final element in elements) {
      if (!element.isFinite) return vm.Matrix3.identity();
    }

    return vm.Matrix3.fromList(elements);
  }

  vm.Vector3 _rotatePoint(vm.Vector3 point) {
    if (!point.x.isFinite || !point.y.isFinite || !point.z.isFinite) return point;
    try {
      final vm.Vector3 rotated = _rotationMatrix.transformed(point);
      if (!rotated.x.isFinite || !rotated.y.isFinite || !rotated.z.isFinite) return point;
      return rotated;
    } catch (e) {
      return point;
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  void setShowCloud(bool value) {
    _showCloud = value;
    _safeNotifyListeners();
  }

  Map<String, Size> _estimateTextDimensions(List<String> tags) {
    final Map<String, Size> dimensions = {};
    final double avgCharWidth = 10.5 * _tagSize / 16;
    final double lineHeight = 22.0 * _tagSize / 16;

    for (final tag in tags) {
      try {
        if (tag.isEmpty || tag.length > 50) {
          dimensions[tag] = Size(60.0 * _tagSize / 16, 35.0 * _tagSize / 16);
          continue;
        }

        double estimatedWidth = 0;
        for (int i = 0; i < tag.length; i++) {
          final char = tag[i];
          if ('ilI1'.contains(char)) {
            estimatedWidth += avgCharWidth * 0.5;
          } else if ('mwMW'.contains(char)) {
            estimatedWidth += avgCharWidth * 1.3;
          } else {
            estimatedWidth += avgCharWidth;
          }
        }

        final width = estimatedWidth + 44 * _tagSize / 16;
        final height = lineHeight + 22 * _tagSize / 16;
        final boundedWidth = width.clamp(60.0 * _tagSize / 16, 350.0 * _tagSize / 16);
        final boundedHeight = height.clamp(35.0 * _tagSize / 16, 65.0 * _tagSize / 16);

        if (boundedWidth.isFinite && boundedHeight.isFinite && boundedWidth > 0 && boundedHeight > 0) {
          dimensions[tag] = Size(boundedWidth, boundedHeight);
        } else {
          dimensions[tag] = Size(60.0 * _tagSize / 16, 35.0 * _tagSize / 16);
        }
      } catch (e) {
        dimensions[tag] = Size(60.0 * _tagSize / 16, 35.0 * _tagSize / 16);
      }
    }

    return dimensions;
  }

  void _safeNotifyListeners() {
    if (!_mounted) return;

    _notificationPending = true;
    _notificationTimer?.cancel();
    _notificationTimer = Timer(const Duration(milliseconds: 1), () {
      if (_mounted && _notificationPending) {
        _notificationPending = false;
        final phase = WidgetsBinding.instance.schedulerPhase;
        if (phase == SchedulerPhase.idle) {
          notifyListeners();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_mounted) {
              notifyListeners();
            }
          });
        }
      }
    });
  }
}
