import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class TagCloud extends StatefulWidget {
  final List<String> tags;
  final double height;
  final double width;
  final double radius;
  final double speed;
  final double slower;
  final int timerMs;
  final double fontMultiplier;
  final TextStyle hoverStyle;
  final TextStyle defaultStyle;
  final Function(String tag)? onTagTap;

  const TagCloud({
    Key? key,
    required this.tags,
    this.height = 400,
    this.width = 400,
    this.radius = 150,
    this.speed = 3,
    this.slower = 0.9,
    this.timerMs = 5,
    this.fontMultiplier = 15,
    this.hoverStyle = const TextStyle(color: Color(0xFF0b2e6f)),
    this.defaultStyle = const TextStyle(color: Colors.black),
    this.onTagTap,
  }) : super(key: key);

  @override
  TagCloudState createState() => TagCloudState();
}

class TagCloudState extends State<TagCloud> with AutomaticKeepAliveClientMixin {
  List<Tag> _tags = [];
  bool _mouseOver = false;
  Offset _mousePosition = Offset.zero;
  double _lastFx = 0;
  double _lastFy = 0;
  Timer? _timer;
  bool _isInitialized = false; // State preservation flag

  // Math assets
  late double _halfHeight;
  late double _halfWidth;
  late double _speedX;
  late double _speedY;
  late double _dtr;
  late double _diameter;
  late double _hwratio;
  late double _whratio;

  // Current state
  double _sy = 0;
  double _cy = 0;
  double _sx = 0;
  double _cx = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!_isInitialized) {
      _initMaths();
      _initTags();
      _deployTags();
      _startAnimation();
      _isInitialized = true;
    }
  }

  @override
  void didUpdateWidget(TagCloud oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only update if tags actually changed
    if (oldWidget.tags != widget.tags) {
      _initTags();
      _deployTags();
    }

    // Update math if dimensions changed, but preserve positions
    if (oldWidget.height != widget.height ||
        oldWidget.width != widget.width ||
        oldWidget.radius != widget.radius ||
        oldWidget.speed != widget.speed ||
        oldWidget.slower != widget.slower ||
        oldWidget.fontMultiplier != widget.fontMultiplier) {
      _initMaths();
      // Recalculate positions with new dimensions but don't redeploy
      if (oldWidget.radius != widget.radius) {
        _deployTags();
      }
    }

    // Update timer if interval changed
    if (oldWidget.timerMs != widget.timerMs) {
      _timer?.cancel();
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initMaths() {
    _halfHeight = widget.height / 2;
    _halfWidth = widget.width / 2;
    _speedX = widget.speed / _halfWidth;
    _speedY = widget.speed / _halfHeight;
    _dtr = pi / 180;
    _diameter = widget.radius * 2;
    _hwratio = widget.height / widget.width;
    _whratio = widget.width / widget.height;

    // Only reset speeds if not initialized or if speed changed significantly
    if (!_isInitialized || (_lastFx == 0 && _lastFy == 0)) {
      _lastFx = widget.speed;
      _lastFy = widget.speed;
    }
  }

  void _initTags() {
    // Preserve existing tag states if they exist
    if (_tags.isNotEmpty && _tags.length == widget.tags.length) {
      for (int i = 0; i < widget.tags.length; i++) {
        if (i < _tags.length && _tags[i].text != widget.tags[i]) {
          _tags[i].text = widget.tags[i];
          _tags[i].isHovered = false; // Reset hover state for changed tags
        }
      }
    } else {
      _tags = widget.tags.map((text) => Tag(text: text)).toList();
    }
  }

  void _deployTags() {
    final max = _tags.length;
    if (max == 0) return;

    for (int i = 0; i < max; i++) {
      final phi = acos(-1 + (2 * (i + 1) - 1) / max);
      final theta = sqrt(max * pi) * phi;

      _tags[i].cx = widget.radius * cos(theta) * sin(phi);
      _tags[i].cy = widget.radius * sin(theta) * sin(phi);
      _tags[i].cz = widget.radius * cos(phi);

      // Initialize display properties
      final per = _diameter / (_diameter + _tags[i].cz);
      _tags[i].x = _tags[i].cx * per;
      _tags[i].y = _tags[i].cy * per;
      _tags[i].alpha = per / 2;
      _tags[i].size = widget.fontMultiplier * _tags[i].alpha;
      _tags[i].zIndex = -_tags[i].cz.round();
    }
  }

  void _startAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: widget.timerMs), (_) {
      if (mounted) {
        _updateTags();
      }
    });
  }

  void _calcRotation(double fy, double fx) {
    _sy = sin(fy * _dtr);
    _cy = cos(fy * _dtr);
    _sx = sin(fx * _dtr);
    _cx = cos(fx * _dtr);
  }

  void _updateTags() {
    if (!mounted || _tags.isEmpty) return;

    double fy;
    double fx;

    if (_mouseOver) {
      fy = widget.speed - _speedY * (_mousePosition.dy - _halfHeight);
      fx = _speedX * (_mousePosition.dx - _halfWidth) - widget.speed;
    } else {
      fy = _lastFy * widget.slower;
      fx = _lastFx * widget.slower;
    }

    if ((_lastFy - fy).abs() > 0.001 || (_lastFx - fx).abs() > 0.001) {
      _calcRotation(fy, fx);
      _lastFy = fy;
      _lastFx = fx;
    }

    if (fy.abs() > 0.01 || fx.abs() > 0.01) {
      for (int j = 0; j < _tags.length; j++) {
        final rx1 = _tags[j].cx;
        final ry1 = _tags[j].cy * _cy + _tags[j].cz * -_sy;
        final rz1 = _tags[j].cy * _sy + _tags[j].cz * _cy;

        _tags[j].cx = rx1 * _cx + rz1 * _sx;
        _tags[j].cy = ry1;
        _tags[j].cz = rx1 * -_sx + rz1 * _cx;

        final per = _diameter / (_diameter + _tags[j].cz);
        _tags[j].x = _tags[j].cx * per;
        _tags[j].y = _tags[j].cy * per;
        _tags[j].alpha = (per / 2).clamp(0.1, 1.0);
        _tags[j].size = (widget.fontMultiplier * _tags[j].alpha).clamp(8.0, 50.0);
        _tags[j].zIndex = -_tags[j].cz.round();
      }

      if (mounted) {
        setState(() {
          // Update UI
        });
      }
    }
  }

  List<Widget> _buildSortedTagWidgets() {
    if (_tags.isEmpty) return [];

    // Sort tags by zIndex for proper depth rendering
    final sortedTags = List<Tag>.from(_tags)..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return sortedTags.map((tag) {
      final left = _whratio * tag.x + _halfWidth - (tag.size * tag.text.length * 0.3);
      final top = _hwratio * tag.y + _halfHeight - (tag.size * 0.5);

      return Positioned(
        left: left.clamp(0, widget.width - (tag.size * tag.text.length * 0.6)),
        top: top.clamp(0, widget.height - tag.size),
        child: MouseRegion(
          onEnter: (_) {
            if (mounted) {
              setState(() => tag.isHovered = true);
            }
          },
          onExit: (_) {
            if (mounted) {
              setState(() => tag.isHovered = false);
            }
          },
          child: GestureDetector(
            onTap: () => widget.onTagTap?.call(tag.text),
            child: Opacity(
              opacity: tag.alpha,
              child: Text(
                tag.text,
                style: tag.isHovered ? widget.hoverStyle.copyWith(fontSize: tag.size) : widget.defaultStyle.copyWith(fontSize: tag.size),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Container(
      height: widget.height,
      width: widget.width,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: MouseRegion(
        onEnter: (_) => _mouseOver = true,
        onExit: (_) => _mouseOver = false,
        onHover: (event) {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null && mounted) {
            final localPosition = box.globalToLocal(event.position);
            _mousePosition = localPosition;
          }
        },
        child: Stack(children: _buildSortedTagWidgets()),
      ),
    );
  }
}

class Tag {
  String text;
  bool isHovered = false;
  double cx = 0;
  double cy = 0;
  double cz = 0;
  double x = 0;
  double y = 0;
  double alpha = 0;
  double size = 0;
  int zIndex = 0;

  Tag({required this.text});
}
