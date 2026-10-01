import '../../domain/entities/parking_slot.dart';
import '../../domain/entities/parking_details.dart';
import '../../domain/repository/parking_repository.dart';
import '../datasource/parking_remote_datasource.dart';

class ParkingRepositoryImpl implements ParkingRepository {
  final ParkingRemoteDataSource remoteDataSource;
  ParkingRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<ParkingSlot>> watchParkingSlots() =>
      remoteDataSource.watchParkingSlots();

  @override
  Future<MyParking> getMyParking() async {
    final data = await remoteDataSource.getMyParking();
    final position = data['position'] as Map<String, dynamic>?;
    final visit = data['visit'] as Map<String, dynamic>?;
    return MyParking(
      bookings: (data['bookings'] as List)
          .map(
            (row) => ParkingBooking(
              row['id'] as String,
              row['slot_code'] as String,
              row['status'] as String,
              DateTime.parse(row['expires_at'] as String).toUtc(),
            ),
          )
          .toList(),
      position: position == null
          ? null
          : SavedParkingPosition(
              position['slot_code'] as String,
              position['note'] as String,
              position['source'] as String,
              DateTime.parse(position['saved_at'] as String),
            ),
      visit: visit == null
          ? null
          : ParkingVisit(
              visit['slot_code'] as String,
              DateTime.parse(visit['started_at'] as String),
            ),
    );
  }

  @override
  Future<void> reserve(String code, int minutes) => remoteDataSource.mutate(
    'reserve_slot',
    {'p_code': code, 'p_minutes': minutes},
  );
  @override
  Future<void> cancel(String id) =>
      remoteDataSource.mutate('cancel_reservation', {'p_id': id});
  @override
  Future<void> confirmParked(String code) =>
      remoteDataSource.mutate('confirm_parked', {'p_code': code});
  @override
  Future<void> savePosition(String code, String note) => remoteDataSource
      .mutate('save_parking_position', {'p_code': code, 'p_note': note});

  @override
  Future<ParkingReport> getReport() async {
    final data = await remoteDataSource.getReport();
    return ParkingReport(
      (data['utilization_percent'] as num?)?.toDouble(),
      (data['coverage_percent'] as num?)?.toDouble() ?? 0,
      (data['average_minutes'] as num?)?.toDouble(),
      (data['peak_hours'] as List)
          .map(
            (row) => PeakHour(
              (row['hour'] as num).toInt(),
              (row['occupied_minutes'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }
}
