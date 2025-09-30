import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:portfolio/services/tilt_service.dart';
import 'package:portfolio/shared/utils.dart';
import 'package:stacked/stacked.dart';

// ============================================================================
// PRESSURE VIEW MODEL
// ============================================================================

/// ViewModel that computes per-character width inflation based on pointer
/// proximity, with smooth interpolation driven by a Ticker.
class PressureViewModel extends BaseViewModel {
  // ============================================================================
  // CONSTANTS & CONFIG
  // ============================================================================

  static const double _lerpSpeed = 0.15; // 0.0..1.0 interpolation speed
  static const double _gutterPx = 4.0; // Horizontal total padding/gutter

  // ============================================================================
  // EXTERNAL STREAMS & SUBSCRIPTIONS
  // ============================================================================

  late Stream<Offset?> _mousePositionStream;
  Stream<Offset?> get mousePositionStream => _mousePositionStream;

  StreamSubscription<Offset?>? _mousePositionStreamSubscription;
  StreamSubscription<Offset?>? get mousePositionStreamSubscription => _mousePositionStreamSubscription;

  StreamSubscription<double?>? _tiltStreamSubscription;
  StreamSubscription<double?>? get tiltStreamSubscription => _tiltStreamSubscription;

  // ============================================================================
  // ANIMATION & EASING
  // ============================================================================

  /// Easing curve applied to the proximity influence.
  Curve _curve = Curves.easeOutQuad;

  late TickerProvider _tickerProvider;
  Ticker? _ticker;

  // ============================================================================
  // STATE: INPUT, LAYOUT, AND INTERNAL BUFFERS
  // ============================================================================

  String _text = '';
  double _totalWidth = 0;
  double _leftViewportOffset = 0;

  // Base width per character at rest (pre-inflation).
  double _baseItemWidth = 0;
  double get baseItemWidth => _baseItemWidth;

  // Pointer tracking.
  double _lastMouseX = 0;

  // Influence controls.
  late double _influenceRadius; // pixels around pointer
  late double _maxInflation; // >= 1.0 multiplier at center

  // Working data per character.
  final List<Color> _colors = []; // Kept for potential visualization/debug.
  List<Color> get colors => _colors;

  final List<double> _widths = []; // current animated widths
  List<double> get widths => _widths;

  final List<double> _amounts = []; // current scale amounts (relative)
  List<double> get amounts => _amounts;

  final List<double> _alignments = []; // normalized alignment [-1..1]
  List<double> get alignments => _alignments;

  // Targets for smooth interpolation.
  final List<double> _targetWidths = [];
  final List<double> _targetAmounts = [];

  // ============================================================================
  // PUBLIC API
  // ============================================================================

  /// Initializes the ViewModel with input text, sizing, streams, and animation
  /// providers; starts the interpolation ticker.
  void onInit({
    required String text,
    required Stream<Offset?> mousePositionStream,
    required double totalWidth,
    required double leftViewportOffset,
    required TickerProvider tickerProvider,
    required double radius,
    required double strength,
    Curve? curve,
  }) {
    assert(text.isNotEmpty, 'text must not be empty'); // sanity
    assert(radius >= 0, 'radius must be >= 0'); // sanity
    assert(strength >= 1.0, 'strength must be >= 1.0'); // sanity

    _text = text;
    _mousePositionStream = mousePositionStream;
    _totalWidth = totalWidth;
    _leftViewportOffset = leftViewportOffset;
    _tickerProvider = tickerProvider;
    _influenceRadius = radius;
    _maxInflation = strength;
    if (curve != null) _curve = curve;

    _recomputeBaseItemWidth();

    // Reset buffers.
    _colors.clear();
    _widths.clear();
    _amounts.clear();
    _alignments.clear();
    _targetWidths.clear();
    _targetAmounts.clear();

    // Seed per-character data.
    for (int i = 0; i < text.length; i++) {
      _widths.add(_baseItemWidth);
      _amounts.add(1.0);
      _targetWidths.add(_baseItemWidth);
      _targetAmounts.add(1.0);
      // Normalized alignment from -1 to 1 across the string.
      _alignments.add(text.length == 1 ? 0.0 : ((2 / (text.length - 1)) * i) - 1);
    }

    _startTicker();
    notifyListeners();

    _mousePositionStreamSubscription = _mousePositionStream.listen(updateMousePosition);
    _tiltStreamSubscription = TiltService.instance.tiltStream.listen(updateTilt);
  }

  double? _currentTilt;
  double? get currentTilt => _currentTilt;

  double? get virtualMouseX {
    if (_currentTilt == null) return null;
    double clampedTilt = _currentTilt!.clamp(-0.5, 0.5);

    double x = interpolate(
      value: clampedTilt,
      range: [-0.5, 0.5],
      outputRange: [0, _totalWidth],
    );

    return x + _leftViewportOffset;
  }

  /// Updates total width and viewport offset; keeps proportions and targets
  /// consistent with current pointer position.
  void updateWidth({
    required double totalWidth,
    required double leftViewportOffset,
  }) {
    if (_totalWidth == totalWidth && _leftViewportOffset == leftViewportOffset) {
      return;
    }

    _totalWidth = totalWidth;
    _leftViewportOffset = leftViewportOffset;

    final double oldBase = _baseItemWidth;
    _recomputeBaseItemWidth();
    final double scaleFactor = _baseItemWidth == 0 ? 1.0 : (_baseItemWidth / (oldBase == 0 ? _baseItemWidth : oldBase));

    for (int i = 0; i < _widths.length; i++) {
      _widths[i] *= scaleFactor;
      _targetWidths[i] *= scaleFactor;
    }

    _updateTargetWidths(_lastMouseX == 0 ? null : _lastMouseX);
    notifyListeners();
  }

  /// Disposes subscriptions and ticker. Must be called by the owning view.
  void onDispose() {
    _mousePositionStreamSubscription?.cancel();
    _tiltStreamSubscription?.cancel();
    _stopTicker();
  }

  /// Returns the x-offset (from the left) for the item at [index], with an
  /// option to include half-width difference adjustment to center the item.
  double getXOffset({required int index, bool includeDiff = true}) {
    double x = 0.0;
    for (int i = 0; i < index; i++) {
      x += _widths[i];
    }
    if (includeDiff) {
      final double halfDiff = (_widths[index] - _baseItemWidth) / 2.0;
      x -= halfDiff;
    }
    return x;
  }

  // ============================================================================
  // EVENT HANDLERS
  // ============================================================================

  /// Handles incoming pointer positions and updates targets when movement
  /// exceeds a small threshold to reduce churn.
  void updateMousePosition(Offset? position) {
    if (position == null) {
      _lastMouseX = 0;
      _updateTargetWidths(null);
      return;
    }

    final double dx = position.dx;
    if ((dx - _lastMouseX).abs() <= 3) return;

    _lastMouseX = dx;
    _updateTargetWidths(dx);
  }

  void updateTilt(double? tilt) {
    if (!isMobileWebBrowser) return;
    if (tilt != null) {
      // Handle tilt (-1.0 to 1.0)
      // print('Tilt: ${(tilt * 100).toStringAsFixed(1)}%');
      _currentTilt = tilt;
      notifyListeners();

      // print('Virtual mouse x: $virtualMouseX');

      _updateTargetWidths(virtualMouseX);
    } else {
      // Tilt not supported
      _currentTilt = null;
      notifyListeners();
      print('Tilt not supported');
    }
  }

  // ============================================================================
  // PRIVATE: COMPUTATIONS & HELPERS
  // ============================================================================

  /// Easing function for proximity response based on [_curve].
  double _easing(double t) {
    return _curve.transform(t);
  }

  void _recomputeBaseItemWidth() {
    _baseItemWidth = _text.isEmpty ? 0 : (_totalWidth - _gutterPx) / _text.length;
  }

  /// Computes target widths and scale amounts based on current pointer x,
  /// normalized so the total width stays constant.
  void _updateTargetWidths(double? mouseX) {
    if (_text.isEmpty) return;

    if (mouseX == null) {
      for (int i = 0; i < _text.length; i++) {
        _targetWidths[i] = _baseItemWidth;
        _targetAmounts[i] = 1.0;
      }
      return;
    }

    final List<double> scales = List<double>.filled(_text.length, 1.0);
    double totalScale = 0.0;

    for (int i = 0; i < _text.length; i++) {
      final double charCenterX = (i + 0.5) * _baseItemWidth + _leftViewportOffset;
      final double distance = (mouseX - charCenterX).abs();

      double scale = 1.0;
      if (distance < _influenceRadius && _influenceRadius > 0) {
        final double normalizedDistance = distance / _influenceRadius;
        final double t = 1.0 - normalizedDistance;
        final double easingValue = _easing(t);
        scale = 1.0 + (_maxInflation - 1.0) * easingValue;
      }

      scales[i] = scale;
      totalScale += scale;
    }

    // Zero-sum normalization to keep total width stable.
    final double targetTotalScale = _text.length.toDouble();
    final double normalizationFactor = totalScale == 0 ? 1.0 : targetTotalScale / totalScale;

    for (int i = 0; i < _text.length; i++) {
      _targetWidths[i] = _baseItemWidth * scales[i] * normalizationFactor;
      _targetAmounts[i] = scales[i];
    }
  }

  /// Ticker tick callback: lerps current values toward targets and notifies
  /// listeners when meaningful changes occur.
  void _onTick(Duration elapsed) {
    if (_text.isEmpty) return;

    bool hasChanges = false;

    for (int i = 0; i < _text.length; i++) {
      final double newWidth = _widths[i] + (_targetWidths[i] - _widths[i]) * _lerpSpeed;
      final double newAmount = _amounts[i] + (_targetAmounts[i] - _amounts[i]) * _lerpSpeed;

      if ((_widths[i] - newWidth).abs() > 0.01 || (_amounts[i] - newAmount).abs() > 0.01) {
        _widths[i] = newWidth;
        _amounts[i] = newAmount;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  // ============================================================================
  // PRIVATE: TICKER LIFECYCLE
  // ============================================================================

  void _startTicker() {
    _ticker?.dispose();
    _ticker = _tickerProvider.createTicker(_onTick);
    _ticker!.start();
  }

  void _stopTicker() {
    _ticker?.dispose();
    _ticker = null;
  }
}
