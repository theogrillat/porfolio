import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Track screen views
  Future<void> logScreen(AppScreen screenType, {String? screenInstance, AppScreen? from, String? fromInstance}) async {
    await _analytics.logScreenView(
      screenName: screenType.toString(),
      parameters: {
        'screen_instance': screenInstance ?? '',
        'from': from?.toString() ?? '',
        'from_instance': fromInstance ?? '',
      },
    );
  }

  // Track custom events
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  // Pre-defined events for your portfolio
  Future<void> logTagClicked(String tagName, TagType tagType) async {
    await _analytics.logEvent(
      name: 'tag_clicked',
      parameters: {
        'tagName': tagName,
        'tagType': tagType.toString(),
      },
    );
  }

  Future<void> logContactFormSubmit(bool success, {String? message}) async {
    await _analytics.logEvent(
      name: 'contact_form_submitted',
      parameters: {
        'success': success,
        'message': message ?? '',
      },
    );
  }

  Future<void> logExternalLink(String linkName, String destination) async {
    await _analytics.logEvent(
      name: 'external_link_clicked',
      parameters: {
        'link_name': linkName,
        'destination': destination,
      },
    );
  }

  Future<void> logResumeDownload() async {
    await _analytics.logEvent(name: 'resume_downloaded');
  }
}

enum TagType {
  filter,
  category,
}

enum AppScreen {
  home,
  profile,
  skills,
  projects,
  screenshot,
  contact,
}
