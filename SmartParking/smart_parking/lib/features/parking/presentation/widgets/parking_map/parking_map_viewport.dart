import 'package:flutter/material.dart';

import '../../../domain/entities/parking_map_layout.dart';
import '../../painters/horizontal_parking_lane_painter.dart';
import '../../parking_map_cubit/parking_map_state.dart';
import 'parking_bay_tile.dart';
import 'parking_map_gate.dart';
import 'parking_map_geometry.dart';

/// Composes the road, bay widgets and gate labels on the same canvas.
class ParkingMapViewport extends StatelessWidget {
  final ParkingMapState state;
  final ValueChanged<String> onSelectSlot;
  const ParkingMapViewport({
    super.key,
    required this.state,
    required this.onSelectSlot,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [state.layout.topRowCodes, state.layout.bottomRowCodes];
    final byCode = state.slotsByCode;
    final size = ParkingMapGeometry.canvasSize(state.layout.columnCount);

    return AspectRatio(
      aspectRatio: size.width / size.height,
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 3,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: HorizontalParkingLanePainter(
                      ParkingMapGeometry.destinationFor(state.route),
                    ),
                  ),
                ),
                for (var row = 0; row < rows.length; row++)
                  for (var column = 0; column < rows[row].length; column++)
                    Positioned.fromRect(
                      rect: ParkingMapGeometry.bayRect(
                        row == 0 ? ParkingMapRow.top : ParkingMapRow.bottom,
                        column,
                      ),
                      child: ParkingBayTile(
                        code: rows[row][column],
                        slot: byCode[rows[row][column]],
                        selected: state.route?.slotCode == rows[row][column],
                        highlighted: state.isHighlighted(rows[row][column]),
                        onTap: () {
                          final slot = byCode[rows[row][column]];
                          if (slot != null) onSelectSlot(slot.id);
                        },
                      ),
                    ),
                const Positioned(
                  left: 0,
                  top: ParkingMapGeometry.roadTop,
                  width: 66,
                  height:
                      ParkingMapGeometry.roadBottom -
                      ParkingMapGeometry.roadTop,
                  child: ParkingMapGate(
                    label: 'CỔNG VÀO',
                    icon: Icons.login_rounded,
                  ),
                ),
                const Positioned(
                  right: 0,
                  top: ParkingMapGeometry.roadTop,
                  width: 66,
                  height:
                      ParkingMapGeometry.roadBottom -
                      ParkingMapGeometry.roadTop,
                  child: ParkingMapGate(
                    label: 'CỔNG RA',
                    icon: Icons.logout_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
