import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class GravityTags extends StatefulWidget {
  const GravityTags({
    super.key,
    required this.tags,
    required this.color,
  });
  final List<String> tags;
  final Color color;

  @override
  State<GravityTags> createState() => _GravityTagsState();
}

class _GravityTagsState extends State<GravityTags> {
  final List<TagPhysics> _tags = [];
  final List<GlobalKey> _tagKeys = [];

  // Enhanced physics parameters for energy control
  final double _gravity = 0.1;
  final double _damping = 0.7; // Boundary collision damping
  final double _collisionDamping = 0.1; // Tag-to-tag collision damping
  final double _angularDamping = 0.9; // Rotational energy loss
  final double _velocityDamping = 1; // General velocity loss over time
  final double _minVelocity = 0.1; // Minimum velocity threshold
  final double _minAngularVelocity = 0.01; // Minimum angular velocity threshold
  final double _restitution = 0.4; // Collision energy retention (0-1)

  Timer? _physicsTimer;
  Size? _containerSize;
  bool _sizesInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeTags();
    // Delay physics start to allow text measurement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureTagSizes();
      _startPhysics();
    });
  }

  @override
  void dispose() {
    _physicsTimer?.cancel();
    super.dispose();
  }

  void _initializeTags() {
    final random = Random();
    _tags.clear();
    _tagKeys.clear();

    for (int i = 0; i < widget.tags.length; i++) {
      _tagKeys.add(GlobalKey());
      _tags.add(TagPhysics(
        text: widget.tags[i],
        x: random.nextDouble() * 200 + 100,
        y: random.nextDouble() * 200 + 100,
        vx: (random.nextDouble() - 0.5) * 2,
        vy: (random.nextDouble() - 0.5) * 2,
        rotation: random.nextDouble() * 2 * pi,
        angularVelocity: (random.nextDouble() - 0.5) * 0.1,
        width: 100, // Initial guess, will be updated
        height: 50, // Initial guess, will be updated
      ));
    }
  }

  void _measureTagSizes() {
    for (int i = 0; i < _tags.length; i++) {
      final RenderBox? renderBox = _tagKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;
        _tags[i].width = size.width;
        _tags[i].height = size.height;
      }
    }
    setState(() {
      _sizesInitialized = true;
    });
  }

  void _startPhysics() {
    _physicsTimer = Timer.periodic(const Duration(milliseconds: 8), (timer) {
      if (_containerSize == null || !_sizesInitialized) return;

      for (final tag in _tags) {
        // Apply gravity
        tag.vy += _gravity;

        // Apply global energy loss over time
        tag.vx *= _velocityDamping;
        tag.vy *= _velocityDamping;
        tag.angularVelocity *= _angularDamping;

        // Stop very slow movement to prevent jitter
        if (tag.vx.abs() < _minVelocity) tag.vx = 0;
        if (tag.vy.abs() < _minVelocity) tag.vy = 0;
        if (tag.angularVelocity.abs() < _minAngularVelocity) tag.angularVelocity = 0;

        // Apply velocity
        tag.x += tag.vx;
        tag.y += tag.vy;
        tag.rotation += tag.angularVelocity;

        // Calculate rotated bounding box
        final bounds = _getRotatedBounds(tag);

        // Boundary collisions with enhanced energy loss
        if (bounds.left < 0) {
          tag.x += -bounds.left;
          tag.vx = -(tag.vx * _damping);
          tag.angularVelocity = (tag.angularVelocity + tag.vy * 0.005) * _damping;
        }
        if (bounds.right > _containerSize!.width) {
          tag.x -= bounds.right - _containerSize!.width;
          tag.vx = -(tag.vx * _damping);
          tag.angularVelocity = (tag.angularVelocity - tag.vy * 0.005) * _damping;
        }
        if (bounds.top < 0) {
          tag.y += -bounds.top;
          tag.vy = -(tag.vy * _damping);
          tag.angularVelocity = (tag.angularVelocity + tag.vx * 0.005) * _damping;
        }
        if (bounds.bottom > _containerSize!.height) {
          tag.y -= bounds.bottom - _containerSize!.height;
          tag.vy = -(tag.vy * _damping);
          tag.angularVelocity = (tag.angularVelocity - tag.vx * 0.005) * _damping;
        }

        // Tag collisions
        for (final other in _tags) {
          if (tag != other) {
            if (_checkCollision(tag, other)) {
              _resolveCollisionWithEnergyLoss(tag, other);
            }
          }
        }
      }

      if (mounted) setState(() {});
    });
  }

  Rect _getRotatedBounds(TagPhysics tag) {
    // Simplified bounding box calculation for rotated rectangle
    final halfWidth = tag.width / 2;
    final halfHeight = tag.height / 2;

    final cos = math.cos(tag.rotation).abs();
    final sin = math.sin(tag.rotation).abs();

    final rotatedWidth = halfWidth * cos + halfHeight * sin;
    final rotatedHeight = halfWidth * sin + halfHeight * cos;

    return Rect.fromCenter(
      center: Offset(tag.x, tag.y),
      width: rotatedWidth * 2,
      height: rotatedHeight * 2,
    );
  }

  bool _checkCollision(TagPhysics tag1, TagPhysics tag2) {
    final bounds1 = _getRotatedBounds(tag1);
    final bounds2 = _getRotatedBounds(tag2);
    return bounds1.overlaps(bounds2);
  }

  void _resolveCollisionWithEnergyLoss(TagPhysics tag1, TagPhysics tag2) {
    final dx = tag2.x - tag1.x;
    final dy = tag2.y - tag1.y;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance == 0) return;

    final angle = atan2(dy, dx);
    final minDistance = (tag1.width + tag1.height + tag2.width + tag2.height) / 4;
    final overlap = minDistance - distance;

    if (overlap > 0) {
      // Separate the tags
      final separationX = cos(angle) * overlap / 2;
      final separationY = sin(angle) * overlap / 2;

      tag1.x -= separationX;
      tag1.y -= separationY;
      tag2.x += separationX;
      tag2.y += separationY;

      // Calculate relative velocity
      final relativeVx = tag2.vx - tag1.vx;
      final relativeVy = tag2.vy - tag1.vy;

      // Calculate relative velocity along collision normal
      final relativeVelNormal = relativeVx * cos(angle) + relativeVy * sin(angle);

      // Don't resolve if velocities are separating
      if (relativeVelNormal > 0) return;

      // Calculate collision impulse with restitution (energy loss)
      final impulse = -(1 + _restitution) * relativeVelNormal / 2;

      // Apply impulse to velocities with additional damping
      final impulseX = impulse * cos(angle) * _collisionDamping;
      final impulseY = impulse * sin(angle) * _collisionDamping;

      tag1.vx -= impulseX;
      tag1.vy -= impulseY;
      tag2.vx += impulseX;
      tag2.vy += impulseY;

      // Add rotational effect with energy loss
      final collisionIntensity = impulse.abs();
      final rotationalDamping = 0.3; // Additional damping for rotation

      tag1.angularVelocity += collisionIntensity * 0.002 * (Random().nextDouble() - 0.5) * rotationalDamping;
      tag2.angularVelocity -= collisionIntensity * 0.002 * (Random().nextDouble() - 0.5) * rotationalDamping;

      // Apply additional energy loss after collision
      tag1.vx *= 0.95;
      tag1.vy *= 0.95;
      tag2.vx *= 0.95;
      tag2.vy *= 0.95;
    }
  }

  void _onDragUpdate(int index, DragUpdateDetails details) {
    final tag = _tags[index];
    tag.x += details.delta.dx;
    tag.y += details.delta.dy;

    // Reduce velocity transfer from dragging
    tag.vx = details.delta.dx * 0.3;
    tag.vy = details.delta.dy * 0.3;
    tag.angularVelocity += (details.delta.dx * 0.0005);

    setState(() {});
  }

  void _onDragEnd(int index, DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    // Reduce initial velocity from drag release
    _tags[index].vx = velocity.dx / 150;
    _tags[index].vy = velocity.dy / 150;
    _tags[index].angularVelocity += velocity.dx / 15000;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _containerSize ??= constraints.biggest;

        return Stack(
          children: [
            for (int i = 0; i < _tags.length; i++)
              Positioned(
                left: _tags[i].x - _tags[i].width / 2,
                top: _tags[i].y - _tags[i].height / 2,
                child: GestureDetector(
                  onPanUpdate: (details) => _onDragUpdate(i, details),
                  onPanEnd: (details) => _onDragEnd(i, details),
                  child: Transform.rotate(
                    angle: _tags[i].rotation,
                    child: Text(
                      _tags[i].text,
                      key: _tagKeys[i],
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class TagPhysics {
  String text;
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double angularVelocity;
  double width;
  double height;

  TagPhysics({
    required this.text,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.angularVelocity,
    required this.width,
    required this.height,
  });
}
