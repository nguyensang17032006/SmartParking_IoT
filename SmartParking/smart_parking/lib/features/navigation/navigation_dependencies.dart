import 'package:http/http.dart' as http;

import 'data/datasources/location_data_source.dart';
import 'data/datasources/routing_remote_data_source.dart';
import 'data/repositories/navigation_repository_impl.dart';

import 'domain/usecases/get_current_location.dart';
import 'domain/usecases/get_navigation_route.dart';
import 'domain/usecases/watch_location.dart';

import 'presentation/viewmodels/navigation_view_model.dart';
import 'domain/services/navigation_distance_service.dart';
import 'domain/services/navigation_progress_service.dart';
import 'domain/services/navigation_instruction_service.dart';
import 'domain/services/off_route_detection_service.dart';
import 'domain/services/arrival_detection_service.dart';

class NavigationDependencies {
  final http.Client _httpClient;

  final GetCurrentLocation getCurrentLocation;
  final GetNavigationRoute getNavigationRoute;
  final WatchLocation watchLocation;

  const NavigationDependencies._({
    required http.Client httpClient,
    required this.getCurrentLocation,
    required this.getNavigationRoute,
    required this.watchLocation,
  }) : _httpClient = httpClient;

  factory NavigationDependencies.create() {
    // 1. HTTP Client
    final httpClient = http.Client();

    // 2. Data Sources
    const locationDataSource = LocationDataSourceImpl();

    final routingDataSource = RoutingRemoteDataSourceImpl(client: httpClient);

    // 3. Repository
    final repository = NavigationRepositoryImpl(
      locationDataSource: locationDataSource,
      routingDataSource: routingDataSource,
    );

    // 4. Use Cases
    return NavigationDependencies._(
      httpClient: httpClient,
      getCurrentLocation: GetCurrentLocation(repository),
      getNavigationRoute: GetNavigationRoute(repository),
      watchLocation: WatchLocation(repository),
    );
  }

  // 5. Create ViewModel
  NavigationViewModel createViewModel() {
    const distanceService = NavigationDistanceService();

    const progressService = NavigationProgressService(
      distanceService: distanceService,
    );

    const instructionService = NavigationInstructionService();

    const offRouteService = OffRouteDetectionService();

    const arrivalService = ArrivalDetectionService();

    return NavigationViewModel(
      getCurrentLocation: getCurrentLocation,
      getNavigationRoute: getNavigationRoute,
      watchLocation: watchLocation,
      distanceService: distanceService,
      progressService: progressService,
      instructionService: instructionService,
      offRouteService: offRouteService,
      arrivalService: arrivalService,
    );
  }

  // 6. Release Resources
  void dispose() {
    _httpClient.close();
  }
}
