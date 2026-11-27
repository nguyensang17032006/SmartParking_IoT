import 'package:flutter/material.dart' hide NavigationDestination;
import '../../domain/entities/navigation_route.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/navigation_instruction_card.dart';
import 'package:smart_parking/core/theme/app_colors.dart';
import '../widgets/navigation_rerouting_card.dart';
import '../../domain/entities/navigation_destination.dart';
import '../../navigation_dependencies.dart';
import '../viewmodels/navigation_view_model.dart';
import '../widgets/arrival_dialog.dart';
import '../controllers/marker_animation_controller.dart';

class NavigationPage extends StatefulWidget {
  final NavigationDestination destination;

  const NavigationPage({super.key, required this.destination});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage>
    with SingleTickerProviderStateMixin {
  late final NavigationDependencies dependencies;
  late final MarkerAnimationController _markerAnimationController;
  late final NavigationViewModel viewModel;
  NavigationRoute? _animationRoute;
  final MapController _mapController = MapController();
  bool _hasShownArrivalDialog = false;
  bool _isMapReady = false;
  static const double _navigationZoom = 17.0;
  bool _followUser = true;

  // 1. INITIALIZE
  @override
  void initState() {
    super.initState();

    dependencies = NavigationDependencies.create();

    viewModel = dependencies.createViewModel();

    _markerAnimationController = MarkerAnimationController(vsync: this);

    _markerAnimationController.addListener(_onMarkerAnimationChanged);

    viewModel.addListener(_onStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      viewModel.prepareNavigation(widget.destination);
    });
  }

  void _onMarkerAnimationChanged() {
    if (!mounted) return;

    setState(() {});

    // Camera chỉ bám theo người dùng
    // khi chế độ follow đang bật.
    if (!_isMapReady || !_followUser || !viewModel.isNavigating) {
      return;
    }

    _moveToCurrentLocation();
  }

  void _updateMarkerPosition() {
    final location = viewModel.currentLocation;
    final route = viewModel.route;
    final progress = viewModel.progress;

    // Cập nhật geometry khi tuyến đường thay đổi.
    if (!identical(_animationRoute, route)) {
      _animationRoute = route;

      _markerAnimationController.setRoute(route?.points ?? []);
    }

    if (location == null) return;

    final rawPoint = LatLng(location.latitude, location.longitude);

    if (!viewModel.isNavigating) {
      _markerAnimationController.setPosition(rawPoint);

      return;
    }

    // Chỉ bám tuyến khi GPS đủ tin cậy.
    final canSnapToRoute =
        route != null &&
        route.points.length >= 2 &&
        progress != null &&
        !viewModel.isOffRoute &&
        !viewModel.isRerouting &&
        location.accuracy.isFinite &&
        location.accuracy > 0 &&
        location.accuracy <= 30 &&
        progress.distanceFromRoute <= 25;

    if (canSnapToRoute) {
      _markerAnimationController.animateAlongRoute(progress.traveledDistance);
    } else {
      // Không ép marker nằm trên đường khi đi sai.
      _markerAnimationController.animateTo(rawPoint);
    }
  }

  // 2. LISTEN TO VIEWMODEL
  void _onStateChanged() {
    if (!mounted) return;

    if (viewModel.hasError || viewModel.route == null) {
      _isMapReady = false;
    }

    _updateMarkerPosition();

    setState(() {});

    // Kiểm tra người dùng đã đến nơi.
    if (viewModel.isArrived) {
      if (!_hasShownArrivalDialog) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          _showArrivalDialog();
        });
      }
    }
  }

  // 3. CURRENT LOCATION
  LatLng? get _currentPoint {
    final location = viewModel.currentLocation;

    if (location == null) return null;

    return _markerAnimationController.position ??
        LatLng(location.latitude, location.longitude);
  }

  // 4. DESTINATION
  LatLng get _destinationPoint {
    return LatLng(widget.destination.latitude, widget.destination.longitude);
  }

  // 5. ROUTE POINTS
  List<LatLng> get _routePoints {
    final route = viewModel.route;

    if (route == null) return [];

    if (viewModel.isArrived) {
      return [];
    }

    if (viewModel.isNavigating) {
      return _markerAnimationController.remainingRoutePoints;
    }

    // Khi chưa bắt đầu chỉ đường,
    // hiển thị toàn bộ tuyến.
    return route.points.map((point) {
      return LatLng(point.latitude, point.longitude);
    }).toList();
  }

  // 6. FIT ENTIRE ROUTE
  void _fitRoute() {
    if (!mounted ||
        !_isMapReady ||
        viewModel.hasError ||
        viewModel.route == null) {
      return;
    }

    final points = [..._routePoints, ?_currentPoint, _destinationPoint];

    if (points.length < 2) return;

    // Tắt bám theo marker để xem tổng quan.
    _followUser = false;

    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(60),
        maxZoom: 17,
      ),
    );
  }

  // 7. FOLLOW CURRENT LOCATION
  void _moveToCurrentLocation({bool resetZoom = false}) {
    final point = _currentPoint;

    if (!mounted ||
        !_isMapReady ||
        point == null ||
        viewModel.hasError ||
        viewModel.route == null) {
      return;
    }

    final zoom = resetZoom ? _navigationZoom : _mapController.camera.zoom;

    _mapController.move(point, zoom);
  }

  // 8. START OR STOP GUIDANCE
  Future<void> _toggleGuidance() async {
    if (viewModel.isNavigating) {
      _followUser = false;

      await viewModel.stopGuidance();

      if (!mounted) return;

      _markerAnimationController.stop();

      _fitRoute();
    } else {
      _followUser = true;

      await viewModel.startGuidance();

      if (!mounted) return;

      if (viewModel.isNavigating) {
        _moveToCurrentLocation(resetZoom: true);
      }
    }
  }

  // 9. FORMAT DISTANCE
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  // 10. FORMAT DURATION
  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).ceil();

    if (minutes < 60) {
      return '$minutes phút';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    return '$hours giờ $remainingMinutes phút';
  }

  Future<void> _showArrivalDialog() async {
    if (!mounted || _hasShownArrivalDialog || !viewModel.isArrived) {
      return;
    }

    _hasShownArrivalDialog = true;

    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ArrivalDialog(
          destinationName: widget.destination.name,
          onCompleted: () {
            Navigator.of(dialogContext).pop(true);
          },
        );
      },
    );

    if (!mounted) return;

    if (completed == true) {
      Navigator.of(context).pop();
    }
  }

  // 11. DISPOSE
  @override
  void dispose() {
    viewModel.removeListener(_onStateChanged);

    _markerAnimationController.removeListener(_onMarkerAnimationChanged);

    _markerAnimationController.dispose();

    viewModel.dispose();

    dependencies.dispose();

    _mapController.dispose();

    super.dispose();
  }

  // 12. BUILD UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,

        title: Text(
          widget.destination.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),

      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (viewModel.hasError) {
      return _buildError();
    }

    if (viewModel.route == null || _currentPoint == null) {
      return _buildLoading();
    }

    return Column(
      children: [
        Expanded(child: _buildMap()),

        _buildNavigationControls(),
      ],
    );
  }

  // 13. LOADING UI
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),

          SizedBox(height: 16),

          Text('Đang tìm tuyến đường...'),
        ],
      ),
    );
  }

  // 14. ERROR UI
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),

            const SizedBox(height: 16),

            Text(
              viewModel.errorMessage ?? 'Không thể tải tuyến đường.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                _isMapReady = false;

                viewModel.prepareNavigation(widget.destination);
              },
              child: const Text('Thử lại'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }

  // 15. BUILD MAP
  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,

          options: MapOptions(
            initialCenter: _currentPoint!,
            initialZoom: 15,

            minZoom: 3,
            maxZoom: 19,

            onMapReady: () {
              _isMapReady = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                _fitRoute();
              });
            },

            onPositionChanged: (camera, hasGesture) {
              if (hasGesture) {
                _followUser = false;
              }
            },
          ),

          children: [
            // OpenStreetMap tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

              userAgentPackageName: 'com.example.smart_parking',

              maxNativeZoom: 19,
            ),

            // Route
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  strokeWidth: 5,
                  color: Colors.blue,
                  borderStrokeWidth: 2,
                  borderColor: Colors.white,
                ),
              ],
            ),

            // Markers
            MarkerLayer(
              markers: [
                // Current GPS position
                Marker(
                  point: _currentPoint!,
                  width: 40,
                  height: 40,

                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),

                    child: Center(
                      child: Container(
                        width: 20,
                        height: 20,

                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,

                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ),
                ),

                // Destination
                Marker(
                  point: _destinationPoint,
                  width: 45,
                  height: 45,
                  alignment: Alignment.topCenter,

                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 45,
                  ),
                ),
              ],
            ),

            // Map attribution
            const SimpleAttributionWidget(
              source: Text('© OpenStreetMap contributors'),
            ),
          ],
        ),

        // Recenter button
        Positioned(
          right: 16,
          bottom: 40,

          child: FloatingActionButton.small(
            heroTag: 'navigation_location',

            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,

            onPressed: () {
              _followUser = true;

              _moveToCurrentLocation(resetZoom: true);
            },

            child: const Icon(Icons.my_location),
          ),
        ),

        // Fit route button
        Positioned(
          right: 16,
          bottom: 92,

          child: FloatingActionButton.small(
            heroTag: 'navigation_route',

            backgroundColor: Colors.white,
            foregroundColor: AppColors.navy,

            onPressed: () {
              _followUser = false;

              _fitRoute();
            },

            child: const Icon(Icons.route),
          ),
        ),
        if (viewModel.isNavigating)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: viewModel.isRerouting
                ? const NavigationReroutingCard()
                : viewModel.rerouteErrorMessage != null && viewModel.isOffRoute
                ? NavigationReroutingCard(
                    errorMessage: viewModel.rerouteErrorMessage,
                  )
                : viewModel.instruction != null
                ? NavigationInstructionCard(instruction: viewModel.instruction!)
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  // 16. NAVIGATION CONTROLS
  Widget _buildNavigationControls() {
    return SafeArea(
      top: false,

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      _formatDuration(viewModel.remainingDuration),

                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),

                    const Text(
                      'Thời gian còn lại',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,

                  children: [
                    Text(
                      _formatDistance(viewModel.remainingDistance),

                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),

                    const Text(
                      'Khoảng cách còn lại',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,

              child: ElevatedButton.icon(
                onPressed: viewModel.isLoading || viewModel.isArrived
                    ? null
                    : _toggleGuidance,

                icon: Icon(
                  viewModel.isNavigating
                      ? Icons.stop_circle_outlined
                      : Icons.navigation_rounded,
                ),

                label: Text(
                  viewModel.isArrived
                      ? 'Đã đến nơi'
                      : viewModel.isLoading
                      ? 'Đang xử lý...'
                      : viewModel.isNavigating
                      ? 'Dừng chỉ đường'
                      : 'Bắt đầu chỉ đường',
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
