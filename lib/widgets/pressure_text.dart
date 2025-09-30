import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
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

  // Track pending operations for proper cleanup
  Future<void>? _pendingFontLoad;
  Future<void>? _pendingSizeCalculation;
  Future<void>? _pendingVerticalCalculation;

  // Performance optimization caches
  List<Rect>? _cachedCharBounds;
  Rect? _cachedContainerBounds;
  int _boundsUpdateCounter = 0;
  static const int BOUNDS_UPDATE_INTERVAL = 3; // Update bounds every 3 frames (20fps for positioning)

  // Character style cache to prevent recalculation
  List<Map<String, dynamic>>? _cachedStyles;
  int _styleUpdateCounter = 0;
  static const int STYLE_UPDATE_INTERVAL = 2; // Update styles every 2 frames (30fps for effects)

  // Mouse movement optimization
  double _lastMouseX = 0.0;
  static const double MOUSE_MOVEMENT_THRESHOLD = 3.0; // Only update if mouse moves > 3 pixels

  // Font variation cache to avoid object creation
  final Map<String, List<FontVariation>> _fontVariationCache = {};

  // Cached RenderBox references
  RenderBox? _cachedContainerRenderBox;
  List<RenderBox?> _cachedCharRenderBoxes = [];

  // Error tracking for stability
  int _errorCount = 0;
  static const int MAX_ERRORS = 10;

  // Safety throttling when system is under pressure
  bool _isThrottled = false;
  int _framesSinceLastCheck = 0;

  // Flag to prevent execution during disposal
  bool _isDisposing = false;

  // WASM/Web compatibility check
  bool get _isWeb => kIsWeb;

  // WASM-safe font variation helper with caching
  List<FontVariation> _createSafeFontVariations(double wght, double wdth, double ital) {
    // Create cache key with rounded values to improve cache hit rate
    final keyWght = (wght / 25).round() * 25; // Round to nearest 25
    final keyWdth = (wdth / 10).round() * 10; // Round to nearest 10
    final keyItal = (ital * 10).round() / 10; // Round to 1 decimal place
    final cacheKey = '${keyWght}_${keyWdth}_${keyItal}';

    // Return cached result if available
    if (_fontVariationCache.containsKey(cacheKey)) {
      return _fontVariationCache[cacheKey]!;
    }

    List<FontVariation> variations = [];

    if (_isWeb) {
      // WASM-safe ranges for CanvasKit compatibility
      if (widget.weight && wght.isFinite) {
        // Limit weight range for WASM stability (100-900 is safest)
        final safeWght = wght.clamp(100.0, 900.0);
        variations.add(FontVariation('wght', safeWght));
      }
      if (widget.width && wdth.isFinite) {
        // Limit width range for WASM stability (75-125 is safest for most fonts)
        final safeWdth = wdth.clamp(75.0, 125.0);
        variations.add(FontVariation('wdth', safeWdth));
      }
      if (widget.italic && ital.isFinite) {
        // Limit italic range for WASM stability (0-1 is safest)
        final safeItal = ital.clamp(0.0, 1.0);
        variations.add(FontVariation('ital', safeItal));
      }
    } else {
      // Full ranges for native platforms
      if (widget.weight && wght.isFinite) variations.add(FontVariation('wght', wght));
      if (widget.width && wdth.isFinite) variations.add(FontVariation('wdth', wdth));
      if (widget.italic && ital.isFinite) variations.add(FontVariation('ital', ital));
    }

    // Cache the result (limit cache size to prevent memory leaks)
    if (_fontVariationCache.length < 200) {
      _fontVariationCache[cacheKey] = variations;
    }

    return variations;
  }

  @override
  void initState() {
    super.initState();

    try {
      _chars = widget.text.split('');
      _charKeys = List.generate(_chars.length, (index) => GlobalKey());

      // 60fps = ~16.66ms intervals - much more reasonable
      _animationController = AnimationController(
        duration: Duration(milliseconds: 16), // 60fps
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
      _cachedCharRenderBoxes = List.filled(_chars.length, null);

      _loadFontFromUrl();

      // Listen to mouse position stream with movement threshold
      _mouseStreamSubscription = widget.mousePositionStream.listen((Offset? position) {
        if (mounted) {
          if (position != null) {
            // Only update if mouse moved significantly
            final dx = position.dx;
            if ((dx - _lastMouseX).abs() > MOUSE_MOVEMENT_THRESHOLD) {
              setState(() {
                _targetMousePosition = Offset(dx, 0);
                _lastMouseX = dx;
              });
            }
          } else {
            // Reset to center when cursor is outside viewport
            setState(() {
              _targetMousePosition = Offset.zero;
              _lastMouseX = 0.0;
            });
          }
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pendingSizeCalculation = _calculateSize();
          if (widget.boxSize != null) {
            _pendingVerticalCalculation = _calculateVerticalOffsetOfText(widget.boxSize!);
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
        _cachedCharRenderBoxes = List.filled(_chars.length, null);
        _invalidateCaches();
      }

      // Recalculate size if boxSize changed
      if (widget.boxSize != oldWidget.boxSize) {
        setState(() {
          _showWidget = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _pendingSizeCalculation = _calculateSize();
            _pendingVerticalCalculation = Future.delayed(Duration(milliseconds: 50), () {
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
    // Set disposal flag to prevent any further execution
    _isDisposing = true;

    // Cancel pending operations
    _pendingFontLoad?.ignore();
    _pendingSizeCalculation?.ignore();
    _pendingVerticalCalculation?.ignore();

    // Remove animation listener first to prevent callbacks during disposal
    _animationController.removeListener(_animateMouseFollow);

    // Stop and dispose animation controller
    _animationController.stop();
    _animationController.dispose();

    // Cancel stream subscription
    _mouseStreamSubscription?.cancel();

    // Clear cached data to free memory (safely handle immutable lists)
    try {
      _cachedCharBounds?.clear();
    } catch (e) {
      // Ignore clear errors for immutable lists
    }
    _cachedCharBounds = null;
    _cachedContainerBounds = null;

    try {
      _cachedStyles?.clear();
    } catch (e) {
      // Ignore clear errors for immutable lists
    }
    _cachedStyles = null;

    // Clear font variation cache
    _fontVariationCache.clear();

    // Clear cached render boxes
    try {
      _cachedCharRenderBoxes.clear();
    } catch (e) {
      // Ignore clear errors for immutable lists
    }
    _cachedContainerRenderBox = null;

    // Clear character arrays (safely handle immutable lists)
    try {
      _chars.clear();
    } catch (e) {
      // Ignore clear errors for immutable lists
    }

    try {
      _charKeys.clear();
    } catch (e) {
      // Ignore clear errors for immutable lists
    }

    super.dispose();
  }

  void _handleError(String context, dynamic error) {
    _errorCount++;
    print('TextPressure error in $context: $error');

    if (_errorCount > MAX_ERRORS) {
      print('Too many errors, disabling complex animations');
      try {
        if (mounted) {
          _animationController.stop();
        }
      } catch (e) {
        // Ignore errors when stopping animation controller
      }
    }
  }

  void _invalidateCaches() {
    _cachedCharBounds = null;
    _cachedContainerBounds = null;
    _cachedContainerRenderBox = null;
    _cachedCharRenderBoxes = List.filled(_chars.length, null);
    _fontVariationCache.clear();
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
      if (mounted) {
        setState(() {
          _effectiveFontFamily = widget.fontFamily;
          _fontLoaded = true;
        });
      }
      return;
    }

    // Store the future to allow cancellation
    _pendingFontLoad = _performFontLoad();
    await _pendingFontLoad;
  }

  Future<void> _performFontLoad() async {
    http.Response? response;
    try {
      response = await http.get(Uri.parse(widget.fontUrl!)).timeout(Duration(seconds: 10));

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
    } finally {
      // Response will be automatically garbage collected
      // No explicit disposal needed for http.Response
    }
  }

  Future<void> _calculateSize() async {
    if (!mounted || _chars.isEmpty) return;

    try {
      Size containerSize;
      if (widget.boxSize != null) {
        containerSize = widget.boxSize!;
      } else {
        final context = _containerKey.currentContext;
        if (!mounted || context == null) return;

        final containerRenderBox = context.findRenderObject() as RenderBox?;
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
            _pendingVerticalCalculation = Future.delayed(Duration(milliseconds: 50), () {
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
      final context = _titleKey.currentContext;
      if (!mounted || context == null) return;

      final titleRenderBox = context.findRenderObject() as RenderBox?;
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

  Future<void> _calculateVerticalOffsetOfText(Size containerSize) async {
    if (!mounted) return;

    try {
      final context = _titleKey.currentContext;
      if (!mounted || context == null) return;

      final titleRenderBox = context.findRenderObject() as RenderBox?;
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
    if (!mounted || _errorCount > MAX_ERRORS || _isDisposing) return;

    // Additional safety check - ensure widget is still part of the tree
    if (_containerKey.currentContext == null) return;

    try {
      // Check for system pressure every 60 frames (0.5 seconds)
      _framesSinceLastCheck++;
      if (_framesSinceLastCheck >= 60) {
        _framesSinceLastCheck = 0;
      }

      // Calculate new mouse position
      final newMouseX = _mousePosition.dx + (_targetMousePosition.dx - _mousePosition.dx) / 15;
      final mouseHasMoved = (newMouseX - _mousePosition.dx).abs() > 0.5; // Only update if movement is significant

      // Update mouse position
      _mousePosition = Offset(newMouseX, 0);

      // Throttle expensive calculations when under pressure
      final boundsInterval = _isThrottled ? BOUNDS_UPDATE_INTERVAL * 3 : BOUNDS_UPDATE_INTERVAL;
      final styleInterval = _isThrottled ? STYLE_UPDATE_INTERVAL * 2 : STYLE_UPDATE_INTERVAL;

      _boundsUpdateCounter++;
      _styleUpdateCounter++;

      bool needsRebuild = false;

      if (_boundsUpdateCounter >= boundsInterval) {
        _boundsUpdateCounter = 0;
        _updateCharacterBounds();
        needsRebuild = true;
      }

      if (_styleUpdateCounter >= styleInterval && !_isThrottled && mouseHasMoved) {
        _styleUpdateCounter = 0;
        _updateCharacterStyles();
        needsRebuild = true;
      }

      // Only call setState if something actually changed
      if (needsRebuild || mouseHasMoved) {
        setState(() {});
      }
    } catch (e) {
      _handleError('animateMouseFollow', e);
    }
  }

  void _updateCharacterBounds() {
    if (!mounted || _isDisposing) return;

    try {
      // Cache container RenderBox if not already cached
      if (_cachedContainerRenderBox == null) {
        final context = _containerKey.currentContext;
        if (!mounted || context == null) return;
        _cachedContainerRenderBox = context.findRenderObject() as RenderBox?;
      }

      if (_cachedContainerRenderBox == null || !_cachedContainerRenderBox!.hasSize) return;

      // Update container bounds
      _cachedContainerBounds = Rect.fromLTWH(0, 0, _cachedContainerRenderBox!.size.width, _cachedContainerRenderBox!.size.height);

      // Initialize bounds list if needed
      _cachedCharBounds ??= List.filled(_charKeys.length, Rect.zero);

      // Only update bounds for characters that actually exist and have render boxes
      for (int i = 0; i < _charKeys.length; i++) {
        if (!mounted) break; // Check mounted state in loop

        // Use cached RenderBox if available
        RenderBox? charRenderBox = _cachedCharRenderBoxes[i];

        if (charRenderBox == null) {
          final charContext = _charKeys[i].currentContext;
          if (charContext == null) continue;
          charRenderBox = charContext.findRenderObject() as RenderBox?;
          // Cache the RenderBox for future use
          if (charRenderBox != null && i < _cachedCharRenderBoxes.length) {
            _cachedCharRenderBoxes[i] = charRenderBox;
          }
        }

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
          // Clear cached RenderBox if it's no longer valid
          if (i < _cachedCharRenderBoxes.length) {
            _cachedCharRenderBoxes[i] = null;
          }
        }
      }
    } catch (e) {
      _handleError('updateCharacterBounds', e);
    }
  }

  void _updateCharacterStyles() {
    if (!mounted || _isDisposing) return;

    try {
      // Use cached container RenderBox
      if (_cachedContainerRenderBox == null || !_cachedContainerRenderBox!.hasSize) return;

      final containerPosition = _cachedContainerRenderBox!.localToGlobal(Offset.zero);
      // Mouse position from stream is already in global coordinates
      final localMousePosition = Offset(
        _mousePosition.dx,
        containerPosition.dy + _cachedContainerRenderBox!.size.height / 2, // Use container's center y position
      );

      // Use cached bounds if available, otherwise get fresh bounds
      final maxDistance = _cachedContainerBounds != null ? math.max(_cachedContainerBounds!.width / 2, 1.0) : math.max(_cachedContainerRenderBox!.size.width / 2, 1.0);

      for (int i = 0; i < _chars.length; i++) {
        if (!mounted) break; // Check mounted state in loop

        Offset charCenter;

        // Use cached bounds if available and recent, otherwise calculate fresh
        if (_cachedCharBounds != null && i < _cachedCharBounds!.length && _cachedCharBounds![i] != Rect.zero) {
          final charBounds = _cachedCharBounds![i];
          charCenter = Offset(charBounds.left, charBounds.top);
        } else {
          // Try to use cached RenderBox first
          RenderBox? charRenderBox = i < _cachedCharRenderBoxes.length ? _cachedCharRenderBoxes[i] : null;

          if (charRenderBox == null) {
            // Fallback to real-time bounds for smooth interaction
            final charContext = _charKeys[i].currentContext;
            if (!mounted || charContext == null) continue;
            charRenderBox = charContext.findRenderObject() as RenderBox?;
          }

          if (charRenderBox == null || !charRenderBox.hasSize) continue;

          final charPosition = charRenderBox.localToGlobal(Offset.zero);
          final charSize = charRenderBox.size;
          charCenter = Offset(
            charPosition.dx + charSize.width / 2,
            charPosition.dy + charSize.height / 2,
          );
        }

        final squaredDistance = _calculateSquaredDistance(localMousePosition, charCenter);
        final maxSquaredDistance = maxDistance * maxDistance; // Use squared max distance

        double _getAttribute(double squaredDist, double minVal, double maxVal) {
          if (maxSquaredDistance <= 0 || !squaredDist.isFinite || !maxSquaredDistance.isFinite) return minVal;
          final val = maxVal - math.min(maxVal, (maxVal * squaredDist) / maxSquaredDistance);
          final result = math.max(minVal, val + minVal);
          return result.isFinite ? result : minVal;
        }

        double wdth = widget.width ? _getAttribute(squaredDistance, 5, 200).clamp(1, 1000) : 100;
        double wght = widget.weight ? _getAttribute(squaredDistance, 200, 900).clamp(100, 1000) : 400;
        double ital = widget.italic ? _getAttribute(squaredDistance, 0, 1).clamp(0, 1) : 0;
        double opacity = widget.alpha ? _getAttribute(squaredDistance, 0.6, 1).clamp(0, 1) : 1.0;

        // Safety checks
        if (!wdth.isFinite) wdth = 100;
        if (!wght.isFinite) wght = 400;
        if (!ital.isFinite) ital = 0;
        if (!opacity.isFinite) opacity = 1.0;

        // Use WASM-safe font variations
        List<FontVariation> variations = _createSafeFontVariations(wght, wdth, ital);

        int weightIndex = ((wght - 100) / 100).clamp(0, 8).round();
        weightIndex = math.min(weightIndex, FontWeight.values.length - 1);

        // Check mounted state before updating cached styles
        if (!mounted || _cachedStyles == null || i >= _cachedStyles!.length) continue;

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

  double _calculateSquaredDistance(Offset point1, Offset point2) {
    try {
      // Only calculate squared distance based on x-axis (dx) - avoid expensive sqrt
      final dx = point2.dx - point1.dx;
      final squaredDistance = dx * dx;
      return squaredDistance.isFinite ? squaredDistance : 0.0;
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
                child: RepaintBoundary(
                  child: Transform.scale(
                    scaleY: _scaleY.clamp(0.1, 5.0),
                    scaleX: 1.0,
                    child: widget.flex ? _buildFlexText() : _buildRegularText(),
                  ),
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

      // Create text style with WASM-safe error handling
      TextStyle createSafeTextStyle({Paint? foreground, Color? color}) {
        try {
          return TextStyle(
            fontFamily: _effectiveFontFamily,
            fontSize: safeFontSize,
            fontWeight: charStyle['fontWeight'] as FontWeight,
            fontVariations: fontVariations,
            foreground: foreground,
            color: color,
            height: 0.7,
            letterSpacing: 0,
            textBaseline: TextBaseline.alphabetic,
            leadingDistribution: TextLeadingDistribution.even,
          );
        } catch (e) {
          // Fallback without font variations if WASM crashes
          _handleError('TextStyle with fontVariations', e);
          return TextStyle(
            fontFamily: _effectiveFontFamily,
            fontSize: safeFontSize,
            fontWeight: charStyle['fontWeight'] as FontWeight,
            foreground: foreground,
            color: color,
            height: 0.7,
            letterSpacing: 0,
            textBaseline: TextBaseline.alphabetic,
            leadingDistribution: TextLeadingDistribution.even,
          );
        }
      }

      Widget characterWidget = Transform.translate(
        offset: Offset(0, -_offsetY.clamp(-100.0, 100.0)),
        child: Text(
          char,
          key: _charKeys[index],
          style: createSafeTextStyle(color: widget.stroke ? null : widget.textColor),
        ),
      );

      // Apply stroke effect if enabled
      if (widget.stroke) {
        characterWidget = Stack(
          children: [
            // Stroke layer
            Text(
              char,
              style: createSafeTextStyle(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3.0
                  ..color = widget.strokeColor,
              ),
            ),
            // Fill layer
            Text(
              char,
              style: createSafeTextStyle(color: widget.textColor),
            ),
          ],
        );
      }

      return RepaintBoundary(
        child: Opacity(
          opacity: opacity,
          child: characterWidget,
        ),
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
