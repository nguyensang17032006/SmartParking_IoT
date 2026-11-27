  import 'dart:async';

  import 'package:flutter/foundation.dart';

  import '../../domain/entities/navigation_destination.dart';
  import '../../domain/entities/navigation_location.dart';
  import '../../domain/entities/navigation_route.dart';

  import '../../domain/usecases/get_current_location.dart';
  import '../../domain/usecases/get_navigation_route.dart';
  import '../../domain/usecases/watch_location.dart';
  import '../../domain/entities/navigation_progress.dart';
  import '../../domain/entities/navigation_instruction.dart';

  import '../../domain/services/navigation_distance_service.dart';
  import '../../domain/services/navigation_progress_service.dart';
  import '../../domain/services/navigation_instruction_service.dart';
  import '../../domain/entities/off_route_result.dart';
  import '../../domain/services/off_route_detection_service.dart';
  import '../../domain/entities/arrival_result.dart';
  import '../../domain/services/arrival_detection_service.dart';

  enum NavigationState {
    idle,
    loading,
    ready,
    navigating,
    arrived,
    stopped,
    error,
  }

  class NavigationViewModel extends ChangeNotifier {
    // DEPENDENCIES
    final GetCurrentLocation getCurrentLocation;
    final GetNavigationRoute getNavigationRoute;
    final WatchLocation watchLocation;
    final NavigationDistanceService distanceService;

    final NavigationProgressService progressService;
    final OffRouteDetectionService offRouteService;
    final NavigationInstructionService instructionService;
    final ArrivalDetectionService arrivalService;
    NavigationViewModel({
      required this.getCurrentLocation,
      required this.getNavigationRoute,
      required this.watchLocation,
      required this.distanceService,
      required this.progressService,
      required this.instructionService,
      required this.offRouteService,
      required this.arrivalService,
    });

    // STATE
    int _arrivalCount = 0;

    ArrivalResult? _arrivalResult;
    NavigationState _state = NavigationState.idle;

    NavigationLocation? _currentLocation;
    NavigationDestination? _destination;
    NavigationRoute? _route;

    String? _errorMessage;

    StreamSubscription<NavigationLocation>? _locationSubscription;

    bool _isDisposed = false;

    Future<void>? _activeOperation;
    NavigationProgress? _progress;

    NavigationInstruction? _instruction;

    double _remainingDistance = 0;

    double _remainingDuration = 0;

    double _distanceFromRoute = 0;

    double _distanceToDestination = 0;
    int _offRouteCount = 0;

    OffRouteResult? _offRouteResult;
    bool _isRerouting = false;
    bool _rerouteRequestInFlight = false;

    DateTime? _lastRerouteTime;

    String? _rerouteErrorMessage;

    int _navigationSessionId = 0;

    static const Duration _rerouteCooldown = Duration(seconds: 15);
    // GETTERS
    ArrivalResult? get arrivalResult => _arrivalResult;

    int get arrivalCount => _arrivalCount;
    NavigationState get state => _state;

    NavigationLocation? get currentLocation => _currentLocation;

    NavigationDestination? get destination => _destination;

    NavigationRoute? get route => _route;

    String? get errorMessage => _errorMessage;

    bool get isLoading => _state == NavigationState.loading;

    bool get isReady => _state == NavigationState.ready;

    bool get isNavigating => _state == NavigationState.navigating;

    bool get isArrived => _state == NavigationState.arrived;

    bool get hasError => _state == NavigationState.error;

    double get totalDistance => _route?.distance ?? 0;

    double get totalDuration => _route?.duration ?? 0;
    NavigationProgress? get progress => _progress;

    NavigationInstruction? get instruction => _instruction;

    double get remainingDistance => _remainingDistance;

    double get remainingDuration => _remainingDuration;

    double get distanceFromRoute => _distanceFromRoute;

    double get distanceToDestination => _distanceToDestination;
    OffRouteResult? get offRouteResult => _offRouteResult;

    bool get isOffRoute => _offRouteResult?.isOffRoute ?? false;

    int get offRouteCount => _offRouteCount;
    bool get isRerouting => _isRerouting;

    String? get rerouteErrorMessage => _rerouteErrorMessage;

    bool _canReroute() {
      if (_isDisposed ||
          !isNavigating ||
          _isRerouting ||
          _rerouteRequestInFlight ||
          !isOffRoute) {
        return false;
      }

      final lastTime = _lastRerouteTime;

      if (lastTime == null) {
        return true;
      }

      final elapsed = DateTime.now().difference(lastTime);

      return elapsed >= _rerouteCooldown;
    }

    Future<void> _completeArrival() async {
      if (_isDisposed || !isNavigating) {
        return;
      }

      // 1. Vô hiệu hóa phiên rerouting hiện tại.
      _resetReroutingState();

      // 2. Cập nhật thông tin còn lại.
      _remainingDistance = 0;
      _remainingDuration = 0;

      _instruction = null;

      // 3. Lấy GPS subscription hiện tại.
      final subscription = _locationSubscription;

      _locationSubscription = null;

      // 4. Chuyển trạng thái ngay lập tức.
      _setState(NavigationState.arrived);

      // 5. Ngừng theo dõi GPS.
      try {
        await subscription?.cancel();
      } catch (error) {
        debugPrint('GPS cleanup error: $error');
      }

      debugPrint('ARRIVAL SUCCESS');
    }

   bool _checkArrival(NavigationLocation location) {
  final progress = _progress;

  if (_isDisposed ||
      !isNavigating ||
      progress == null ||
      _isRerouting ||
      isOffRoute) {
    _resetArrivalState();
    return false;
  }

  final result = arrivalService.evaluate(
    location: location,
    distanceToDestination: _distanceToDestination,
    remainingDistance: progress.remainingDistance,
    distanceFromRoute: progress.distanceFromRoute,
    previousCount: _arrivalCount,
  );

  _arrivalResult = result;

  _arrivalCount = result.consecutiveCount;

  return result.isArrived;
}

    Future<void> _reroute() async {
      if (!_canReroute()) {
        return;
      }

      final location = _currentLocation;
      final destination = _destination;

      if (location == null || destination == null) {
        return;
      }

      final sessionId = _navigationSessionId;

      _rerouteRequestInFlight = true;
      _isRerouting = true;
      _rerouteErrorMessage = null;
      _lastRerouteTime = DateTime.now();

      notifyListeners();

      try {
        final newRoute = await getNavigationRoute(
          origin: location,
          destination: destination,
        );

        if (_isDisposed || !isNavigating || sessionId != _navigationSessionId) {
          return;
        }

        if (newRoute.points.length < 2) {
          throw Exception('Tuyến đường mới không hợp lệ.');
        }

        _route = newRoute;
        _resetArrivalState();
        _progress = null;
        _instruction = null;

        _offRouteCount = 0;
        _offRouteResult = null;

        _remainingDistance = newRoute.distance;
        _remainingDuration = newRoute.duration;

        _distanceFromRoute = 0;

        final latestLocation = _currentLocation ?? location;

        _updateNavigationProgress(latestLocation);

        debugPrint('REROUTE SUCCESS');
      } catch (error) {
        if (_isDisposed || !isNavigating || sessionId != _navigationSessionId) {
          return;
        }

        _rerouteErrorMessage = 'Không thể tìm lại đường. Đang chờ thử lại.';

        debugPrint('REROUTE ERROR: $error');
      } finally {
        _rerouteRequestInFlight = false;

        if (!_isDisposed && sessionId == _navigationSessionId) {
          _isRerouting = false;

          notifyListeners();
        }
      }
    }

    void _checkOffRoute(NavigationLocation location) {
      final progress = _progress;

      if (progress == null) {
        return;
      }

      final result = offRouteService.evaluate(
        location: location,
        progress: progress,
        previousCount: _offRouteCount,
      );

      _offRouteResult = result;

      _offRouteCount = result.consecutiveCount;

      if (result.isOffRoute) {
        debugPrint(
          'OFF ROUTE: '
          '${result.distanceFromRoute.toStringAsFixed(1)} m',
        );
      }
    }

    void _updateNavigationProgress(NavigationLocation location) {
      final route = _route;
      final destination = _destination;

      if (route == null || destination == null) {
        return;
      }

      final destinationLocation = NavigationLocation(
        latitude: destination.latitude,
        longitude: destination.longitude,
      );

      _distanceToDestination = distanceService.distanceBetween(
        location,
        destinationLocation,
      );

      if (route.points.length < 2) {
        return;
      }

      final progress = progressService.calculateProgress(
        currentLocation: location,
        routePoints: route.points,
        previousProgress: _progress,
      );

      _progress = progress;
      debugPrint(
        'NAV PROGRESS: '
        'accuracy=${location.accuracy.toStringAsFixed(1)}m, '
        'matched=${progress.distanceFromRoute.toStringAsFixed(1)}m, '
        'nearest=${progress.nearestRouteDistance.toStringAsFixed(1)}m, '
        'traveled=${progress.traveledDistance.toStringAsFixed(1)}m, '
        'remaining=${progress.remainingDistance.toStringAsFixed(1)}m',
      );
      _distanceFromRoute = progress.distanceFromRoute;

      final geometryDistance =
          progress.traveledDistance + progress.remainingDistance;

      final remainingRatio = geometryDistance > 0
          ? (progress.remainingDistance / geometryDistance)
                .clamp(0.0, 1.0)
                .toDouble()
          : 0.0;

      _remainingDistance = route.distance * remainingRatio;

      _remainingDuration = route.duration * remainingRatio;

      _instruction = instructionService.getNextInstruction(
        route: route,
        progress: progress,
      );
    }

    // UPDATE STATE
    void _setState(NavigationState state) {
      if (_isDisposed) return;

      _state = state;
      notifyListeners();
    }

    // HANDLE ERROR
    void _handleError(Object error) {
      if (_isDisposed) return;

      _errorMessage = error.toString();

      _setState(NavigationState.error);
    }

    // PREVENT CONCURRENT OPERATIONS
    Future<void> _runOperation(Future<void> Function() operation) async {
      if (_isDisposed || _activeOperation != null) {
        return;
      }

      final completer = Completer<void>();

      _activeOperation = completer.future;

      try {
        await operation();
      } catch (error) {
        _handleError(error);
      } finally {
        _activeOperation = null;
        completer.complete();
      }
    }

    // PREPARE NAVIGATION
    Future<void> prepareNavigation(NavigationDestination destination) {
      if (isNavigating) return Future.value();

      return _runOperation(() async {
        _resetReroutingState();
        _resetArrivalState();
        _destination = destination;
        _errorMessage = null;
        _currentLocation = null;
        _route = null;
        _progress = null;
        _instruction = null;
        _remainingDistance = 0;
        _remainingDuration = 0;
        _distanceFromRoute = 0;
        _distanceToDestination = 0;
        _setState(NavigationState.loading);

        await _locationSubscription?.cancel();
        _locationSubscription = null;

        if (_isDisposed) return;

        // 1. Get current GPS location
        final location = await getCurrentLocation();

        if (_isDisposed) return;

        _currentLocation = location;

        // 2. Get route from OSRM
        final navigationRoute = await getNavigationRoute(
          origin: location,
          destination: destination,
        );

        if (_isDisposed) return;

        // 3. Save route
        _route = navigationRoute;

        _remainingDistance = navigationRoute.distance;

        _remainingDuration = navigationRoute.duration;

        _updateNavigationProgress(location);

        _setState(NavigationState.ready);
      });
    }

    // START GUIDANCE
    Future<void> startGuidance() {
      if (!isReady && _state != NavigationState.stopped) {
        return Future.value();
      }

      return _runOperation(() async {
        _resetReroutingState();
        _resetArrivalState();
        _progress = null;
        _instruction = null;
        _errorMessage = null;
        _setState(NavigationState.loading);

        await _locationSubscription?.cancel();

        _locationSubscription = null;

        if (_isDisposed) return;

        _locationSubscription = watchLocation().listen(
          _onLocationChanged,
          onError: (Object error) {
            _handleError(error);
          },
          onDone: () {
            if (isNavigating) {
              _setState(NavigationState.stopped);
            }
          },
          cancelOnError: true,
        );

        _setState(NavigationState.navigating);
      });
    }

    // UPDATE CURRENT LOCATION
    void _onLocationChanged(NavigationLocation location) {
      if (_isDisposed || !isNavigating) {
        return;
      }

      _currentLocation = location;

      // 1. Cập nhật tiến độ.
      _updateNavigationProgress(location);

      // 2. Kiểm tra sai đường trước.
      _checkOffRoute(location);

      // 3. Chỉ kiểm tra đến nơi khi không lệch tuyến.
      if (_checkArrival(location)) {
        unawaited(_completeArrival());
        return;
      }

      // 4. Cập nhật giao diện.
      notifyListeners();

      // 5. Tìm lại tuyến nếu cần.
      if (_canReroute()) {
        unawaited(_reroute());
      }
    }

    void _resetArrivalState() {
      _arrivalCount = 0;
      _arrivalResult = null;
    }

    void _resetReroutingState() {
      _navigationSessionId++;

      _isRerouting = false;
      _lastRerouteTime = null;
      _rerouteErrorMessage = null;

      _offRouteCount = 0;
      _offRouteResult = null;
    }

    // STOP GUIDANCE
    Future<void> stopGuidance() {
      if (!isNavigating && !isArrived) {
        return Future.value();
      }

      return _runOperation(() async {
        _resetReroutingState();
        _resetArrivalState();
        _setState(NavigationState.loading);

        final subscription = _locationSubscription;
        _locationSubscription = null;

        await subscription?.cancel();
        _setState(NavigationState.stopped);
      });
    }

    // RELEASE RESOURCES
    @override
    void dispose() {
      _isDisposed = true;
      _navigationSessionId++;
      final subscription = _locationSubscription;

      _locationSubscription = null;

      if (subscription != null) {
        unawaited(
          subscription.cancel().catchError((Object error, StackTrace stackTrace) {
            debugPrint('GPS cleanup error: $error');
          }),
        );
      }

      super.dispose();
    }
  }
