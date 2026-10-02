import '../../domain/entities/parking_map_layout.dart';
import '../../domain/entities/parking_route.dart';
import '../../domain/entities/parking_slot.dart';

class ParkingMapState {
  final List<ParkingSlot> slots;
  final ParkingMapLayout layout;
  final Set<String>? highlightedCodes;
  final String? selectedId;
  final ParkingRoute? route;

  ParkingMapState({
    required List<ParkingSlot> slots,
    required this.layout,
    Set<String>? highlightedCodes,
    this.selectedId,
    this.route,
  }) : slots = List.unmodifiable(slots),
       highlightedCodes = highlightedCodes == null
           ? null
           : Set.unmodifiable(highlightedCodes);

  bool isHighlighted(String code) =>
      highlightedCodes == null || highlightedCodes!.contains(code);

  Map<String, ParkingSlot> get slotsByCode => {
    for (final slot in slots) slot.code: slot,
  };

  List<String> get unplacedCodes =>
      slots
          .where((slot) => layout.locationOf(slot.code) == null)
          .map((slot) => slot.code)
          .toList()
        ..sort();
}
