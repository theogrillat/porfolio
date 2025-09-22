import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/shared/styles.dart';

// Enhanced controller class with proper lifecycle management
///
/// Usage Example:
/// ```dart
/// class MyWidget extends StatefulWidget {
///   @override
///   _MyWidgetState createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<MyWidget> {
///   final ForgeController controller = ForgeController();
///
///   @override
///   void dispose() {
///     controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         ForgeWidget(
///           tags: ['Flutter', 'Dart'],
///           color: Colors.blue,
///           controller: controller,
///           onTap: () => print('Tapped!'),
///         ),
///         ElevatedButton(
///           onPressed: () => controller.addPhysicsComponent('New Tag'),
///           child: Text('Add Component'),
///         ),
///         ElevatedButton(
///           onPressed: () => controller.applyGlobalImpulse(Vector2(100, -200)),
///           child: Text('Apply Force'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
class ForgeController extends ChangeNotifier {
  ForgeWorld? _game;
  bool _isInitialized = false;

  // Getters for state
  bool get isInitialized => _isInitialized;
  ForgeWorld? get game => _game;

  // Internal method to set the game instance
  void _attachGame(ForgeWorld game) {
    if (_game != null) {
      debugPrint('ForgeController: Replacing existing game instance');
    }
    _game = game;
    _isInitialized = true;
    notifyListeners();
  }

  // Internal method to detach the game
  void _detachGame() {
    _game = null;
    _isInitialized = false;
    notifyListeners();
  }

  // Public API methods

  /// Triggers the viewport tap callback
  void triggerViewportTap() {
    if (!_isInitialized || _game == null) {
      debugPrint('ForgeController: Cannot trigger tap - game not initialized');
      return;
    }
    _game!.onViewportTap?.call();
  }

  /// Adds a new physics text component dynamically
  void addPhysicsComponent(String text, {Vector2? position, TextStyle? textStyle}) {
    if (!_isInitialized || _game == null) {
      debugPrint('ForgeController: Cannot add component - game not initialized');
      return;
    }
    _game!.addCustomComponent(text, position: position, textStyle: textStyle);
  }

  /// Removes all physics text components
  void clearAllComponents() {
    if (!_isInitialized || _game == null) {
      debugPrint('ForgeController: Cannot clear components - game not initialized');
      return;
    }
    _game!.clearAllPhysicsComponents();
  }

  /// Applies an impulse to all physics components
  void applyGlobalImpulse(Vector2 impulse) {
    if (!_isInitialized || _game == null) {
      debugPrint('ForgeController: Cannot apply impulse - game not initialized');
      return;
    }
    _game!.applyGlobalImpulse(impulse);
  }

  void applyGlobalAngularImpulse(double impulse) {
    if (!_isInitialized || _game == null) {
      debugPrint('ForgeController: Cannot apply angular impulse - game not initialized');
      return;
    }
    _game!.applyGlobalAngularImpulse(impulse);
  }

  /// Gets the count of current physics components
  int getComponentCount() {
    if (!_isInitialized || _game == null) {
      return 0;
    }
    return _game!.getPhysicsComponentCount();
  }

  /// Pauses/resumes the game
  void setPaused(bool paused) {
    if (!_isInitialized || _game == null) {
      debugPrint('ForgeController: Cannot set pause state - game not initialized');
      return;
    }
    _game!.paused = paused;
  }

  /// Sets gravity for the physics world
  void setGravity(Vector2 gravity) {
    if (!_isInitialized || _game == null) {
      debugPrint('ForgeController: Cannot set gravity - game not initialized');
      return;
    }
    _game!.world.gravity = gravity;
  }

  /// Resets the game to initial state
  void reset() {
    if (!_isInitialized || _game == null) {
      debugPrint('ForgeController: Cannot reset - game not initialized');
      return;
    }
    _game!.resetGame();
  }

  @override
  void dispose() {
    _detachGame();
    super.dispose();
  }
}

class ForgeWidget extends StatefulWidget {
  const ForgeWidget({
    required this.tags,
    required this.color,
    this.onTap,
    this.controller,
    this.fontSize = 35,
    super.key,
  });

  final List<String> tags;
  final Color color;
  final VoidCallback? onTap;
  final ForgeController? controller;
  final double fontSize;
  @override
  State<ForgeWidget> createState() => _ForgeWidgetState();
}

class _ForgeWidgetState extends State<ForgeWidget> {
  late ForgeWorld game;

  @override
  void initState() {
    super.initState();
    game = ForgeWorld(
      tags: widget.tags,
      color: widget.color,
      onViewportTap: widget.onTap,
      fontSize: widget.fontSize / 10,
    );

    // Attach the game to the controller after creation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller?._attachGame(game);
    });
  }

  @override
  void dispose() {
    // Detach the game from the controller
    widget.controller?._detachGame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRect(
        child: GameWidget<ForgeWorld>.controlled(
          gameFactory: () => game,
          addRepaintBoundary: false,
        ),
      ),
    );
  }
}

class ForgeWorld extends Forge2DGame {
  final List<String> tags;
  final Color color;
  final VoidCallback? onViewportTap;
  List<Component> boundaries = [];
  final double fontSize;
  // Black hole properties
  double blackHoleStrength = 0.0; // Gravitational strength
  Vector2? blackHoleCenter; // Center of the black hole

  ForgeWorld({
    required this.tags,
    required this.color,
    this.onViewportTap,
    required this.fontSize,
  });

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Disable standard gravity for black hole effect
    world.gravity = Vector2.zero();

    // Enable debug rendering for physics bodies
    world.debugMode = false;

    // Add unified text-physics components
    for (var tag in tags) {
      // Random position within visible bounds:
      final visibleRect = camera.visibleWorldRect;
      final position = Vector2(
        visibleRect.left + (visibleRect.width * (0.1 + Vector2.random().x * 0.8)),
        visibleRect.top + (visibleRect.height * (0.1 + Vector2.random().y * 0.8)),
      );

      // Create unified text-physics component
      world.add(
        PhysicsTextComponent(
          text: tag,
          position: position,
          textStyle: Typos().large(color: color).copyWith(fontWeight: FontWeight.w700, fontSize: fontSize),
        ),
      );
    }

    // Create boundaries that match the exact widget dimensions
    _createBoundaries();

    // Debug: print boundary positions
    // print('Game size: $size');
    // print('Camera visible rect: ${camera.visibleWorldRect}');
    // print('Black hole center: $blackHoleCenter');
  }

  void _createBoundaries() {
    // Remove existing boundaries
    for (final boundary in boundaries) {
      world.remove(boundary);
    }
    boundaries.clear();

    // Create new boundaries
    boundaries = createBoundaries(this);
    world.addAll(boundaries);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Recreate boundaries when the game resizes
    _createBoundaries();
  }

  void addCustomComponent(String text, {Vector2? position, TextStyle? textStyle}) {
    final componentPosition = position ??
        (() {
          final visibleRect = camera.visibleWorldRect;
          return Vector2(
            visibleRect.left + (visibleRect.width * (0.1 + Vector2.random().x * 0.8)),
            visibleRect.top + (visibleRect.height * (0.1 + Vector2.random().y * 0.8)),
          );
        })();
    final style = textStyle ?? Typos().large(color: color).copyWith(fontWeight: FontWeight.w700, fontSize: fontSize);

    world.add(
      PhysicsTextComponent(
        text: text,
        position: componentPosition,
        textStyle: style,
      ),
    );
  }

  /// Removes all physics text components from the world
  void clearAllPhysicsComponents() {
    final physicsComponents = world.children.whereType<PhysicsTextComponent>().toList();
    for (final component in physicsComponents) {
      world.remove(component);
    }
  }

  /// Applies an impulse to all physics text components
  void applyGlobalImpulse(Vector2 impulse) {
    final physicsComponents = world.children.whereType<PhysicsTextComponent>();
    for (final component in physicsComponents) {
      try {
        component.body.applyLinearImpulse(impulse);
      } catch (e) {
        debugPrint('Error applying global impulse to component: $e');
      }
    }
  }

  void applyGlobalAngularImpulse(double impulse) {
    final physicsComponents = world.children.whereType<PhysicsTextComponent>();
    for (final component in physicsComponents) {
      try {
        component.body.applyAngularImpulse(impulse);
      } catch (e) {
        debugPrint('Error applying global angular impulse to component: $e');
      }
    }
  }

  /// Gets the count of physics text components
  int getPhysicsComponentCount() {
    return world.children.whereType<PhysicsTextComponent>().length;
  }

  /// Resets the game to its initial state
  void resetGame() {
    // Clear all existing physics components
    clearAllPhysicsComponents();

    // Re-add original tags
    for (var tag in tags) {
      // Random position within visible bounds:
      final visibleRect = camera.visibleWorldRect;
      final position = Vector2(
        visibleRect.left + (visibleRect.width * (0.1 + Vector2.random().x * 0.8)),
        visibleRect.top + (visibleRect.height * (0.1 + Vector2.random().y * 0.8)),
      );
      world.add(
        PhysicsTextComponent(
          text: tag,
          position: position,
          textStyle: Typos().large(color: color).copyWith(fontWeight: FontWeight.w700, fontSize: fontSize),
        ),
      );
    }

    // Reset world gravity
    world.gravity = Vector2(0, 150.0);
  }
}

List<Component> createBoundaries(Forge2DGame game) {
  // Use the camera's visible world rect to get the actual widget boundaries
  final visibleRect = game.camera.visibleWorldRect;
  final left = visibleRect.left;
  final right = visibleRect.right;
  final top = visibleRect.top;
  final bottom = visibleRect.bottom;

  print('Creating boundaries from visible rect: left=$left, right=$right, top=$top, bottom=$bottom');
  print('Visible rect size: ${visibleRect.width} x ${visibleRect.height}');

  return [
    Wall(Vector2(left, top), Vector2(right, top)), // Top wall
    Wall(Vector2(right, top), Vector2(right, bottom)), // Right wall
    Wall(Vector2(right, bottom), Vector2(left, bottom)), // Bottom wall
    Wall(Vector2(left, bottom), Vector2(left, top)), // Left wall
  ];
}

class Wall extends BodyComponent {
  final Vector2 start;
  final Vector2 end;

  Wall(this.start, this.end);

  @override
  Body createBody() {
    final shape = EdgeShape()..set(start, end);
    final fixtureDef = FixtureDef(shape, friction: 0);
    final bodyDef = BodyDef(position: Vector2.zero(), type: BodyType.static);

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {}
}

// Unified component that handles both text rendering and physics
class PhysicsTextComponent extends BodyComponent with TapCallbacks {
  final String text;
  final double impulseStrength;
  final bool useRandomImpulse;
  final TextStyle textStyle;
  late TextComponent textComponent;

  PhysicsTextComponent({
    required this.text,
    required Vector2 position,
    this.impulseStrength = 300000.0,
    this.useRandomImpulse = false,
    required this.textStyle,
    Vector2? size,
  }) : super(
          renderBody: false,
          bodyDef: BodyDef()
            ..position = position
            ..type = BodyType.dynamic
            ..angularDamping = 0.04
            ..linearDamping = 0.01,
          fixtureDefs: [
            FixtureDef(
              PolygonShape()
                ..setAsBoxXY(
                  (size?.x ?? text.length * 2) / 2,
                  1.35,
                ),
              density: 0.02,
              friction: 0.01,
              restitution: 0.8,
            ),
          ],
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Create and add the text component as a child
    textComponent = TextComponent(
      text: text,
      textRenderer: TextPaint(
        style: textStyle,
      ),
      anchor: Anchor.center,
      position: Vector2.zero(), // Relative to the physics body
    );

    add(textComponent);
    await Future.delayed(const Duration(milliseconds: 10));
    customTrigger();
  }

  void customTrigger() {
    try {
      body.applyLinearImpulse(Vector2.random() * impulseStrength);
      body.applyAngularImpulse((Vector2.random().x - 0.5) * 1000);
    } catch (e) {
      print('Error applying impulse to $text: $e');
    }
  }

  @override
  bool onTapDown(TapDownEvent event) {
    print('Tap detected on unified component: $text');
    Vector2 impulse;

    if (useRandomImpulse) {
      impulse = Vector2.random() * impulseStrength;
    } else {
      final tapPosition = event.localPosition;
      final bodyCenter = Vector2.zero();
      final direction = (bodyCenter - tapPosition).normalized();
      impulse = direction * impulseStrength;
    }

    try {
      body.applyLinearImpulse(impulse);
      body.applyAngularImpulse((Vector2.random().x - 0.5) * 1000);
      print('Applied impulse to $text: $impulse');
    } catch (e) {
      print('Error applying impulse to $text: $e');
    }

    return true;
  }
}
