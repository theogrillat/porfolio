import 'package:flame/extensions.dart';
import 'package:portfolio/models/about.dart';
import 'package:portfolio/services/db.dart';
import 'package:portfolio/widgets/forge.dart';
import 'package:stacked/stacked.dart';

class AboutViewModel extends BaseViewModel {
  About? _about;
  About? get about => _about;

  final ForgeController _forgeController = ForgeController();
  ForgeController get forgeController => _forgeController;

  void explode() {
    _forgeController.applyGlobalImpulse(Vector2.random() * 50000);
    _forgeController.applyGlobalAngularImpulse(10000);
  }

  void onInit() async {
    _about = await DbService().getAbout();
    notifyListeners();
  }

  void onDispose() {
    _forgeController.dispose();
  }
}
