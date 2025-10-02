import 'package:portfolio/models/about.dart';
import 'package:portfolio/services/db.dart';
import 'package:stacked/stacked.dart';

// ============================================================================
// ABOUT VIEWMODEL
// ============================================================================

class AboutViewModel extends BaseViewModel {
  // ============================================================================
  // PROPERTIES
  // ============================================================================

  About? _about;
  About? get about => _about;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  void onInit() async {
    _about = await DbService().getAbout();
    notifyListeners();
  }

  void onDispose() {}
}
