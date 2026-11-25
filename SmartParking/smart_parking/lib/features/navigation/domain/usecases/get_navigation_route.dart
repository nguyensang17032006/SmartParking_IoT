import '../entities/navigation_destination.dart';
import '../entities/navigation_location.dart';
import '../entities/navigation_route.dart';
import '../repositories/navigation_repository.dart';

class GetNavigationRoute {
  final NavigationRepository repository;

  const GetNavigationRoute(this.repository);

  Future<NavigationRoute> call({
    required NavigationLocation origin,
    required NavigationDestination destination,
  }) {
    return repository.getNavigationRoute(
      origin: origin,
      destination: destination,
    );
  }
}