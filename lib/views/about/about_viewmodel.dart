import 'package:portfolio/models/about.dart';
import 'package:portfolio/services/db.dart';
import 'package:stacked/stacked.dart';

class AboutViewModel extends BaseViewModel {
  About? _about;
  About? get about => _about;

  void onInit() async {
    _about = await DbService().getAbout();
    notifyListeners();
  }

  void onDispose() {}
}
