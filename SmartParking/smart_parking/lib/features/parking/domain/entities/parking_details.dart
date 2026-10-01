class ParkingBooking {
  final String id;
  final String code;
  final String status;
  final DateTime expiresAt;
  const ParkingBooking(this.id, this.code, this.status, this.expiresAt);
  bool activeAt(DateTime now) => status == 'active' && expiresAt.isAfter(now);
}

class SavedParkingPosition {
  final String code;
  final String note;
  final String source;
  final DateTime savedAt;
  const SavedParkingPosition(this.code, this.note, this.source, this.savedAt);
}

class ParkingVisit {
  final String code;
  final DateTime startedAt;
  const ParkingVisit(this.code, this.startedAt);
}

class MyParking {
  final List<ParkingBooking> bookings;
  final SavedParkingPosition? position;
  final ParkingVisit? visit;
  const MyParking({this.bookings = const [], this.position, this.visit});
}

class PeakHour {
  final int hour;
  final double minutes;
  const PeakHour(this.hour, this.minutes);
}

class ParkingReport {
  final double? utilization;
  final double coverage;
  final double? averageMinutes;
  final List<PeakHour> peaks;
  const ParkingReport(
    this.utilization,
    this.coverage,
    this.averageMinutes,
    this.peaks,
  );
}
