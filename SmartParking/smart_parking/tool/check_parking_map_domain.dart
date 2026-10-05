import '../lib/features/parking/domain/entities/parking_map_layout.dart';
import '../lib/features/parking/domain/entities/parking_overview.dart';
import '../lib/features/parking/domain/usecases/build_parking_route.dart';

void main() {
  var count = 0;
  void check(String scenario, bool condition) {
    if (!condition) throw StateError(scenario);
    count++;
  }

  const build = BuildParkingRoute();
  final layout = ParkingMapLayout(
    topRowCodes: ['A01', 'A02', 'A03'],
    bottomRowCodes: ['B01', 'B02', 'B03'],
  );

  final top = build(layout: layout, slotCode: 'A03', occupied: false);
  check(
    'Route to the third top bay',
    top?.destination.row == ParkingMapRow.top && top?.destination.column == 2,
  );
  final bottom = build(layout: layout, slotCode: 'B01', occupied: false);
  check(
    'Route to the first bottom bay',
    bottom?.destination.row == ParkingMapRow.bottom &&
        bottom?.destination.column == 0,
  );
  check(
    'An occupied bay is rejected',
    build(layout: layout, slotCode: 'B02', occupied: true) == null,
  );
  check(
    'A bay outside the physical layout is rejected',
    build(layout: layout, slotCode: 'C01', occupied: false) == null,
  );

  final reordered = ParkingMapLayout(
    topRowCodes: ['A03', 'A01'],
    bottomRowCodes: ['B02'],
  );
  check(
    'Explicit physical order wins over the number in a code',
    build(
          layout: reordered,
          slotCode: 'A01',
          occupied: false,
        )?.destination.column ==
        1,
  );
  check(
    'Different row lengths keep their own bay positions',
    build(
              layout: reordered,
              slotCode: 'B02',
              occupied: false,
            )?.destination.column ==
            0 &&
        reordered.columnCount == 2,
  );
  final mutable = ['A01'];
  final snapshot = ParkingMapLayout(topRowCodes: mutable, bottomRowCodes: []);
  mutable[0] = 'A99';
  check(
    'Caller mutations cannot silently change the physical layout',
    snapshot.locationOf('A01') != null && snapshot.locationOf('A99') == null,
  );

  var rejectedDuplicate = false;
  try {
    ParkingMapLayout(topRowCodes: ['A01'], bottomRowCodes: ['A01']);
  } on ArgumentError {
    rejectedDuplicate = true;
  }
  check('Duplicate codes cannot give an ambiguous route', rejectedDuplicate);
  var rejectedBlank = false;
  try {
    ParkingMapLayout(topRowCodes: [' '], bottomRowCodes: []);
  } on ArgumentError {
    rejectedBlank = true;
  }
  check('Blank bay codes are rejected', rejectedBlank);
  final empty = ParkingMapLayout(topRowCodes: [], bottomRowCodes: []);
  check(
    'An empty layout cannot produce a target',
    build(layout: empty, slotCode: 'A01', occupied: false) == null &&
        empty.columnCount == 1,
  );

  final noSlots = ParkingOverview.fromOccupancy([]);
  check(
    'No data is not a full car park, and avoids division by zero',
    noSlots.totalCount == 0 && noSlots.occupancyRate == 0 && !noSlots.isFull,
  );
  final mixed = ParkingOverview.fromOccupancy([false, true, false, true]);
  check(
    'Real sensor occupancy is aggregated into consistent totals',
    mixed.availableCount == 2 &&
        mixed.occupiedCount == 2 &&
        mixed.totalCount == 4 &&
        mixed.occupancyRate == 0.5,
  );
  final full = ParkingOverview.fromOccupancy([true, true]);
  check(
    'A full car park has no free bays and 100 percent occupancy',
    full.isFull && full.availableCount == 0 && full.occupancyRate == 1,
  );
  final available = ParkingOverview.fromOccupancy([false, false]);
  check(
    'An empty-of-cars car park remains available',
    !available.isFull &&
        available.availableCount == 2 &&
        available.occupancyRate == 0,
  );
  final readings = [true, false];
  final snapshotOverview = ParkingOverview.fromOccupancy(readings);
  readings.clear();
  check(
    'Sensor input mutations do not alter an already rendered snapshot',
    snapshotOverview.totalCount == 2 && snapshotOverview.occupiedCount == 1,
  );

  print('Passed $count parking domain checks.');
}
