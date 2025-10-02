import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

// ============================================================================
// MOUSE VIEWMODEL
// ============================================================================

class MouseViewModel extends BaseViewModel {
  // ============================================================================
  // PROPERTIES
  // ============================================================================

  double _x = 0;
  double get x => _x;

  double _y = 0;
  double get y => _y;

  bool isIn = false;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  void onInit() {}

  void onDispose() {}

  // ============================================================================
  // EVENT HANDLERS
  // ============================================================================

  void onEnter(PointerEnterEvent event) {
    isIn = true;
    notifyListeners();
  }

  void onExit(PointerExitEvent event) {
    isIn = false;
    notifyListeners();
  }

  void onHover(PointerHoverEvent event, Offset? hoverPosition) {
    _x = event.position.dx;
    _y = event.position.dy;
    notifyListeners();
  }
}