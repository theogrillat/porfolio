// ============================================================================
// IMPORTS AND EXTERNAL JS INTEROP
// ============================================================================

import 'dart:async';
import 'dart:js_interop';
import 'package:portfolio/services/analytics.dart';
import 'package:web/web.dart' as web;

/// JavaScript global checks
@JS('window.AbsoluteOrientationSensor')
external JSAny? get absoluteOrientationSensor;

@JS('window.DeviceOrientationEvent')
external JSAny? get deviceOrientationEvent;

@JS('window.navigator.permissions')
external JSAny? get navigatorPermissions;

/// External JS interop for DeviceOrientationEvent.requestPermission
@JS('DeviceOrientationEvent.requestPermission')
external JSFunction? get requestPermissionFunction;

/// Call DeviceOrientationEvent.requestPermission() directly
@JS('DeviceOrientationEvent.requestPermission')
external JSPromise<JSString>? callRequestPermission();

/// Screen API JS interop
@JS('window.screen')
external JSAny? get windowScreen;

@JS('window.screen.orientation')
external JSAny? get screenOrientation;

@JS('window.screen.orientation.type')
external JSString? get screenOrientationType;

@JS('window.screen.orientation.addEventListener')
external void addScreenOrientationListener(JSString type, JSFunction callback);

// ============================================================================
// CONSTANTS AND CONFIGURATION
// ============================================================================

/// Configuration constants for the tilt service
class TiltConfig {
  static const double defaultDriftRate = 0.95;
  static const Duration defaultUpdateInterval = Duration(milliseconds: 16);
  static const Duration defaultDriftDelay = Duration(milliseconds: 100);
  static const double defaultSnapThreshold = 0.01;
  static const double gammaDegreesRange = 90.0;
  static const double betaDegreesRange = 90.0;
}

// ============================================================================
// TILT SERVICE CLASS
// ============================================================================

/// Service that provides device tilt information as a stream
/// Works on both Android Chrome (Sensor API) and iOS Safari (DeviceOrientation API)
/// Values range from -1 (left tilt) to 1 (right tilt), where 0 is no tilt
/// Automatically adjusts tilt axis based on device orientation (portrait/landscape)
/// Returns null if tilt is not supported
class TiltService {
  // ============================================================================
  // SERVICES
  // ============================================================================

  final AnalyticsService _anal = AnalyticsService.instance;

  // ============================================================================
  // SINGLETON PATTERN
  // ============================================================================

  static TiltService? _instance;
  static TiltService get instance => _instance ??= TiltService._();
  TiltService._();

  // ============================================================================
  // STATE MANAGEMENT
  // ============================================================================

  StreamController<double?>? _controller;
  Stream<double?>? _stream;
  StreamSubscription<web.Event>? _orientationSubscription;
  StreamSubscription<web.Event>? _screenOrientationSubscription;
  Timer? _driftTimer;
  Timer? _debugTimer;

  bool _isInitialized = false;
  bool _isSupported = false;
  String? _apiType;

  // Device orientation tracking
  String _currentOrientation = 'portrait-primary';

  // ============================================================================
  // DRIFT FUNCTIONALITY STATE
  // ============================================================================

  double _currentTiltValue = 0.0;
  double _rawTiltValue = 0.0;
  DateTime _lastOrientationUpdate = DateTime.now();
  bool _isDrifting = false;
  double _driftRate = TiltConfig.defaultDriftRate;
  Duration _updateInterval = TiltConfig.defaultUpdateInterval;
  Duration _driftDelay = TiltConfig.defaultDriftDelay;
  double _snapThreshold = TiltConfig.defaultSnapThreshold;

  // ============================================================================
  // PERMISSION TRACKING STATE
  // ============================================================================

  String? _permissionStatus; // 'granted', 'denied', 'unknown'
  bool _hasTestedPermission = false;

  // ============================================================================
  // PUBLIC API METHODS
  // ============================================================================

  /// Get the tilt stream. Values range from -1 to 1, null if not supported
  Stream<double?> get tiltStream {
    if (_stream == null) {
      _controller = StreamController<double?>.broadcast();
      _stream = _controller!.stream;
      _initialize();
    }
    return _stream!;
  }

  /// Check if tilt is supported on the current platform
  bool get isSupported => _isSupported;

  /// Get the API type being used ('sensor' or 'orientation' or null)
  String? get apiType => _apiType;

  /// Check current permission status
  /// Returns: 'granted', 'denied', 'unknown', or null if not applicable
  String? get permissionStatus => _permissionStatus;

  /// Check if permission has been granted (convenience getter)
  bool get isPermissionGranted => _permissionStatus == 'granted';

  /// Check if permission has been explicitly denied
  bool get isPermissionDenied => _permissionStatus == 'denied';

  /// Check if we need to request permission (permission is unknown and required)
  bool get needsPermissionRequest {
    if (!_hasRequestPermissionMethod()) return false;
    return _permissionStatus == null || _permissionStatus == 'unknown';
  }

  /// Get current device orientation
  String get currentOrientation => _currentOrientation;

  /// Configure the drift behavior
  /// [driftRate] - How much tilt to retain each frame (0.9 = lose 10% per frame, slower drift)
  /// [updateIntervalMs] - How often to update the drift in milliseconds
  /// [driftDelayMs] - How long to wait before starting drift after device stops moving
  /// [snapThreshold] - When to snap directly to 0 (values closer to 0 than this threshold)
  void configureDrift({
    double? driftRate,
    int? updateIntervalMs,
    int? driftDelayMs,
    double? snapThreshold,
  }) {
    if (driftRate != null) {
      _driftRate = driftRate.clamp(0.0, 1.0);
    }
    if (updateIntervalMs != null) {
      _updateInterval = Duration(milliseconds: updateIntervalMs.clamp(1, 1000));
      // Restart timer with new interval if it's already running
      if (_driftTimer?.isActive == true) {
        _startDriftTimer();
      }
    }
    if (driftDelayMs != null) {
      _driftDelay = Duration(milliseconds: driftDelayMs.clamp(0, 5000));
    }
    if (snapThreshold != null) {
      _snapThreshold = snapThreshold.clamp(0.0, 0.1);
    }
  }

  /// Test permission status by attempting to detect device orientation events
  Future<String> checkPermissionStatus() async {
    if (!_hasRequestPermissionMethod()) {
      _permissionStatus = 'granted'; // No permission needed on older systems
      _anal.logEvent(
        name: 'tilt_permission_status_check',
        parameters: {
          'result': 'granted (no permission needed)',
        },
      );
      return 'granted';
    }

    if (_hasTestedPermission && _permissionStatus != null) {
      return _permissionStatus!;
    }

    print('TiltService: Testing permission status...');

    // Test by setting up a temporary listener and seeing if events fire
    bool eventsReceived = false;
    final testCompleter = Completer<String>();

    // Set up temporary event listener
    void testEventListener(web.Event event) {
      eventsReceived = true;
      print('TiltService: Permission test - events are firing');
    }

    web.window.addEventListener('deviceorientation', testEventListener.toJS);

    // Give it 2 seconds to detect events
    Timer(const Duration(seconds: 2), () {
      web.window.removeEventListener('deviceorientation', testEventListener.toJS);

      if (eventsReceived) {
        _permissionStatus = 'granted';
        print('TiltService: Permission status determined: granted');
        _anal.logEvent(
          name: 'tilt_permission_status_check',
          parameters: {
            'result': 'granted',
          },
        );
        testCompleter.complete('granted');
      } else {
        _permissionStatus = 'unknown';
        _anal.logEvent(
          name: 'tilt_permission_status_check',
          parameters: {
            'result': 'unknown',
          },
        );
        print('TiltService: Permission status determined: unknown (no events received)');
        testCompleter.complete('unknown');
      }
    });

    _hasTestedPermission = true;
    return await testCompleter.future;
  }

  /// Manually request permission (useful for iOS where permission must be requested in response to user gesture)
  Future<bool> requestPermission() async {
    try {
      print('TiltService: Manual permission request started');
      final result = await _requestOrientationPermissions();
      print('TiltService: Manual permission request result: $result');

      // Track permission status
      _permissionStatus = result ? 'granted' : 'denied';
      _hasTestedPermission = true;

      _anal.logEvent(
        name: 'tilt_permission_requested',
        parameters: {
          'permission': result ? 'granted' : 'denied',
        },
      );

      if (result && !_isSupported) {
        // If permission was granted and service wasn't supported before, try to initialize
        print('TiltService: Permission granted, reinitializing...');
        _isInitialized = false;
        await _initialize();
      }

      return result;
    } catch (e) {
      print('TiltService: Manual permission request failed: $e');
      _anal.logEvent(
        name: 'tilt_permission_request_failed',
        parameters: {
          'error': e.toString(),
        },
      );
      return false;
    }
  }

  // ============================================================================
  // INITIALIZATION METHODS
  // ============================================================================

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Initialize screen orientation tracking
    _initializeOrientationTracking();

    // Try modern Sensor API first (Android Chrome)
    if (await _tryInitializeSensorAPI()) {
      _apiType = 'sensor';
      _isSupported = true;
      _startDriftTimer();
      return;
    }

    // Fall back to DeviceOrientation API (iOS Safari, older browsers)
    if (await _tryInitializeOrientationAPI()) {
      _apiType = 'orientation';
      _isSupported = true;
      _startDriftTimer();
      return;
    }

    // Neither API is supported
    _isSupported = false;
    _controller?.add(null);
  }

  /// Try to initialize the modern Sensor API (Android Chrome)
  Future<bool> _tryInitializeSensorAPI() async {
    try {
      // Check if AbsoluteOrientationSensor is available
      if (absoluteOrientationSensor == null) {
        return false;
      }

      // For now, we'll skip the complex sensor API implementation
      // and focus on the DeviceOrientation API which is more universally supported
      return false;
    } catch (e) {
      print('TiltService: Sensor API initialization failed: $e');
      return false;
    }
  }

  /// Try to initialize the DeviceOrientation API (iOS Safari)
  Future<bool> _tryInitializeOrientationAPI() async {
    try {
      print('TiltService: Trying to initialize DeviceOrientation API');

      // Check if DeviceOrientationEvent is available
      if (deviceOrientationEvent == null) {
        print('TiltService: DeviceOrientationEvent not available');
        return false;
      }

      print('TiltService: DeviceOrientationEvent is available');

      // For iOS 13+, we need to request permission
      final permissionGranted = await _requestOrientationPermissions();
      print('TiltService: Permission granted: $permissionGranted');

      if (permissionGranted) {
        print('TiltService: Setting up orientation listener with permission');
        _setupOrientationListener();
        return true;
      } else {
        print('TiltService: Permission denied, trying without permission...');
        // Try without permission request (older iOS/Android)
        _setupOrientationListener();

        // Wait a bit to see if we get any events
        await Future.delayed(const Duration(milliseconds: 500));

        print('TiltService: Orientation listener setup complete (legacy mode)');
        return true; // We'll assume it might work and let the stream handle null values
      }
    } catch (e) {
      print('TiltService: DeviceOrientation API initialization failed: $e');
      return false;
    }
  }

  // ============================================================================
  // ORIENTATION TRACKING METHODS
  // ============================================================================

  /// Initialize screen orientation tracking to adjust tilt axis
  void _initializeOrientationTracking() {
    // Get initial orientation
    _updateCurrentOrientation();

    // Listen for orientation changes
    web.window.addEventListener(
      'orientationchange',
      (web.Event event) {
        // Delay slightly to allow orientation to settle
        Timer(const Duration(milliseconds: 100), () {
          _updateCurrentOrientation();
        });
      }.toJS,
    );

    // Also listen to screen.orientation.change if available
    try {
      if (screenOrientation != null) {
        addScreenOrientationListener(
          'change'.toJS,
          (JSAny event) {
            _updateCurrentOrientation();
          }.toJS,
        );
      }
    } catch (e) {
      print('TiltService: Screen orientation change listener not available: $e');
    }
  }

  /// Update the current orientation state
  void _updateCurrentOrientation() {
    try {
      // Try modern Screen Orientation API first
      final orientationType = screenOrientationType;
      if (orientationType != null) {
        _currentOrientation = orientationType.toDart;
        print('TiltService: Orientation updated to: $_currentOrientation');
        return;
      }
    } catch (e) {
      print('TiltService: Screen orientation API not available: $e');
    }

    // Fall back to window.orientation (deprecated but widely supported)
    try {
      final orientation = web.window.orientation;
      switch (orientation) {
        case 0:
          _currentOrientation = 'portrait-primary';
          break;
        case 90:
          _currentOrientation = 'landscape-primary';
          break;
        case 180:
          _currentOrientation = 'portrait-secondary';
          break;
        case 270:
        case -90:
          _currentOrientation = 'landscape-secondary';
          break;
        default:
          _currentOrientation = 'portrait-primary';
      }
      print('TiltService: Orientation updated to: $_currentOrientation (from window.orientation: $orientation)');
      return;
    } catch (e) {
      print('TiltService: Window orientation not available: $e');
    }

    // Final fallback: use media query
    try {
      final isPortrait = web.window.matchMedia('(orientation: portrait)').matches;
      _currentOrientation = isPortrait ? 'portrait-primary' : 'landscape-primary';
      print('TiltService: Orientation updated to: $_currentOrientation (from media query)');
    } catch (e) {
      print('TiltService: Media query orientation detection failed: $e');
      _currentOrientation = 'portrait-primary'; // Default fallback
    }
  }

  // ============================================================================
  // EVENT HANDLING METHODS
  // ============================================================================

  void _setupOrientationListener() {
    print('TiltService: Setting up orientation listener');

    // Use the addEventListener approach instead of the direct stream
    web.window.addEventListener(
        'deviceorientation',
        (web.Event event) {
          try {
            // Cast to DeviceOrientationEvent to access orientation properties
            final orientation = event as web.DeviceOrientationEvent;
            final gamma = orientation.gamma; // Left/right tilt (-90 to 90 degrees)
            final alpha = orientation.alpha; // Compass direction
            final beta = orientation.beta; // Front/back tilt

            print('TiltService: Orientation event - alpha: $alpha, beta: $beta, gamma: $gamma, screenOrientation: $_currentOrientation');

            // Mark permission as granted when we receive events
            if (_permissionStatus != 'granted') {
              _permissionStatus = 'granted';
              _hasTestedPermission = true;
              print('TiltService: Permission status updated to granted (events received)');
            }

            if (gamma != null && beta != null && !gamma.isNaN && !beta.isNaN) {
              // Transform tilt values based on device orientation
              final normalizedTilt = _transformTiltForOrientation(gamma, beta);

              print('TiltService: Normalized tilt: $normalizedTilt');

              // Update raw tilt value and reset drift state
              _rawTiltValue = normalizedTilt;
              _lastOrientationUpdate = DateTime.now();
              _isDrifting = false;

              // Immediately update the current value
              _currentTiltValue = normalizedTilt;
              _controller?.add(_currentTiltValue);
            } else {
              print('TiltService: Gamma or Beta is null or NaN - gamma: $gamma, beta: $beta');
              _controller?.add(0.0); // Send 0 instead of null for debugging
            }
          } catch (e) {
            print('TiltService: Error processing orientation event: $e');
            _controller?.add(null);
          }
        }.toJS);

    print('TiltService: Event listeners registered successfully');
  }

  /// Transform tilt values based on current device orientation
  double _transformTiltForOrientation(double gamma, double beta) {
    switch (_currentOrientation) {
      case 'portrait-primary':
        // Normal portrait: gamma is left/right tilt (what we want)
        return (gamma / TiltConfig.gammaDegreesRange).clamp(-1.0, 1.0);

      case 'portrait-secondary':
        // Upside-down portrait: gamma is inverted
        return (-gamma / TiltConfig.gammaDegreesRange).clamp(-1.0, 1.0);

      case 'landscape-primary':
        // Landscape (rotated 90° clockwise): beta becomes our left/right tilt
        return (beta / TiltConfig.betaDegreesRange).clamp(-1.0, 1.0);

      case 'landscape-secondary':
        // Landscape (rotated 90° counter-clockwise): beta is inverted
        return (-beta / TiltConfig.betaDegreesRange).clamp(-1.0, 1.0);

      default:
        // Fallback to portrait-primary behavior
        return (gamma / TiltConfig.gammaDegreesRange).clamp(-1.0, 1.0);
    }
  }

  // ============================================================================
  // DRIFT PROCESSING METHODS
  // ============================================================================

  /// Start the drift timer that gradually reduces tilt toward zero
  void _startDriftTimer() {
    _driftTimer?.cancel();
    _driftTimer = Timer.periodic(_updateInterval, (timer) {
      _processDrift();
    });
  }

  /// Process the drift-to-zero functionality
  void _processDrift() {
    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(_lastOrientationUpdate);

    // Only start drifting after the delay period
    if (timeSinceLastUpdate >= _driftDelay) {
      if (!_isDrifting) {
        _isDrifting = true;
        // Start from the last raw tilt value
        _currentTiltValue = _rawTiltValue;
      }

      // Apply drift rate to gradually reduce the tilt value toward zero
      _currentTiltValue *= _driftRate;

      // Snap to zero if below threshold
      if (_currentTiltValue.abs() < _snapThreshold) {
        _currentTiltValue = 0.0;
      }

      // Send the processed value to the stream
      _controller?.add(_currentTiltValue);
    }
    // If we're within the delay period, don't do anything -
    // the orientation listener handles immediate updates
  }

  // ============================================================================
  // PERMISSION MANAGEMENT METHODS
  // ============================================================================

  /// Request orientation permissions (for iOS 13+)
  Future<bool> _requestOrientationPermissions() async {
    try {
      if (deviceOrientationEvent == null) {
        print('TiltService: DeviceOrientationEvent is null');
        return false;
      }

      print('TiltService: DeviceOrientationEvent is available');

      // Use direct JavaScript evaluation for permission request
      final hasRequestPermission = _hasRequestPermissionMethod();
      print('TiltService: Has requestPermission method: $hasRequestPermission');

      if (hasRequestPermission) {
        print('TiltService: Requesting device orientation permission...');
        final permission = await _requestPermissionJS();
        print('TiltService: Permission result: $permission');

        // Track permission status
        _permissionStatus = permission;
        _hasTestedPermission = true;

        return permission == 'granted';
      }

      // For older versions, permissions are not required
      print('TiltService: No permission required (older iOS/Android)');
      return true;
    } catch (e) {
      print('TiltService: Error requesting orientation permissions: $e');
      return false;
    }
  }

  bool _hasRequestPermissionMethod() {
    return requestPermissionFunction != null;
  }

  /// Request permission using direct JS interop
  Future<String> _requestPermissionJS() async {
    try {
      if (requestPermissionFunction != null) {
        print('TiltService: Calling DeviceOrientationEvent.requestPermission()');

        try {
          // Call the actual permission function
          final jsPromise = callRequestPermission();
          if (jsPromise != null) {
            print('TiltService: Awaiting permission response...');
            final jsResult = await jsPromise.toDart;
            final result = jsResult.toDart;
            print('TiltService: Permission response: $result');
            return result;
          } else {
            print('TiltService: Permission function returned null');
            return 'denied';
          }
        } catch (jsError) {
          print('TiltService: JS permission call failed: $jsError');
          return 'denied';
        }
      }
      return 'granted'; // Assume granted if method doesn't exist
    } catch (e) {
      print('TiltService: Error in JS permission request: $e');
      return 'denied';
    }
  }

  // ============================================================================
  // CLEANUP METHODS
  // ============================================================================

  /// Dispose of resources
  void dispose() {
    _orientationSubscription?.cancel();
    _screenOrientationSubscription?.cancel();
    _driftTimer?.cancel();
    _debugTimer?.cancel();
    _controller?.close();
    _controller = null;
    _stream = null;
    _driftTimer = null;
    _debugTimer = null;
    _orientationSubscription = null;
    _screenOrientationSubscription = null;
    _isInitialized = false;
    _isSupported = false;
    _apiType = null;
    _currentTiltValue = 0.0;
    _rawTiltValue = 0.0;
    _isDrifting = false;
    _lastOrientationUpdate = DateTime.now();
    _permissionStatus = null;
    _hasTestedPermission = false;
    _currentOrientation = 'portrait-primary';
  }
}
