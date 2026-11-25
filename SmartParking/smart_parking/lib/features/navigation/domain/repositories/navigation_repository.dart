import '../entities/navigation_destination.dart';
import '../entities/navigation_location.dart';
import '../entities/navigation_route.dart';

abstract class NavigationRepository {
  Future<NavigationLocation> getCurrentLocation();

  Future<NavigationRoute> getNavigationRoute({
    required NavigationLocation origin,
    required NavigationDestination destination,
  });

  Stream<NavigationLocation> watchLocation();
}