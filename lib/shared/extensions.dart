import 'package:diacritic/diacritic.dart' as diacritic;
import 'package:flutter/material.dart';

// String extensions
extension StringExtension on String {
  String removeDiacritics() {
    return diacritic.removeDiacritics(this);
  }
}

extension ListExtension on List {
  List<Widget> addSeparator(Widget separator) {
    List<Widget> list = [];
    for (var i = 0; i < length; i++) {
      list.add(this[i]);
      if (i < length - 1) {
        list.add(separator);
      }
    }
    return list;
  }
}
