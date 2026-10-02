import 'package:flutter/material.dart';

import '../../parking_map_cubit/parking_map_state.dart';
import 'parking_map_header.dart';
import 'parking_map_route_summary.dart';
import 'parking_map_viewport.dart';

class ParkingMapView extends StatelessWidget {
  final ParkingMapState state;
  final ValueChanged<String> onSelectSlot;
  final VoidCallback onClear;
  const ParkingMapView({
    super.key,
    required this.state,
    required this.onSelectSlot,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final unplaced = state.unplacedCodes;
    return Material(
      key: const ValueKey('horizontal-parking-map-v2'),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE4E9F1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ParkingMapHeader(),
            const SizedBox(height: 14),
            ParkingMapViewport(state: state, onSelectSlot: onSelectSlot),
            const SizedBox(height: 12),
            ParkingMapRouteSummary(route: state.route, onClear: onClear),
            if (unplaced.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Ô chưa có vị trí trên sơ đồ: ${unplaced.join(', ')}.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6F7C90)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
