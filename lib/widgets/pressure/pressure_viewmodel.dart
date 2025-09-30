import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:stacked/stacked.dart';

class PressureViewModel extends BaseViewModel {
  late Stream<Offset?> _mousePositionStream;
  Stream<Offset?> get mousePositionStream => _mousePositionStream;

  StreamSubscription<Offset?>? _mousePositionStreamSubscription;
  StreamSubscription<Offset?>? get mousePositionStreamSubscription =>
      _mousePositionStreamSubscription;

  Curve _curve = Curves.easeOutQuad;

  final List<Color> _colors = [];
  List<Color> get colors => _colors;

  final List<double> _widths = [];
  List<double> get widths => _widths;

  final List<double> _amounts = [];
  List<double> get amounts => _amounts;

  final List<double> _alignemnts = [];
  List<double> get alignments => _alignemnts;

  // Smooth interpolation properties
  final List<double> _targetWidths = [];
  final List<double> _targetAmounts = [];
  late TickerProvider _tickerProvider;
  Ticker? _ticker;
  static const double _lerpSpeed = 0.15; // How fast to interpolate (0.0 to 1.0)

  double _lastMouseX = 0;
  double _baseItemWidth = 0;

  double get baseItemWidth => _baseItemWidth;
  String _text = '';
  double _leftViewportOffset = 0;
  double _totalWidth = 0;

  double getXOffset({required int index, bool includeDiff = true}) {
    List<double> previousWidths = widths.sublist(0, index);
    double centerOffset = 0;
    if (previousWidths.isNotEmpty) {
      for (double width in previousWidths) {
        double scaleFactor = width / baseItemWidth;
        double actualWidth = baseItemWidth * scaleFactor;
        centerOffset += actualWidth;
      }
    }
    double diff = includeDiff
        ? (baseItemWidth - baseItemWidth * widths[index] / baseItemWidth) / 2
        : 0;
    return centerOffset - diff;
  }

  void updateMousePosition(Offset? position) {
    if (position == null) {
      _lastMouseX = 0;
      _updateTargetWidths(null);
      return;
    }

    double dx = position.dx;
    if ((dx - _lastMouseX).abs() <= 3) return;

    _lastMouseX = dx;
    _updateTargetWidths(dx);
  }

  late double _influenceRadius;
  late double _maxInflation;

  double easingFunction(double t) {
    return _curve.transform(t);
    // Exponential decay
    // return exp(-3 * t);

    // EaseOutBack
    // const c1 = 1.70158;
    // const c3 = c1 + 1;
    // return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2);

    //
    // return t == 1 ? 1.0 : 1.0 - pow(2, -10.0 * t);
    // return 1 - (1 - t) * (1 - t);
  }

  void _updateTargetWidths(double? mouseX) {
    if (mouseX == null) {
      // Reset to base widths
      for (int i = 0; i < _text.length; i++) {
        _targetWidths[i] = _baseItemWidth;
        _targetAmounts[i] = 1.0;
      }
      return;
    }

    // const double influenceRadius = 550.0; // pixels
    // const double maxInflation = 4.0; // maximum scale factor

    List<double> scales = [];
    double totalScale = 0;

    // Calculate scale factors based on distance from mouse
    for (int i = 0; i < _text.length; i++) {
      double charCenterX = (i + 0.5) * _baseItemWidth + _leftViewportOffset;
      double distance = (mouseX - charCenterX).abs();

      double scale;
      if (distance < _influenceRadius) {
        // Use exponential decay for smooth transition
        double normalizedDistance = distance / _influenceRadius;

        double t = 1.0 - normalizedDistance;

        double easingValue = easingFunction(t);

        scale = 1.0 + (_maxInflation - 1.0) * easingValue;
      } else {
        scale = 1.0;
      }

      scales.add(scale);
      totalScale += scale;
    }

    // Normalize to maintain total width (zero sum)
    double targetTotalScale =
        _text.length.toDouble(); // Should equal sum of base scales (all 1.0)
    double normalizationFactor = targetTotalScale / totalScale;

    for (int i = 0; i < _text.length; i++) {
      _targetWidths[i] = _baseItemWidth * scales[i] * normalizationFactor;
      // _targetAmounts[i] = _targetWidths[i] / _baseItemWidth;
      _targetAmounts[i] = scales[i];
    }
  }

  void _lerpToTargets(Duration elapsed) {
    bool hasChanges = false;

    for (int i = 0; i < _text.length; i++) {
      // Smoothly interpolate current values toward target values
      double newWidth =
          _widths[i] + (_targetWidths[i] - _widths[i]) * _lerpSpeed;
      double newAmount =
          _amounts[i] + (_targetAmounts[i] - _amounts[i]) * _lerpSpeed;

      // Only update if there's a meaningful change
      if ((_widths[i] - newWidth).abs() > 0.01 ||
          (_amounts[i] - newAmount).abs() > 0.01) {
        _widths[i] = newWidth;
        _amounts[i] = newAmount;
        hasChanges = true;
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  void _startTicker() {
    _ticker?.dispose();
    _ticker = _tickerProvider.createTicker(_lerpToTargets);
    _ticker!.start();
  }

  void _stopTicker() {
    _ticker?.dispose();
    _ticker = null;
  }

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
    _text = text;
    _totalWidth = totalWidth;
    _baseItemWidth = (totalWidth - 4) / text.length;
    _leftViewportOffset = leftViewportOffset;
    _tickerProvider = tickerProvider;
    _influenceRadius = radius;
    _maxInflation = strength;
    if (curve != null) {
      _curve = curve;
    }

    // Clear existing data
    _colors.clear();
    _widths.clear();
    _amounts.clear();
    _alignemnts.clear();
    _targetWidths.clear();
    _targetAmounts.clear();

    // Initialize data for each character
    for (int i = 0; i < text.length; i++) {
      // _colors.add(Color((Random().nextDouble() * 0xFFFFFF).toInt())
          // .withValues(alpha: 1.0));
      _widths.add(_baseItemWidth);
      _amounts.add(1.0);
      _targetWidths.add(_baseItemWidth);
      _targetAmounts.add(1.0);
      _alignemnts.add(((2 / (text.length - 1)) * i) - 1);
    }

    // Start the smooth interpolation ticker
    _startTicker();

    notifyListeners();
    _mousePositionStreamSubscription =
        mousePositionStream.listen(updateMousePosition);
  }

  void updateWidth({
    required double totalWidth,
    required double leftViewportOffset,
  }) {
    if (_totalWidth == totalWidth && _leftViewportOffset == leftViewportOffset) {
      return; // No change needed
    }
    
    _totalWidth = totalWidth;
    _leftViewportOffset = leftViewportOffset;
    double newBaseItemWidth = (totalWidth - 4) / _text.length;
    
    // Update all width-related calculations proportionally
    double scaleFactor = newBaseItemWidth / _baseItemWidth;
    _baseItemWidth = newBaseItemWidth;
    
    // Update current widths proportionally
    for (int i = 0; i < _widths.length; i++) {
      _widths[i] = _widths[i] * scaleFactor;
      _targetWidths[i] = _targetWidths[i] * scaleFactor;
    }
    
    // Recalculate target widths based on current mouse position
    _updateTargetWidths(_lastMouseX == 0 ? null : _lastMouseX);
    
    notifyListeners();
  }

  void onDispose() {
    _mousePositionStreamSubscription?.cancel();
    _stopTicker();
  }
}
