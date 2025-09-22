import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:stacked/stacked.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class SphereTag {
  final String text;
  final vm.Vector3 position3D;
  Offset position2D;
  final double size;
  double depth;
  final double textWidth;
  final double textHeight;
  final double tagSize;
  SphereTag({
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

class CloudViewModel extends BaseViewModel {
  bool _showCloud = false;
  bool get showCloud => _showCloud;

  void setShowCloud(bool value) {
    _showCloud = value;
    _safeNotifyListeners();
  }

  late List<String> _tags;
  late double _height;
  late double _width;
  late double _topViewportOffset;
  late double _leftViewportOffset;
  late double _tagSize;
  List<String> get tags => _tags;
  double get height => _height;
  double get width => _width;
  double get topViewportOffset => _topViewportOffset;
  double get leftViewportOffset => _leftViewportOffset;
  double get tagSize => _tagSize;
  StreamSubscription<Offset?>? _mousePositionStream;

  Offset? _globalMousePosition;
  Offset? get globalMousePosition => _globalMousePosition;

  Offset? _localMousePosition;
  Offset? get localMousePosition => _localMousePosition;

  double get maxVectorLength {
    return _width / 2;
  }

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

  // 3D sphere properties
  double _sphereRadius = 100.0;
  double _rotationX = 0.0;
  double _rotationY = 0.0;

  double get sphereRadius => _sphereRadius;
  double get rotationX => _rotationX;
  double get rotationY => _rotationY;

  final List<SphereTag> _sphereTags = [];
  List<SphereTag> get sphereTags => _sphereTags;

  // Animation properties
  Timer? _animationTimer;
  double _currentRotationX = 0.0;
  double _currentRotationY = 0.0;
  double _targetRotationSpeed = 0.0;
  double _targetRotationAngle = 0.0;
  static const double _maxRotationSpeed = 2.0; // Fixed speed multiplier

  // Rotation matrix to avoid gimbal lock
  vm.Matrix3 _rotationMatrix = vm.Matrix3.identity();

  double get targetRotationSpeed => _targetRotationSpeed;
  double get targetRotationAngle => _targetRotationAngle;

  // Throttling properties
  DateTime _lastRotationUpdate = DateTime.now();
  static const Duration _rotationUpdateInterval = Duration(milliseconds: 33); // ~30fps

  // Debouncing properties for mouse updates
  Timer? _debounceTimer;
  Timer? _notificationTimer;
  static const Duration _debounceInterval = Duration(milliseconds: 16); // ~60fps

  // WASM safety
  bool _mounted = true;

  double get currentRotationX => _currentRotationX;
  double get currentRotationY => _currentRotationY;
  bool get mounted => _mounted;

  void updateMousePosition(Offset? position) {
    double globalX = position?.dx ?? 0;
    double globalY = position?.dy ?? 0;
    double localX = globalX - _leftViewportOffset - _width / 2;
    double localY = globalY - _topViewportOffset - _height / 2;
    _globalMousePosition = Offset(globalX, globalY);
    _localMousePosition = Offset(localX, localY);

    // Throttle rotation updates to 30fps
    final DateTime now = DateTime.now();
    if (now.difference(_lastRotationUpdate) >= _rotationUpdateInterval) {
      // Update rotation based on mouse position
      if (_localMousePosition != null) {
        _targetRotationAngle = vectorAngle;
        _targetRotationSpeed = vectorLengthPercentage * _maxRotationSpeed;
      } else {
        _targetRotationSpeed = 0.0;
      }
      _lastRotationUpdate = now;
    }

    // Debounce UI updates to prevent excessive rebuilds
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceInterval, () {
      if (_mounted) {
        _safeNotifyListeners();
      }
    });
  }

  // Estimate text dimensions based on character count (WASM-safe approach)
  Map<String, Size> _estimateTextDimensions(List<String> tags) {
    final Map<String, Size> dimensions = {};

    // Base font size is 16px with FontWeight.w700 (bold)
    // For bold fonts, average character width is slightly wider
    final double avgCharWidth = 10.5 * _tagSize / 16; // Adjusted for bold weight
    final double lineHeight = 22.0 * _tagSize / 16; // Approximate line height for 16px bold font

    for (final tag in tags) {
      try {
        // Skip empty or invalid tags
        if (tag.isEmpty || tag.length > 50) {
          dimensions[tag] = Size(60.0 * _tagSize / 16, 35.0 * _tagSize / 16);
          continue;
        }

        // Estimate width based on character count
        // Account for variable width characters (i, l vs m, w)
        double estimatedWidth = 0;
        for (int i = 0; i < tag.length; i++) {
          final char = tag[i];
          if ('ilI1'.contains(char)) {
            estimatedWidth += avgCharWidth * 0.5; // Narrow characters
          } else if ('mwMW'.contains(char)) {
            estimatedWidth += avgCharWidth * 1.3; // Wide characters
          } else {
            estimatedWidth += avgCharWidth; // Average characters
          }
        }

        // Add padding to dimensions
        final width = estimatedWidth + 44 * _tagSize / 16; // horizontal padding: 12 * 2 + margin
        final height = lineHeight + 22 * _tagSize / 16; // vertical padding: 6 * 2 + margin

        // Apply reasonable bounds with additional safety checks
        final boundedWidth = width.clamp(60.0 * _tagSize / 16, 350.0 * _tagSize / 16);
        final boundedHeight = height.clamp(35.0 * _tagSize / 16, 65.0 * _tagSize / 16);

        // Ensure dimensions are finite and positive
        if (boundedWidth.isFinite && boundedHeight.isFinite && boundedWidth > 0 && boundedHeight > 0) {
          dimensions[tag] = Size(boundedWidth, boundedHeight);
        } else {
          dimensions[tag] = Size(60.0 * _tagSize / 16, 35.0 * _tagSize / 16);
        }
      } catch (e) {
        // Fallback to safe default dimensions
        dimensions[tag] = Size(60.0 * _tagSize / 16, 35.0 * _tagSize / 16);
      }
    }

    return dimensions;
  }

  void _distributeTagsOnSphere() {
    try {
      _sphereTags.clear();

      // Handle edge case of empty or single tag
      if (_tags.isEmpty) return;

      // Estimate all text dimensions (WASM-safe)
      final textDimensions = _estimateTextDimensions(_tags);

      for (int i = 0; i < _tags.length; i++) {
        try {
          // Use Fibonacci spiral distribution for even spacing on sphere
          final double y = _tags.length == 1
              ? 0.0 // Center single tag
              : 1 - (i / (_tags.length - 1)) * 2; // y goes from 1 to -1
          final double radiusAtY = math.sqrt(1 - y * y);
          final double theta = math.pi * (1 + math.sqrt(5)) * i; // Golden angle

          final double x = math.cos(theta) * radiusAtY;
          final double z = math.sin(theta) * radiusAtY;

          // Safety checks for 3D position
          if (!x.isFinite || !y.isFinite || !z.isFinite) {
            continue; // Skip invalid positions
          }

          final vm.Vector3 position3D = vm.Vector3(x, y, z) * _sphereRadius;

          // Calculate initial 2D position without rotation
          final double depth = position3D.z;
          final double x2D = position3D.x + _width / 2;
          final double y2D = position3D.y + _height / 2;

          // Safety checks for 2D position
          if (!x2D.isFinite || !y2D.isFinite || !depth.isFinite) {
            continue; // Skip invalid positions
          }

          // Clamp positions to stay within widget bounds
          final double clampedX = x2D.clamp(0.0, _width);
          final double clampedY = y2D.clamp(0.0, _height);

          final Offset position2D = Offset(clampedX, clampedY);

          // Calculate size based on depth (closer = larger)
          final double normalizedDepth = (depth + _sphereRadius) / (2 * _sphereRadius);
          final double size = 5 + (normalizedDepth * 8); // Size between 12-20

          // Get pre-calculated dimensions with fallback
          final dimensions = textDimensions[_tags[i]] ?? const Size(50, 20);

          // Additional safety checks for dimensions
          if (dimensions.width <= 0 || dimensions.height <= 0 || !dimensions.width.isFinite || !dimensions.height.isFinite) {
            continue; // Skip invalid dimensions
          }

          _sphereTags.add(SphereTag(
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
          // Skip this tag if any error occurs during distribution
          print('Error distributing tag ${_tags[i]}: $e');
          continue;
        }
      }

      // Sort by depth (farthest first for proper rendering) with safety check
      try {
        _sphereTags.sort((a, b) {
          if (!a.depth.isFinite || !b.depth.isFinite) return 0;
          return a.depth.compareTo(b.depth);
        });
      } catch (e) {
        print('Error sorting sphere tags: $e');
      }

      setShowCloud(true);
    } catch (e) {
      print('Error in _distributeTagsOnSphere: $e');
      // Ensure we still show something even if distribution fails
      setShowCloud(true);
    }
  }

  vm.Matrix3 _createRotationMatrix(vm.Vector3 axis, double angle) {
    // Safety checks for WASM compatibility
    if (!angle.isFinite || angle.abs() > math.pi * 2) {
      return vm.Matrix3.identity();
    }

    // Ensure axis is normalized and finite
    if (!axis.x.isFinite || !axis.y.isFinite || !axis.z.isFinite) {
      return vm.Matrix3.identity();
    }

    final double axisLength = axis.length;
    if (axisLength == 0 || !axisLength.isFinite) {
      return vm.Matrix3.identity();
    }

    // Normalize axis safely
    final vm.Vector3 normalizedAxis = axis / axisLength;

    // Rodrigues' rotation formula with safety checks
    final double cos = math.cos(angle);
    final double sin = math.sin(angle);

    if (!cos.isFinite || !sin.isFinite) {
      return vm.Matrix3.identity();
    }

    final double oneMinusCos = 1 - cos;
    final double x = normalizedAxis.x;
    final double y = normalizedAxis.y;
    final double z = normalizedAxis.z;

    // Calculate matrix elements with finite checks
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

    // Verify all elements are finite
    for (final element in elements) {
      if (!element.isFinite) {
        return vm.Matrix3.identity();
      }
    }

    return vm.Matrix3(
      elements[0],
      elements[1],
      elements[2],
      elements[3],
      elements[4],
      elements[5],
      elements[6],
      elements[7],
      elements[8],
    );
  }

  vm.Vector3 _rotatePoint(vm.Vector3 point) {
    // Safety checks for WASM compatibility
    if (!point.x.isFinite || !point.y.isFinite || !point.z.isFinite) {
      return point;
    }

    try {
      // Use rotation matrix to avoid gimbal lock
      final vm.Vector3 rotated = _rotationMatrix.transformed(point);

      // Verify result is finite
      if (!rotated.x.isFinite || !rotated.y.isFinite || !rotated.z.isFinite) {
        return point; // Return original point if rotation fails
      }

      return rotated;
    } catch (e) {
      // Return original point if matrix transformation fails
      return point;
    }
  }

  void _updateSpherePositions() {
    // Safety check for empty tags list
    if (_sphereTags.isEmpty) return;

    for (final tag in _sphereTags) {
      try {
        final vm.Vector3 rotated = _rotatePoint(tag.position3D);
        final double depth = rotated.z;

        // Safety checks for position calculations
        final double x2D = rotated.x + _width / 2;
        final double y2D = rotated.y + _height / 2;

        // Ensure 2D position values are finite and within reasonable bounds
        if (!x2D.isFinite || !y2D.isFinite || !depth.isFinite) {
          continue; // Skip this tag if calculations produce invalid values
        }

        final Offset position2D = Offset(
          x2D.clamp(-_width, _width * 2), // Allow some overflow for smooth transitions
          y2D.clamp(-_height, _height * 2),
        );

        // Update the tag's 2D position and depth
        tag.position2D = position2D;
        tag.depth = depth.clamp(-_sphereRadius * 2, _sphereRadius * 2);
      } catch (e) {
        // Skip this tag if any error occurs during position update
        print('Error updating tag position: $e');
        continue;
      }
    }

    // Re-sort by depth with safety check
    try {
      _sphereTags.sort((a, b) {
        if (!a.depth.isFinite || !b.depth.isFinite) return 0;
        return a.depth.compareTo(b.depth);
      });
    } catch (e) {
      // If sorting fails, maintain current order
      print('Sort error: $e');
    }
  }

  void onInit({
    required List<String> tags,
    required double height,
    required double width,
    required Stream<Offset?> mousePositionStream,
    required double topViewportOffset,
    required double leftViewportOffset,
    required Color foregroundColor,
    required double tagSize,
  }) {
    _tags = tags;
    _height = height;
    _width = width;
    _topViewportOffset = topViewportOffset;
    _leftViewportOffset = leftViewportOffset;
    _tagSize = tagSize;
    // foregroundColor is passed but not stored since we don't use TextPainter anymore
    _mousePositionStream = mousePositionStream.listen(updateMousePosition);

    // We no longer need to initialize text style here since we're not using TextPainter

    // Calculate sphere radius based on container size (smaller to fit within bounds)
    _sphereRadius = math.min(height, width) * 0.37;

    // Defer initialization to ensure we're not in a build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mounted) {
        // Distribute tags on sphere
        _distributeTagsOnSphere();

        // Start animation timer
        _startAnimationTimer();
      }
    });
  }

  void _startAnimationTimer() {
    // Use a slower timer for WASM compatibility (30fps instead of 60fps)
    _animationTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      // Stop timer if widget is disposed or not mounted
      if (!_mounted) {
        timer.cancel();
        return;
      }
      _updateRotation();
    });
  }

  double _moveX = 0;
  double _moveY = 0;

  double get moveX => _moveX;
  double get moveY => _moveY;

  void _updateRotation() {
    try {
      // Additional safety checks for WASM compatibility
      if (!_mounted || _sphereTags.isEmpty) return;

      if (_targetRotationSpeed > 0 && _localMousePosition != null) {
        final double deltaTime = 1.0 / 30.0; // 30fps for WASM compatibility
        final double rotationAmount = _targetRotationSpeed * deltaTime;

        // Skip very small rotations to reduce computational load
        if (rotationAmount < 0.001) return;

        // Safety check for rotation amount
        if (!rotationAmount.isFinite || rotationAmount > 1.0) return;

        // Get movement direction components with safety checks
        final double angle = vectorAngle;
        if (!angle.isFinite) return;

        _moveX = math.cos(angle); // Right component
        _moveY = math.sin(angle); // Up component

        // Verify movement components are finite
        if (!_moveX.isFinite || !_moveY.isFinite) return;

        // For rolling ball: the rotation axis is perpendicular to movement direction
        // Movement direction: (_moveX, _moveY, 0)
        // Rotation axis: (-_moveY, _moveX, 0) - perpendicular in XY plane
        final vm.Vector3 rotationAxis = vm.Vector3(_moveY, -_moveX, 0);

        // Safety check before normalization
        if (rotationAxis.length == 0 || !rotationAxis.length.isFinite) return;

        final vm.Vector3 normalizedAxis = rotationAxis.normalized();

        // Create rotation matrix using Rodrigues' rotation formula
        final vm.Matrix3 frameRotation = _createRotationMatrix(normalizedAxis, rotationAmount);

        // Safety check: ensure we got a valid rotation matrix
        if (frameRotation == vm.Matrix3.identity() && rotationAmount > 0.001) {
          return; // Skip this frame if matrix creation failed
        }

        // Accumulate rotation by multiplying matrices (avoids gimbal lock)
        try {
          final vm.Matrix3 newMatrix = frameRotation * _rotationMatrix;

          // Verify the new matrix is valid
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
            // Reset to identity if matrix becomes invalid
            _rotationMatrix = vm.Matrix3.identity();
            return;
          }
        } catch (e) {
          // Reset to identity if matrix multiplication fails
          _rotationMatrix = vm.Matrix3.identity();
          return;
        }

        // Update sphere positions with new rotation
        _updateSpherePositions();

        // Always use safe notification to prevent render mutations
        _safeNotifyListeners();
      }
    } catch (e) {
      // Reset rotation matrix and silently handle errors to prevent WASM crashes
      _rotationMatrix = vm.Matrix3.identity();
      print('Cloud rotation error: $e');
    }
  }

  void _safeNotifyListeners() {
    if (!_mounted) {
      print('Cloud not mounted, skipping safe notify listeners');
      return;
    }

    // Always defer notification to avoid render mutations
    // This ensures we never call notifyListeners during layout/paint phases
    _notificationPending = true;

    // Cancel any existing pending notification to avoid stacking up callbacks
    _notificationTimer?.cancel();

    // Use a small delay to ensure we're in a safe state
    _notificationTimer = Timer(const Duration(milliseconds: 1), () {
      if (_mounted && _notificationPending) {
        _notificationPending = false;

        // Double-check we're in a safe state before notifying
        final phase = WidgetsBinding.instance.schedulerPhase;
        if (phase == SchedulerPhase.idle) {
          notifyListeners();
        } else {
          // If still not safe, defer to next frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_mounted) {
              notifyListeners();
            }
          });
        }
      } else {}
    });
  }

  bool _notificationPending = false;

  void onDispose() {
    _mounted = false;
    _mousePositionStream?.cancel();
    _animationTimer?.cancel();
    _debounceTimer?.cancel();
    _notificationTimer?.cancel();
  }
}
