import 'package:portfolio/models/about.dart';
import 'package:portfolio/services/analytics.dart';
import 'package:portfolio/services/db.dart';
import 'package:stacked/stacked.dart';

// ============================================================================
// ABOUT VIEWMODEL
// ============================================================================

class AboutViewModel extends BaseViewModel {
  // ============================================================================
  // SERVICES
  // ============================================================================

  final AnalyticsService _anal = AnalyticsService.instance;

  // ============================================================================
  // PROPERTIES
  // ============================================================================

  About? _about;
  About? get about => _about;

  // ============================================================================
  // ITEM EXPANSION
  // ============================================================================

  bool _bioExpanded = false;
  bool get bioExpanded => _bioExpanded;

  void toggleBio() {
    _bioExpanded = !_bioExpanded;
    notifyListeners();
    _anal.logEvent(
      name: 'about_bio_expanded',
      parameters: {
        'expanded': bioExpanded,
      },
    );
  }

  bool _skillsExpanded = false;
  bool get skillsExpanded => _skillsExpanded;

  void toggleSkills() {
    _skillsExpanded = !_skillsExpanded;
    notifyListeners();
    _anal.logEvent(
      name: 'about_skills_expanded',
      parameters: {
        'expanded': skillsExpanded,
      },
    );
  }

  bool get anyExpanded => _bioExpanded || _skillsExpanded;
  bool get noExpanded => !anyExpanded;

  void closeAll() {
    _bioExpanded = false;
    _skillsExpanded = false;
    notifyListeners();
    _anal.logEvent(
      name: 'about_close_all',
      parameters: {
        'expanded': noExpanded,
      },
    );
  }

  // ============================================================================
  // EVENT HANDLERS
  // ============================================================================

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  void onInit() async {
    _about = await DbService().getAbout();
    notifyListeners();
  }

  void onDispose() {}
}
