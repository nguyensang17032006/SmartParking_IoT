import '../entities/navigation_location.dart';
import '../repositories/navigation_repository.dart';

class GetCurrentLocation {
  final NavigationRepository repository;

  const GetCurrentLocation(this.repository);

  Future<NavigationLocation> call() {
    return repository.getCurrentLocation();
  }
}