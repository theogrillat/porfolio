import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

class MouseViewModel extends BaseViewModel {
  double _x = 0;
  double _y = 0;

  double get x => _x;
  double get y => _y;

  bool isIn = false;

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

  void onInit() {}
  void onDispose() {}
}
