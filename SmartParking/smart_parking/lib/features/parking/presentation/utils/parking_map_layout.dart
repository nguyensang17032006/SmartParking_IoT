import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/map_element.dart';
import 'isometric_projection.dart';

class ParkingMapLayout {
  final Size canvasSize;

  final IsometricProjection projection;

  const ParkingMapLayout({
    required this.canvasSize,
    required this.projection,
  });

  factory ParkingMapLayout.calculate({
    required List<MapElement> elements,
    required double cellSize,
  }) {
    final baseProjection = IsometricProjection(
      cellSize: cellSize,
    );

    double minX = double.infinity;
    double minY = double.infinity;

    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final element in elements) {
      if (element.width <= 0 ||
          element.height <= 0) {
        continue;
      }

      final corners = baseProjection.projectRectangle(
        x: element.x.toDouble(),
        y: element.y.toDouble(),
        width: element.width.toDouble(),
        height: element.height.toDouble(),
        rotation: element.rotation.toDouble(),
      );

      for (final corner in corners) {
        minX = math.min(minX, corner.dx);
        minY = math.min(minY, corner.dy);

        maxX = math.max(maxX, corner.dx);
        maxY = math.max(maxY, corner.dy);
      }
    }

    if (!minX.isFinite ||
        !minY.isFinite ||
        !maxX.isFinite ||
        !maxY.isFinite) {
      return ParkingMapLayout(
        canvasSize: const Size(300, 300),
        projection: IsometricProjection(
          cellSize: cellSize,
          origin: const Offset(150, 100),
        ),
      );
    }

    // Khoảng trống dành cho mặt sàn,
    // vật thể nổi và nhãn vị trí đỗ xe.
    final horizontalPadding = math.max(
      48.0,
      cellSize * 2,
    );

    final topPadding = math.max(
      64.0,
      cellSize * 3,
    );

    final bottomPadding = cellSize * 2;

    final width =
        maxX - minX + horizontalPadding * 2;

    final height =
        maxY - minY + topPadding + bottomPadding;

    final origin = Offset(
      -minX + horizontalPadding,
      -minY + topPadding,
    );

    return ParkingMapLayout(
      canvasSize: Size(width, height),
      projection: IsometricProjection(
        cellSize: cellSize,
        origin: origin,
      ),
    );
  }
}