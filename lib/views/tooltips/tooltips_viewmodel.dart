import 'dart:async';

import 'package:flutter/material.dart';
import 'package:portfolio/shared/coords.dart';
import 'package:portfolio/views/home/home_viewmodel.dart';
import 'package:stacked/stacked.dart';

class TooltipsViewModel extends BaseViewModel {
  BuildContext? _ctx;

  late double _boxSize;

  String? _tooltip;
  String? get tooltip => _tooltip;

  void onTooltip(String? tooltip) {
    _tooltip = tooltip;
    notifyListeners();
  }

  Offset? _cursorPosition;
  Offset? get cursorPosition => _cursorPosition;

  StreamSubscription<Offset?>? _cursorPositionSubscription;

  void onCursorPosition(Offset? position) {
    _cursorPosition = position;
    String? tltp = getTooltip(_ctx!, NavigationState.project, _boxSize, position);
    print('tltp: $tltp');
    onTooltip(tltp);
    notifyListeners();
  }

  String? getTooltip(BuildContext context, NavigationState navState, double boxSize, Offset? cursorPosition) {
    print('getTooltip');
    if (cursorPosition == null) return null;
    if (navState == NavigationState.project) {
      if (ProjectItems(context).description.position.postition.contains(
            context: context,
            boxSize: boxSize,
            positionToCheck: cursorPosition,
          )) {
        return '<> agrandir';
      }
    }
    return null;
  }

  void onInit({
    required Stream<Offset?> cursorPositionStream,
    required BuildContext context,
    required double boxSize,
  }) {
    _cursorPositionSubscription = cursorPositionStream.listen(onCursorPosition);
    _ctx = context;
    _boxSize = boxSize;
    notifyListeners();
  }

  void onDispose() {
    _cursorPositionSubscription?.cancel();
  }
}
