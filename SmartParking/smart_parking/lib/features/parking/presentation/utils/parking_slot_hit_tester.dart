import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/map_element.dart';
import 'isometric_projection.dart';

class ParkingSlotHitTester {
  const ParkingSlotHitTester();

  String? hitTest({
    required Offset scenePoint,
    required List<MapElement> elements,
    required bool isIsometric,
    required IsometricProjection projection,
    required double cellSize,
  }) {
    // Chuyển về tọa độ gốc của bản đồ.
    final gridPoint = isIsometric
        ? projection.unproject(scenePoint)
        : scenePoint / cellSize;

    // Duyệt ngược theo thứ tự vẽ ô đỗ.
    for (final element in elements.reversed) {
      if (element.type != 'slot' ||
          element.slotId == null ||
          element.width <= 0 ||
          element.height <= 0) {
        continue;
      }

      if (_containsPoint(gridPoint, element)) {
        return element.slotId;
      }
    }

    return null;
  }

  bool _containsPoint(
    Offset point,
    MapElement element,
  ) {
    final centerX =
        element.x + element.width / 2;

    final centerY =
        element.y + element.height / 2;

    // Xoay ngược điểm để kiểm tra ô đỗ
    // có thuộc tính rotation.
    final radians =
        -element.rotation * math.pi / 180;

    final dx = point.dx - centerX;
    final dy = point.dy - centerY;

    final rotatedX =
        centerX +
        dx * math.cos(radians) -
        dy * math.sin(radians);

    final rotatedY =
        centerY +
        dx * math.sin(radians) +
        dy * math.cos(radians);

    return rotatedX >= element.x &&
        rotatedX <= element.x + element.width &&
        rotatedY >= element.y &&
        rotatedY <= element.y + element.height;
  }
}