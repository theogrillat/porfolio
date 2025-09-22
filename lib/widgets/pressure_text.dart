import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:async';

class TextPressure extends StatefulWidget {
  final String text;
  final String fontFamily;
  final String? fontUrl;
  final bool width;
  final bool weight;
  final bool italic;
  final bool alpha;
  final bool flex;
  final bool stroke;
  final bool scale;
  final Color textColor;
  final Color strokeColor;
  final double minFontSize;
  final Size? boxSize;
  final Stream<Offset?> mousePositionStream;

  const TextPressure({
    super.key,
    this.text = 'Compressa',
    this.fontFamily = 'Compressa VF',
    this.fontUrl,
    this.width = true,
    this.weight = true,
    this.italic = true,
    this.alpha = false,
    this.flex = true,
    this.stroke = false,
    this.scale = false,
    this.textColor = Colors.white,
    this.strokeColor = Colors.red,
    this.minFontSize = 3,
    this.boxSize,
    required this.mousePositionStream,
  });

  @override
  State<TextPressure> createState() => _TextPressureState();
}

class _TextPressureState extends State<TextPressure> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<String> _chars;
  late List<GlobalKey> _charKeys;

  Offset _mousePosition = Offset.zero;
  Offset _targetMousePosition = Offset.zero;
  StreamSubscription<Offset?>? _mouseStreamSubscription;

  double _fontSize = 24;
  double _scaleY = 1.0;
  double _offsetY = 0;

  bool _fontLoaded = false;
  String _effectiveFontFamily = 'Arial';

  final GlobalKey _containerKey = GlobalKey();
  final GlobalKey _titleKey = GlobalKey();

  // Performance optimization caches
  List<Rect>? _cachedCharBounds;
  Rect? _cachedContainerBounds;
  int _boundsUpdateCounter = 0;
  static const int BOUNDS_UPDATE_INTERVAL = 2; // Update bounds every 2 frames (~60fps for smooth positioning)

  // Character style cache to prevent recalculation
  List<Map<String, dynamic>>? _cachedStyles;
  int _styleUpdateCounter = 0;
  static const int STYLE_UPDATE_INTERVAL = 1; // Update styles every frame (120fps for smooth effects)

  // Error tracking for stability
  int _errorCount = 0;
  static const int MAX_ERRORS = 10;

  // Safety throttling when system is under pressure
  bool _isThrottled = false;
  int _framesSinceLastCheck = 0;

  @override
  void initState() {
    super.initState();

    try {
      _chars = widget.text.split('');
      _charKeys = List.generate(_chars.length, (index) => GlobalKey());

      // 120fps = ~8.33ms intervals
      _animationController = AnimationController(
        duration: Duration(milliseconds: 8), // 120fps
        vsync: this,
      )..repeat();

      _animationController.addListener(_animateMouseFollow);

      // Initialize caches
      _cachedStyles = List.generate(
          _chars.length,
          (index) => {
                'fontWeight': FontWeight.w400,
                'fontVariations': <FontVariation>[],
                'opacity': 1.0,
              });

      _loadFontFromUrl();

      // Listen to mouse position stream
      _mouseStreamSubscription = widget.mousePositionStream.listen((Offset? position) {
        if (mounted) {
          setState(() {
            if (position != null) {
              // Only use dx value, ignore dy
              _targetMousePosition = Offset(position.dx, 0);
            } else {
              // Reset to center when cursor is outside viewport
              _targetMousePosition = Offset.zero;
            }
          });
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _calculateSize();
          if (widget.boxSize != null) {
            _calculateVerticalOffsetOfText(widget.boxSize!);
          }
          setState(() {});
        }
      });
    } catch (e) {
      _handleError('initState', e);
    }
  }

  @override
  void didUpdateWidget(TextPressure oldWidget) {
    super.didUpdateWidget(oldWidget);

    try {
      // Update character arrays if text changed
      if (widget.text != oldWidget.text) {
        _chars = widget.text.split('');
        _charKeys = List.generate(_chars.length, (index) => GlobalKey());
        _invalidateCaches();
      }

      // Recalculate size if boxSize changed
      if (widget.boxSize != oldWidget.boxSize) {
        setState(() {
          _showWidget = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _calculateSize();
            Future.delayed(Duration(milliseconds: 50), () {
              if (mounted && widget.boxSize != null) {
                _calculateVerticalOffsetOfText(widget.boxSize!);
                setState(() {
                  _showWidget = true;
                });
              }
            });
          }
        });
      }
    } catch (e) {
      _handleError('didUpdateWidget', e);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mouseStreamSubscription?.cancel();
    super.dispose();
  }

  void _handleError(String context, dynamic error) {
    _errorCount++;
    print('TextPressure error in $context: $error');

    if (_errorCount > MAX_ERRORS) {
      print('Too many errors, disabling complex animations');
      _animationController.stop();
    }
  }

  void _invalidateCaches() {
    _cachedCharBounds = null;
    _cachedContainerBounds = null;
    _cachedStyles = List.generate(
        _chars.length,
        (index) => {
              'fontWeight': FontWeight.w400,
              'fontVariations': <FontVariation>[],
              'opacity': 1.0,
            });
  }

  Future<void> _loadFontFromUrl() async {
    if (widget.fontUrl == null || widget.fontUrl!.isEmpty) {
      setState(() {
        _effectiveFontFamily = widget.fontFamily;
        _fontLoaded = true;
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse(widget.fontUrl!)).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final fontLoader = FontLoader(widget.fontFamily);
        fontLoader.addFont(Future.value(ByteData.sublistView(response.bodyBytes)));

        await fontLoader.load();

        if (mounted) {
          setState(() {
            _effectiveFontFamily = widget.fontFamily;
            _fontLoaded = true;
          });
        }
      } else {
        throw Exception('Failed to download font: ${response.statusCode}');
      }
    } catch (e) {
      _handleError('font loading', e);
      if (mounted) {
        setState(() {
          _effectiveFontFamily = 'Arial';
          _fontLoaded = true;
        });
      }
    }
  }

  void _calculateSize() {
    if (!mounted || _chars.isEmpty) return;

    try {
      Size containerSize;
      if (widget.boxSize != null) {
        containerSize = widget.boxSize!;
      } else {
        final containerRenderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
        if (containerRenderBox == null || !containerRenderBox.hasSize) return;
        containerSize = containerRenderBox.size;
      }

      if (containerSize.width <= 0 || containerSize.height <= 0 || !containerSize.width.isFinite || !containerSize.height.isFinite) {
        return;
      }

      double widthBasedFontSize = containerSize.width / math.max(_chars.length / 2, 1);
      double heightBasedFontSize = containerSize.height * 0.8;

      double newFontSize = math.min(widthBasedFontSize, heightBasedFontSize);

      if (newFontSize < widget.minFontSize && containerSize.height > 20) {
        newFontSize = widget.minFontSize;
      }

      // Apply safety bounds
      newFontSize = newFontSize.clamp(8.0, 500.0);
      if (!newFontSize.isFinite) newFontSize = 24.0;

      if (mounted) {
        setState(() {
          _fontSize = newFontSize;
          _scaleY = 1.0;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Future.delayed(Duration(milliseconds: 50), () {
              if (mounted) {
                _calculateVerticalScale(containerSize);
                _calculateVerticalOffsetOfText(containerSize);
                setState(() {
                  _showWidget = true;
                });
              }
            });
          }
        });
      }
    } catch (e) {
      _handleError('calculateSize', e);
    }
  }

  void _calculateVerticalScale(Size containerSize) {
    if (!mounted) return;

    try {
      final titleRenderBox = _titleKey.currentContext?.findRenderObject() as RenderBox?;
      if (titleRenderBox == null || !titleRenderBox.hasSize) return;

      final titleSize = titleRenderBox.size;

      if (titleSize.height > 0 && containerSize.height > 0 && titleSize.height.isFinite && containerSize.height.isFinite) {
        final yRatio = containerSize.height / titleSize.height;
        final adjustedYRatio = (yRatio * 0.85).clamp(0.1, 5.0);

        if (mounted && adjustedYRatio.isFinite && adjustedYRatio > 0) {
          setState(() {
            _scaleY = adjustedYRatio;
          });
        }
      }
    } catch (e) {
      _handleError('calculateVerticalScale', e);
    }
  }

  void _calculateVerticalOffsetOfText(Size containerSize) {
    if (!mounted) return;

    try {
      final titleRenderBox = _titleKey.currentContext?.findRenderObject() as RenderBox?;
      if (titleRenderBox == null || !titleRenderBox.hasSize) return;

      final titleSize = titleRenderBox.size;

      if (titleSize.height > 0 && titleSize.height.isFinite) {
        final offsetY = (titleSize.height * 0.065).clamp(0, containerSize.height / 2).toDouble();

        if (mounted && offsetY.isFinite) {
          setState(() {
            _offsetY = offsetY;
          });
        }
      }
    } catch (e) {
      _handleError('calculateVerticalOffsetOfText', e);
    }
  }

  void _animateMouseFollow() {
    if (!mounted || _errorCount > MAX_ERRORS) return;

    try {
      // Check for system pressure every 60 frames (0.5 seconds)
      _framesSinceLastCheck++;
      if (_framesSinceLastCheck >= 60) {
        _framesSinceLastCheck = 0;
      }

      // Always update mouse position smoothly at 120fps
      setState(() {
        _mousePosition = Offset(
          _mousePosition.dx + (_targetMousePosition.dx - _mousePosition.dx) / 15,
          0, // Always keep y at 0 since we only care about x position
        );
      });

      // Throttle expensive calculations when under pressure
      final boundsInterval = _isThrottled ? BOUNDS_UPDATE_INTERVAL * 3 : BOUNDS_UPDATE_INTERVAL;
      final styleInterval = _isThrottled ? STYLE_UPDATE_INTERVAL * 2 : STYLE_UPDATE_INTERVAL;

      _boundsUpdateCounter++;
      _styleUpdateCounter++;

      if (_boundsUpdateCounter >= boundsInterval) {
        _boundsUpdateCounter = 0;
        _updateCharacterBounds();
      }

      if (_styleUpdateCounter >= styleInterval && !_isThrottled) {
        _styleUpdateCounter = 0;
        _updateCharacterStyles();
      }
    } catch (e) {
      _handleError('animateMouseFollow', e);
    }
  }

  void _updateCharacterBounds() {
    if (!mounted) return;

    try {
      final containerRenderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
      if (containerRenderBox == null || !containerRenderBox.hasSize) return;

      // Update container bounds
      _cachedContainerBounds = Rect.fromLTWH(0, 0, containerRenderBox.size.width, containerRenderBox.size.height);

      // Initialize bounds list if needed
      _cachedCharBounds ??= List.filled(_charKeys.length, Rect.zero);

      // Only update bounds for characters that actually exist and have render boxes
      for (int i = 0; i < _charKeys.length; i++) {
        final charRenderBox = _charKeys[i].currentContext?.findRenderObject() as RenderBox?;
        if (charRenderBox != null && charRenderBox.hasSize) {
          final charPosition = charRenderBox.localToGlobal(Offset.zero);
          final charSize = charRenderBox.size;

          // Store center position for distance calculations
          if (i < _cachedCharBounds!.length) {
            _cachedCharBounds![i] = Rect.fromLTWH(
              charPosition.dx + charSize.width / 2,
              charPosition.dy + charSize.height / 2,
              charSize.width,
              charSize.height,
            );
          }
        } else if (i < _cachedCharBounds!.length) {
          _cachedCharBounds![i] = Rect.zero;
        }
      }
    } catch (e) {
      _handleError('updateCharacterBounds', e);
    }
  }

  void _updateCharacterStyles() {
    if (!mounted) return;

    try {
      // Get fresh container position for accurate mouse tracking
      final containerRenderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
      if (containerRenderBox == null || !containerRenderBox.hasSize) return;

      final containerPosition = containerRenderBox.localToGlobal(Offset.zero);
      // Mouse position from stream is already in global coordinates
      final localMousePosition = Offset(
        _mousePosition.dx,
        containerPosition.dy + containerRenderBox.size.height / 2, // Use container's center y position
      );

      // Use cached bounds if available, otherwise get fresh bounds
      final maxDistance =
          _cachedContainerBounds != null ? math.max(_cachedContainerBounds!.width / 2, 1.0) : math.max(containerRenderBox.size.width / 2, 1.0);

      for (int i = 0; i < _chars.length; i++) {
        Offset charCenter;

        // Use cached bounds if available and recent, otherwise calculate fresh
        if (_cachedCharBounds != null && i < _cachedCharBounds!.length && _cachedCharBounds![i] != Rect.zero) {
          final charBounds = _cachedCharBounds![i];
          charCenter = Offset(charBounds.left, charBounds.top);
        } else {
          // Fallback to real-time bounds for smooth interaction
          final charRenderBox = _charKeys[i].currentContext?.findRenderObject() as RenderBox?;
          if (charRenderBox == null || !charRenderBox.hasSize) continue;

          final charPosition = charRenderBox.localToGlobal(Offset.zero);
          final charSize = charRenderBox.size;
          charCenter = Offset(
            charPosition.dx + charSize.width / 2,
            charPosition.dy + charSize.height / 2,
          );
        }

        final distance = _calculateDistance(localMousePosition, charCenter);

        double _getAttribute(double distance, double minVal, double maxVal) {
          if (maxDistance <= 0 || !distance.isFinite || !maxDistance.isFinite) return minVal;
          final val = maxVal - math.min(maxVal, (maxVal * distance) / maxDistance);
          final result = math.max(minVal, val + minVal);
          return result.isFinite ? result : minVal;
        }

        double wdth = widget.width ? _getAttribute(distance, 5, 200).clamp(1, 1000) : 100;
        double wght = widget.weight ? _getAttribute(distance, 200, 900).clamp(100, 1000) : 400;
        double ital = widget.italic ? _getAttribute(distance, 0, 1).clamp(0, 1) : 0;
        double opacity = widget.alpha ? _getAttribute(distance, 0.6, 1).clamp(0, 1) : 1.0;

        // Safety checks
        if (!wdth.isFinite) wdth = 100;
        if (!wght.isFinite) wght = 400;
        if (!ital.isFinite) ital = 0;
        if (!opacity.isFinite) opacity = 1.0;

        List<FontVariation> variations = [];
        if (widget.weight && wght.isFinite) variations.add(FontVariation('wght', wght));
        if (widget.width && wdth.isFinite) variations.add(FontVariation('wdth', wdth));
        if (widget.italic && ital.isFinite) variations.add(FontVariation('ital', ital));

        int weightIndex = ((wght - 100) / 100).clamp(0, 8).round();
        weightIndex = math.min(weightIndex, FontWeight.values.length - 1);

        _cachedStyles![i] = {
          'fontWeight': FontWeight.values[weightIndex],
          'fontVariations': variations,
          'opacity': opacity,
        };
      }
    } catch (e) {
      _handleError('updateCharacterStyles', e);
    }
  }

  double _calculateDistance(Offset point1, Offset point2) {
    try {
      // Only calculate distance based on x-axis (dx)
      final dx = point2.dx - point1.dx;
      final distance = dx.abs();
      return distance.isFinite ? distance : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Map<String, dynamic> _getCharacterStyle(int index) {
    // Use cached styles or return safe defaults
    if (_cachedStyles != null && index >= 0 && index < _cachedStyles!.length) {
      return _cachedStyles![index];
    }

    return {
      'fontWeight': FontWeight.w400,
      'fontVariations': <FontVariation>[],
      'opacity': 1.0,
    };
  }

  bool _showWidget = false;

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while font is loading
    if (!_fontLoaded) {
      return Container(
        key: _containerKey,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(widget.textColor),
          ),
        ),
      );
    }

    return AnimatedOpacity(
      opacity: _showWidget ? 1.0 : 0.0,
      duration: Duration(milliseconds: 1000),
      child: Container(
        key: _containerKey,
        width: double.infinity,
        height: double.infinity,
        clipBehavior: Clip.none,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Center(
                child: Transform.scale(
                  scaleY: _scaleY.clamp(0.1, 5.0),
                  scaleX: 1.0,
                  child: widget.flex ? _buildFlexText() : _buildRegularText(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlexText() {
    if (_chars.isEmpty || _charKeys.isEmpty) {
      return Container(key: _titleKey);
    }

    try {
      return Row(
        key: _titleKey,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _chars.asMap().entries.where((entry) => entry.key < _charKeys.length).map((entry) {
          final index = entry.key;
          final char = entry.value;
          return _buildCharacter(char, index);
        }).toList(),
      );
    } catch (e) {
      _handleError('buildFlexText', e);
      return Container(key: _titleKey);
    }
  }

  Widget _buildRegularText() {
    if (_chars.isEmpty || _charKeys.isEmpty) {
      return Container(key: _titleKey);
    }

    try {
      return Row(
        key: _titleKey,
        mainAxisAlignment: MainAxisAlignment.center,
        children: _chars.asMap().entries.where((entry) => entry.key < _charKeys.length).map((entry) {
          final index = entry.key;
          final char = entry.value;
          return _buildCharacter(char, index);
        }).toList(),
      );
    } catch (e) {
      _handleError('buildRegularText', e);
      return Container(key: _titleKey);
    }
  }

  Widget _buildCharacter(String char, int index) {
    try {
      final charStyle = _getCharacterStyle(index);
      final opacity = (charStyle['opacity'] as double).clamp(0.0, 1.0);
      final fontVariations = charStyle['fontVariations'] as List<FontVariation>;

      // Safe font size
      final safeFontSize = _fontSize.clamp(8.0, 500.0);

      Widget characterWidget = Transform.translate(
        offset: Offset(0, -_offsetY.clamp(-100.0, 100.0)),
        child: Text(
          char,
          key: _charKeys[index],
          style: TextStyle(
            fontFamily: _effectiveFontFamily,
            fontSize: safeFontSize,
            fontWeight: charStyle['fontWeight'] as FontWeight,
            fontVariations: fontVariations,
            color: widget.stroke ? null : widget.textColor,
            height: 0.7,
            letterSpacing: 0,
            textBaseline: TextBaseline.alphabetic,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      );

      // Apply stroke effect if enabled
      if (widget.stroke) {
        characterWidget = Stack(
          children: [
            // Stroke layer
            Text(
              char,
              style: TextStyle(
                fontFamily: _effectiveFontFamily,
                fontSize: safeFontSize,
                fontWeight: charStyle['fontWeight'] as FontWeight,
                fontVariations: fontVariations,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3.0
                  ..color = widget.strokeColor,
                height: 0.7,
                letterSpacing: 0,
                textBaseline: TextBaseline.alphabetic,
                leadingDistribution: TextLeadingDistribution.even,
              ),
            ),
            // Fill layer
            Text(
              char,
              style: TextStyle(
                fontFamily: _effectiveFontFamily,
                fontSize: safeFontSize,
                fontWeight: charStyle['fontWeight'] as FontWeight,
                fontVariations: fontVariations,
                color: widget.textColor,
                height: 0.7,
                letterSpacing: 0,
                textBaseline: TextBaseline.alphabetic,
                leadingDistribution: TextLeadingDistribution.even,
              ),
            ),
          ],
        );
      }

      return Opacity(
        opacity: opacity,
        child: characterWidget,
      );
    } catch (e) {
      _handleError('buildCharacter', e);
      // Return simple fallback
      return Text(
        char,
        key: _charKeys[index],
        style: TextStyle(
          fontSize: 24,
          color: widget.textColor,
        ),
      );
    }
  }
}

// Usage example with fontUrl and mousePositionStream
class TextPressureDemo extends StatefulWidget {
  @override
  _TextPressureDemoState createState() => _TextPressureDemoState();
}

class _TextPressureDemoState extends State<TextPressureDemo> {
  final StreamController<Offset?> _mousePositionController = StreamController<Offset?>.broadcast();

  @override
  void dispose() {
    _mousePositionController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerMove: (event) {
          _mousePositionController.add(event.position);
        },
        child: Center(
          child: Container(
            width: 800,
            height: 400,
            child: TextPressure(
              text: 'FLUTTER',
              fontFamily: 'Compressa VF',
              fontUrl: 'https://res.cloudinary.com/dr6lvwubh/raw/upload/v1529908256/CompressaPRO-GX.woff2',
              width: true,
              weight: true,
              italic: true,
              alpha: false,
              flex: true,
              stroke: true,
              scale: true,
              textColor: Colors.white,
              strokeColor: Colors.red,
              minFontSize: 32,
              mousePositionStream: _mousePositionController.stream,
            ),
          ),
        ),
      ),
    );
  }
}
