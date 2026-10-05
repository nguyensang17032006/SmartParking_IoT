import 'package:flutter/material.dart';

import '../../../../domain/entities/parking_map_layout.dart';
import '../../../../domain/entities/parking_route.dart';

/// Screen geometry belongs to Presentation, never Domain or Data.
class ParkingMapGeometry {
  static const height = 336.0;
  static const bayLeft = 112.0;
  static const step = 108.0;
  static const bayWidth = 88.0;
  static const bayHeight = 102.0;
  static const topBay = 22.0;
  static const bottomBay = 212.0;
  static const roadTop = 134.0;
  static const roadBottom = 202.0;
  static const roadCenter = 168.0;
  static const gateInset = 72.0;

  static Size canvasSize(int columns) => Size(200 + columns * step, height);

  static Rect bayRect(ParkingMapRow row, int column) => Rect.fromLTWH(
    bayLeft + column * step,
    row == ParkingMapRow.top ? topBay : bottomBay,
    bayWidth,
    bayHeight,
  );

  static Offset? destinationFor(ParkingRoute? route) {
    if (route == null) return null;
    return Offset(
      bayLeft + route.destination.column * step + bayWidth / 2,
      route.destination.row == ParkingMapRow.top
          ? topBay + bayHeight + 4
          : bottomBay - 4,
    );
  }
}
