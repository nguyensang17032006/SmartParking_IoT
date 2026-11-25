import '../entities/navigation_location.dart';
import '../repositories/navigation_repository.dart';

class WatchLocation {
  final NavigationRepository repository;

  const WatchLocation(this.repository);

  Stream<NavigationLocation> call() {
    return repository.watchLocation();
  }
}