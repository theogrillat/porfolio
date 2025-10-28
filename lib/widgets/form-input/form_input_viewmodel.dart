import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

class FormInputViewModel extends BaseViewModel {
  bool _isFocused = false;
  bool get isFocused => _isFocused;

  final FocusNode _focusNode = FocusNode();
  FocusNode get focusNode => _focusNode;

  BuildContext? _context;

  void onInit() {
    _focusNode.addListener(() {
      if (_focusNode.hasFocus != _isFocused) {
        _isFocused = _focusNode.hasFocus;
        notifyListeners();

        // When focused, ensure the field is visible (scroll into view)
        if (_isFocused && _context != null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_context != null && _focusNode.hasFocus) {
              Scrollable.ensureVisible(
                _context!,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: 0.5, // Center the field in the viewport
              );
            }
          });
        }
      }
    });
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  void onDispose() {
    _focusNode.dispose();
    _context = null;
  }
}
