import 'package:flame/extensions.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/widgets/forge.dart';
import 'package:stacked/stacked.dart';

class ProjectViewModel extends BaseViewModel {
  late Project _project;
  Project get project => _project;

  final ForgeController _forgeController = ForgeController();
  ForgeController get forgeController => _forgeController;

  void onInit(Project prj) {
    _project = prj;

    // Listen to controller state changes
    _forgeController.addListener(_onControllerStateChanged);

    notifyListeners();
  }

  void _onControllerStateChanged() {
    // React to controller state changes if needed
    notifyListeners();
  }

  // Example methods to demonstrate controller usage
  void addRandomTags(List<String> tags) {
    for (var tag in tags) {
      _forgeController.addPhysicsComponent(tag);
    }
    explode();
  }

  void clearAllTags() {
    _forgeController.clearAllComponents();
  }

  void resetPhysics() {
    _forgeController.reset();
  }

  void explode() {
    _forgeController.applyGlobalImpulse(Vector2.random() * 50000);
    _forgeController.applyGlobalAngularImpulse(10000);
  }

  void onDispose() {
    _forgeController.removeListener(_onControllerStateChanged);
    _forgeController.dispose();
  }
}
