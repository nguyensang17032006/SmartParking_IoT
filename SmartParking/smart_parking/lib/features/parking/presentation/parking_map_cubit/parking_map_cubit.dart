import 'package:bloc/bloc.dart';

import '../../domain/entities/parking_map_layout.dart';
import '../../domain/entities/parking_slot.dart';
import '../../domain/usecases/build_parking_route.dart';
import 'parking_map_state.dart';

/// Selection/filter state of the map. Does not fetch sensor data.
class ParkingMapCubit extends Cubit<ParkingMapState> {
  final BuildParkingRoute buildParkingRoute;

  ParkingMapCubit({
    required List<ParkingSlot> slots,
    required ParkingMapLayout layout,
    Set<String>? highlightedCodes,
    this.buildParkingRoute = const BuildParkingRoute(),
  }) : super(
         ParkingMapState(
           slots: slots,
           layout: layout,
           highlightedCodes: highlightedCodes,
         ),
       );

  ParkingMapState _nextState({
    required List<ParkingSlot> slots,
    required ParkingMapLayout layout,
    Set<String>? highlightedCodes,
    String? selectedId,
  }) {
    final next = ParkingMapState(
      slots: slots,
      layout: layout,
      highlightedCodes: highlightedCodes,
    );
    for (final slot in slots) {
      if (slot.id != selectedId || !next.isHighlighted(slot.code)) continue;
      final route = buildParkingRoute(
        layout: layout,
        slotCode: slot.code,
        occupied: slot.occupied,
      );
      if (route != null) {
        return ParkingMapState(
          slots: slots,
          layout: layout,
          highlightedCodes: highlightedCodes,
          selectedId: slot.id,
          route: route,
        );
      }
    }
    return next;
  }

  void selectSlot(String id) {
    final next = _nextState(
      slots: state.slots,
      layout: state.layout,
      highlightedCodes: state.highlightedCodes,
      selectedId: id,
    );
    // Ignore invalid taps; keep an existing valid selection.
    if (next.route != null) emit(next);
  }

  void clearSelection() {
    emit(
      ParkingMapState(
        slots: state.slots,
        layout: state.layout,
        highlightedCodes: state.highlightedCodes,
      ),
    );
  }

  void updateData({
    required List<ParkingSlot> slots,
    required ParkingMapLayout layout,
    Set<String>? highlightedCodes,
  }) {
    // A sensor/filter/layout update invalidates a target that is no longer valid.
    emit(
      _nextState(
        slots: slots,
        layout: layout,
        highlightedCodes: highlightedCodes,
        selectedId: state.selectedId,
      ),
    );
  }
}
