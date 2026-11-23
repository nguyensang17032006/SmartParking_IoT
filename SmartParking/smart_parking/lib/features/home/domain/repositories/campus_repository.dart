import '../entities/campus.dart';

abstract class CampusRepository {
  Future<List<Campus>> getCampuses();
}