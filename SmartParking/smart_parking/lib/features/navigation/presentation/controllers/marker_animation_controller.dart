import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/entities/navigation_location.dart';
import '../../domain/services/route_geometry_service.dart';

class MarkerAnimationController extends ChangeNotifier {
  final RouteGeometryService _geometryService = const RouteGeometryService();

  late final AnimationController _controller;

  LatLng? _position;
  LatLng? _start;
  LatLng? _target;

  List<NavigationLocation> _routePoints = [];
  List<double> _cumulativeDistances = [];

  double? _traveledDistance;
  double _startDistance = 0;
  double _targetDistance = 0;

  bool _animateAlongRoute = false;

  MarkerAnimationController({required TickerProvider vsync}) {
    _controller = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 800),
    );

    _controller.addListener(_onAnimationTick);
  }

  LatLng? get position => _position;

  double? get traveledDistance => _traveledDistance;

  // Chỉ gọi khi tuyến đường thay đổi.
  void setRoute(List<NavigationLocation> points) {
    _controller.stop();

    _routePoints = List.unmodifiable(points);

    _cumulativeDistances = _geometryService.buildCumulativeDistances(
      _routePoints,
    );

    _traveledDistance = null;
    _animateAlongRoute = false;

    _start = null;
    _target = null;
  }

  void _onAnimationTick() {
    final t = _controller.value;

    if (_animateAlongRoute) {
      final distance = _startDistance + (_targetDistance - _startDistance) * t;

      _updateRoutePosition(distance);

      notifyListeners();
      return;
    }

    final start = _start;
    final target = _target;

    if (start == null || target == null) return;

    _position = LatLng(
      start.latitude + (target.latitude - start.latitude) * t,
      start.longitude + (target.longitude - start.longitude) * t,
    );

    notifyListeners();
  }

  void _updateRoutePosition(double distance) {
    _traveledDistance = distance;

    final location = _geometryService.positionAtDistance(
      points: _routePoints,
      cumulativeDistances: _cumulativeDistances,
      traveledDistance: distance,
    );

    _position = LatLng(location.latitude, location.longitude);
  }

  // Di chuyển marker dọc theo tuyến đường.
  void animateAlongRoute(double distance) {
    if (_routePoints.length < 2) return;

    final targetDistance = distance
        .clamp(0.0, _cumulativeDistances.last)
        .toDouble();

    final currentDistance = _traveledDistance;

    if (currentDistance == null) {
      _controller.stop();

      _animateAlongRoute = true;
      _targetDistance = targetDistance;

      _updateRoutePosition(targetDistance);

      notifyListeners();
      return;
    }

    if (_animateAlongRoute && _targetDistance == targetDistance) {
      return;
    }

    _controller.stop();

    _animateAlongRoute = true;

    _startDistance = currentDistance;
    _targetDistance = targetDistance;

    _controller.forward(from: 0);
  }

  // Lấy Polyline còn lại theo vị trí animation.
  List<LatLng> get remainingRoutePoints {
    if (_routePoints.isEmpty) return [];

    final distance = _traveledDistance;

    final points = distance == null
        ? _routePoints
        : _geometryService.remainingRoute(
            points: _routePoints,
            cumulativeDistances: _cumulativeDistances,
            traveledDistance: distance,
          );

    return points.map((point) {
      return LatLng(point.latitude, point.longitude);
    }).toList();
  }

  // Đặt marker tại tọa độ GPS thực tế.
  void setPosition(LatLng point) {
    _controller.stop();

    _animateAlongRoute = false;
    _traveledDistance = null;

    _start = point;
    _target = point;
    _position = point;

    notifyListeners();
  }

  // Animation GPS thông thường khi lệch tuyến.
  void animateTo(LatLng target) {
    final current = _position;

    if (current == null) {
      setPosition(target);
      return;
    }

    if (!_animateAlongRoute &&
        _target?.latitude == target.latitude &&
        _target?.longitude == target.longitude) {
      return;
    }

    _controller.stop();

    _animateAlongRoute = false;

    _start = current;
    _target = target;

    _controller.forward(from: 0);
  }

  void stop() {
    _controller.stop();
  }

  @override
  void dispose() {
    _controller.removeListener(_onAnimationTick);
    _controller.dispose();

    super.dispose();
  }
}
