import 'package:diacritic/diacritic.dart' as diacritic;

// String extensions
extension StringExtension on String {
  String removeDiacritics() {
    return diacritic.removeDiacritics(this);
  }
}
