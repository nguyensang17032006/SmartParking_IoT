import '../../domain/entities/campus.dart';
import '../../domain/repositories/campus_repository.dart';
import '../datasources/campus_remote_data_source.dart';

class CampusRepositoryImpl implements CampusRepository {
  final CampusRemoteDataSource remoteDataSource;

  CampusRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Campus>> getCampuses() {
    return remoteDataSource.getCampuses();
  }
}