import '../../domain/entities/navigation_destination.dart';
import '../../domain/entities/navigation_location.dart';
import '../../domain/entities/navigation_route.dart';
import '../../domain/repositories/navigation_repository.dart';

import '../datasources/location_data_source.dart';
import '../datasources/routing_remote_data_source.dart';

class NavigationRepositoryImpl
    implements NavigationRepository {
  final LocationDataSource locationDataSource;

  final RoutingRemoteDataSource routingDataSource;

  const NavigationRepositoryImpl({
    required this.locationDataSource,
    required this.routingDataSource,
  });

  @override
  Future<NavigationLocation> getCurrentLocation() {
    return locationDataSource.getCurrentLocation();
  }

  @override
  Future<NavigationRoute> getNavigationRoute({
    required NavigationLocation origin,
    required NavigationDestination destination,
  }) {
    return routingDataSource.getNavigationRoute(
      originLatitude: origin.latitude,
      originLongitude: origin.longitude,
      destinationLatitude: destination.latitude,
      destinationLongitude: destination.longitude,
    );
  }

  @override
  Stream<NavigationLocation> watchLocation() {
    return locationDataSource.watchLocation();
  }
}