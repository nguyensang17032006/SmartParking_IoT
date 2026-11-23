import '../entities/campus.dart';
import '../repositories/campus_repository.dart';

class GetCampuses {
  final CampusRepository repository;

  GetCampuses(this.repository);

  Future<List<Campus>> call() {
    return repository.getCampuses();
  }
}