import 'dart:math' as math;
import 'dart:ui';

class IsometricProjection {
  final double cellSize;

  final Offset origin;

  const IsometricProjection({
    this.cellSize = 32,
    this.origin = Offset.zero,
  }) : assert(cellSize > 0);

  static const double _angle = math.pi / 6;

  // Chuyển tọa độ 2D sang tọa độ 2.5D.
  Offset project(
    double x,
    double y, {
    double z = 0,
  }) {
    final screenX =
        (x - y) * cellSize * math.cos(_angle);

    final screenY =
        (x + y) * cellSize * math.sin(_angle) - z;

    return Offset(
      screenX + origin.dx,
      screenY + origin.dy,
    );
  }

  // Chuyển tọa độ 2.5D về tọa độ mặt phẳng 2D.
  Offset unproject(
    Offset point, {
    double z = 0,
  }) {
    final screenX = point.dx - origin.dx;

    final screenY = point.dy - origin.dy + z;

    final a =
        screenX / (cellSize * math.cos(_angle));

    final b =
        screenY / (cellSize * math.sin(_angle));

    return Offset(
      (a + b) / 2,
      (b - a) / 2,
    );
  }

  // Tính 4 đỉnh của một hình chữ nhật 2.5D.
  List<Offset> projectRectangle({
    required double x,
    required double y,
    required double width,
    required double height,
    double rotation = 0,
    double z = 0,
  }) {
    final centerX = x + width / 2;
    final centerY = y + height / 2;

    final radians = rotation * math.pi / 180;

    final cosAngle = math.cos(radians);
    final sinAngle = math.sin(radians);

    final corners = [
      Offset(x, y),
      Offset(x + width, y),
      Offset(x + width, y + height),
      Offset(x, y + height),
    ];

    return corners.map((corner) {
      final dx = corner.dx - centerX;
      final dy = corner.dy - centerY;

      final rotatedX =
          centerX + dx * cosAngle - dy * sinAngle;

      final rotatedY =
          centerY + dx * sinAngle + dy * cosAngle;

      return project(
        rotatedX,
        rotatedY,
        z: z,
      );
    }).toList();
  }

  // Tạo Path để CustomPainter vẽ vật thể.
  Path createRectanglePath({
    required double x,
    required double y,
    required double width,
    required double height,
    double rotation = 0,
    double z = 0,
  }) {
    final points = projectRectangle(
      x: x,
      y: y,
      width: width,
      height: height,
      rotation: rotation,
      z: z,
    );

    return Path()
      ..addPolygon(points, true);
  }
}