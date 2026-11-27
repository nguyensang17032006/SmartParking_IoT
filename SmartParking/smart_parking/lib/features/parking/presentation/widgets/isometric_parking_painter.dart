import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/map_element.dart';
import '../../domain/entities/parking_slot.dart';
import '../utils/isometric_projection.dart';

class IsometricParkingPainter extends CustomPainter {
  final List<MapElement> elements;

  final Map<String, ParkingSlot> slotsById;

  final IsometricProjection projection;

  final String? selectedSlotId;

  IsometricParkingPainter({
    required this.elements,
    required this.slotsById,
    required this.projection,
    this.selectedSlotId,
  });

  static const Color _floorColor = Color(0xFF626B78);

  static const Color _roadColor = Color(0xFF4B5563);

  static const Color _availableColor = Color(0xFF16A34A);

  static const Color _occupiedColor = Color(0xFFDC2626);

  static const Color _reservedColor = Color(0xFFF59E0B);

  static const Color _selectedColor = Color(0xFF2563EB);

  static const Color _inactiveColor = Color(0xFF9CA3AF);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFEEF2F7), BlendMode.src);

    final validElements = elements
        .where((e) => e.width > 0 && e.height > 0)
        .toList();

    if (validElements.isEmpty) return;

    // 1. Vẽ mặt sàn.
    _drawFloor(canvas, validElements);

    // 2. Vẽ các thành phần nằm trên mặt sàn.
    for (final element in validElements) {
      switch (element.type) {
        case 'zone':
          _drawZone(canvas, element);
          break;
      }
    }

    for (final element in validElements) {
      switch (element.type) {
        case 'road':
          _drawRoad(canvas, element);
          break;

        case 'ramp':
          _drawRamp(canvas, element);
          break;

        case 'gate_in':
        case 'gate_out':
          _drawGate(canvas, element);
          break;
      }
    }

    // 3. Vẽ các ô đỗ xe.
    for (final element in validElements) {
      if (element.type == 'slot') {
        _drawSlot(canvas, element);
      }
    }

    // 4. Sắp xếp vật thể nổi theo chiều sâu.
    final elevatedElements = validElements
        .where(
          (e) =>
              e.type == 'obstacle' ||
              e.type == 'wall' ||
              e.type == 'pillar' ||
              e.type == 'slot',
        )
        .toList();

    elevatedElements.sort((a, b) => _depth(a).compareTo(_depth(b)));

    // 5. Vẽ vật thể có chiều cao.
    for (final element in elevatedElements) {
      switch (element.type) {
        case 'obstacle':
          _drawObstacle(canvas, element);
          break;

        case 'wall':
          _drawWall(canvas, element);
          break;

        case 'pillar':
          _drawPillar(canvas, element);
          break;

        case 'slot':
          final slot = slotsById[element.slotId];

          if (slot != null && slot.isActive && slot.status == 'occupied') {
            _drawVehicle(canvas, element, slot);
          }
          break;
      }
    }

    // 6. Vẽ nhãn của vị trí đang chọn.
    for (final element in validElements) {
      if (element.type == 'slot' &&
          selectedSlotId != null &&
          element.slotId == selectedSlotId) {
        _drawSelectedLabel(canvas, element);
      }
    }
  }

  // =====================================================
  // DEPTH
  // =====================================================

  double _depth(MapElement element) {
    final corners = projection.projectRectangle(
      x: element.x.toDouble(),
      y: element.y.toDouble(),
      width: element.width.toDouble(),
      height: element.height.toDouble(),
      rotation: element.rotation.toDouble(),
    );

    return corners.map((point) => point.dy).reduce(math.max);
  }

  // =====================================================
  // BASIC DRAWING
  // =====================================================

  void _drawPolygon(
    Canvas canvas,
    List<Offset> points,
    Color color, {
    Color? borderColor,
    double borderWidth = 1,
  }) {
    final path = Path()..addPolygon(points, true);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    if (borderColor != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  List<Offset> _elementPoints(MapElement element, {double z = 0}) {
    return projection.projectRectangle(
      x: element.x.toDouble(),
      y: element.y.toDouble(),
      width: element.width.toDouble(),
      height: element.height.toDouble(),
      rotation: element.rotation.toDouble(),
      z: z,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position, {
    double fontSize = 11,
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
    );

    painter.layout();

    painter.paint(
      canvas,
      position - Offset(painter.width / 2, painter.height / 2),
    );

    painter.dispose();
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);

    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0).toDouble())
        .toColor();
  }

  // =====================================================
  // FLOOR
  // =====================================================

  void _drawFloor(Canvas canvas, List<MapElement> elements) {
    double minX = double.infinity;
    double minY = double.infinity;

    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final element in elements) {
      final corners = _elementPoints(element);

      for (final corner in corners) {
        final point = projection.unproject(corner);

        minX = math.min(minX, point.dx);
        minY = math.min(minY, point.dy);

        maxX = math.max(maxX, point.dx);
        maxY = math.max(maxY, point.dy);
      }
    }

    const padding = 0.5;

    final points = projection.projectRectangle(
      x: minX - padding,
      y: minY - padding,
      width: maxX - minX + padding * 2,
      height: maxY - minY + padding * 2,
    );

    final thickness = projection.cellSize * 0.3;

    final bottomPoints = points
        .map((point) => point + Offset(0, thickness))
        .toList();

    // Mặt bên trái.
    _drawPolygon(canvas, [
      points[3],
      points[2],
      bottomPoints[2],
      bottomPoints[3],
    ], const Color(0xFF374151));

    // Mặt bên phải.
    _drawPolygon(canvas, [
      points[1],
      points[2],
      bottomPoints[2],
      bottomPoints[1],
    ], const Color(0xFF4B5563));

    // Mặt sàn phía trên.
    _drawPolygon(
      canvas,
      points,
      _floorColor,
      borderColor: const Color(0xFF94A3B8),
    );
  }

  // =====================================================
  // ZONE
  // =====================================================

  void _drawZone(Canvas canvas, MapElement element) {
    _drawPolygon(
      canvas,
      _elementPoints(element),
      const Color(0xFF788391),
      borderColor: const Color(0xFF94A3B8),
    );
  }

  // =====================================================
  // ROAD
  // =====================================================

  void _drawRoad(Canvas canvas, MapElement element) {
    final points = _elementPoints(element);

    _drawPolygon(canvas, points, _roadColor);

    final horizontal = element.width >= element.height;

    final start = horizontal
        ? Offset(
            (points[0].dx + points[3].dx) / 2,
            (points[0].dy + points[3].dy) / 2,
          )
        : Offset(
            (points[0].dx + points[1].dx) / 2,
            (points[0].dy + points[1].dy) / 2,
          );

    final end = horizontal
        ? Offset(
            (points[1].dx + points[2].dx) / 2,
            (points[1].dy + points[2].dy) / 2,
          )
        : Offset(
            (points[3].dx + points[2].dx) / 2,
            (points[3].dy + points[2].dy) / 2,
          );

    _drawDashedLine(canvas, start, end);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end) {
    final delta = end - start;
    final length = delta.distance;

    if (length <= 0) return;

    final direction = delta / length;

    final dashLength = projection.cellSize * 0.35;
    final gapLength = projection.cellSize * 0.25;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    double distance = 0;

    while (distance < length) {
      final dashStart = start + direction * distance;

      final dashEnd =
          start + direction * math.min(distance + dashLength, length);

      canvas.drawLine(dashStart, dashEnd, paint);

      distance += dashLength + gapLength;
    }
  }

  // =====================================================
  // SLOT
  // =====================================================

  Color _getSlotColor(ParkingSlot? slot) {
    if (slot == null || !slot.isActive) {
      return _inactiveColor;
    }

    switch (slot.status) {
      case 'available':
        return _availableColor;

      case 'occupied':
        return _occupiedColor;

      case 'reserved':
        return _reservedColor;

      case 'maintenance':
        return const Color(0xFFFACC15);

      default:
        return _inactiveColor;
    }
  }

  void _drawSlot(Canvas canvas, MapElement element) {
    final slot = slotsById[element.slotId];

    final isSelected =
        selectedSlotId != null && selectedSlotId == element.slotId;

    final color = isSelected ? _selectedColor : _getSlotColor(slot);

    final points = _elementPoints(element);
    if (isSelected || (slot?.isActive == true && slot?.status == 'available')) {
      canvas.drawPath(Path()..addPolygon(points, true), Paint()..color = color.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 4..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
    _drawPolygon(
      canvas,
      points,
      color.withValues(alpha: 0.25),
      borderColor: color,
      borderWidth: isSelected ? 3 : 1.8,
    );

    final center = projection.project(
      element.x + element.width / 2,
      element.y + element.height / 2,
    );

    if (slot?.status != 'occupied') {
      _drawText(
        canvas,
        slot?.code ?? element.label ?? '',
        center,
        fontSize: 10,
      );
    }
  }

  // =====================================================
  // 3D BOX
  // =====================================================

  void _drawBox(
    Canvas canvas, {
    required double x,
    required double y,
    required double width,
    required double height,
    required double elevation,
    required Color color,
    double rotation = 0,
    double baseZ = 0,
  }) {
    final bottom = projection.projectRectangle(
      x: x,
      y: y,
      width: width,
      height: height,
      rotation: rotation,
      z: baseZ,
    );

    final top = projection.projectRectangle(
      x: x,
      y: y,
      width: width,
      height: height,
      rotation: rotation,
      z: baseZ + elevation,
    );

    // Chỉ vẽ những mặt bên hướng về người xem.
    for (int i = 0; i < 4; i++) {
      final next = (i + 1) % 4;

      final edge = bottom[next] - bottom[i];

      if (edge.dx >= 0) continue;

      _drawPolygon(canvas, [
        bottom[i],
        bottom[next],
        top[next],
        top[i],
      ], _darken(color, i.isEven ? 0.22 : 0.12));
    }

    _drawPolygon(
      canvas,
      top,
      color,
      borderColor: Colors.black12,
      borderWidth: 0.6,
    );
  }

  // =====================================================
  // OBSTACLE
  // =====================================================

  void _drawObstacle(Canvas canvas, MapElement element) {
    _drawBox(
      canvas,
      x: element.x.toDouble(),
      y: element.y.toDouble(),
      width: element.width.toDouble(),
      height: element.height.toDouble(),
      rotation: element.rotation.toDouble(),
      elevation: projection.cellSize * 0.8,
      color: const Color(0xFF94A3B8),
    );
  }

  // =====================================================
  // WALL
  // =====================================================

  void _drawWall(Canvas canvas, MapElement element) {
    _drawBox(
      canvas,
      x: element.x.toDouble(),
      y: element.y.toDouble(),
      width: element.width.toDouble(),
      height: element.height.toDouble(),
      rotation: element.rotation.toDouble(),
      elevation: projection.cellSize * 1.6,
      color: const Color(0xFFCBD5E1),
    );
  }

  // =====================================================
  // PILLAR
  // =====================================================

  void _drawPillar(Canvas canvas, MapElement element) {
    _drawBox(
      canvas,
      x: element.x.toDouble(),
      y: element.y.toDouble(),
      width: element.width.toDouble(),
      height: element.height.toDouble(),
      rotation: element.rotation.toDouble(),
      elevation: projection.cellSize * 1.8,
      color: const Color(0xFFE2E8F0),
    );
  }

  // =====================================================
  // RAMP
  // =====================================================

  void _drawRamp(Canvas canvas, MapElement element) {
    _drawPolygon(
      canvas,
      _elementPoints(element),
      const Color(0xFF64748B),
      borderColor: const Color(0xFFFBBF24),
      borderWidth: 2,
    );

    final center = projection.project(
      element.x + element.width / 2,
      element.y + element.height / 2,
    );

    _drawText(canvas, element.label ?? 'Đường dốc', center);
  }

  // =====================================================
  // GATE
  // =====================================================

  void _drawGate(Canvas canvas, MapElement element) {
    final isEntrance = element.type == 'gate_in';

    _drawPolygon(
      canvas,
      _elementPoints(element),
      isEntrance ? const Color(0xFF2563EB) : const Color(0xFF7C3AED),
      borderColor: Colors.white70,
    );

    final center = projection.project(
      element.x + element.width / 2,
      element.y + element.height / 2,
    );

    _drawText(canvas, isEntrance ? 'Lối vào' : 'Lối ra', center, fontSize: 12);
  }

  // =====================================================
  // VEHICLE
  // =====================================================

  void _drawVehicle(Canvas canvas, MapElement element, ParkingSlot slot) {
    final vehicleType = slot.vehicleType.toLowerCase();

    if (vehicleType == 'motorbike' ||
        vehicleType == 'motorcycle' ||
        vehicleType == 'bike') {
      _drawMotorbike(canvas, element);
      return;
    }

    if (vehicleType == 'car') {
      _drawCar(canvas, element);
      return;
    }

    // Không giả định loại phương tiện khi dữ liệu
    // không khớp với các giá trị đã hỗ trợ.
    _drawText(
      canvas,
      'Đã có xe',
      projection.project(
        element.x + element.width / 2,
        element.y + element.height / 2,
      ),
      fontSize: 9,
    );
  }

  void _drawCar(Canvas canvas, MapElement element) {
    final width = element.width * 0.72;
    final height = element.height * 0.72;

    final x = element.x + (element.width - width) / 2;

    final y = element.y + (element.height - height) / 2;

    final rotation = element.rotation.toDouble();

    final bodyHeight = projection.cellSize * 0.22;

    // Thân xe.
    _drawBox(
      canvas,
      x: x,
      y: y,
      width: width,
      height: height,
      elevation: bodyHeight,
      rotation: rotation,
      color: const Color(0xFFE5E7EB),
    );

    // Cabin xe.
    final isVertical = height >= width;

    final cabinWidth = width * (isVertical ? 0.8 : 0.5);

    final cabinHeight = height * (isVertical ? 0.5 : 0.8);

    _drawBox(
      canvas,
      x: x + (width - cabinWidth) / 2,
      y: y + (height - cabinHeight) / 2,
      width: cabinWidth,
      height: cabinHeight,
      elevation: projection.cellSize * 0.16,
      baseZ: bodyHeight,
      rotation: rotation,
      color: const Color(0xFF334155),
    );
  }

  void _drawMotorbike(Canvas canvas, MapElement element) {
    final width = element.width * 0.35;
    final height = element.height * 0.65;

    final x = element.x + (element.width - width) / 2;

    final y = element.y + (element.height - height) / 2;

    _drawBox(
      canvas,
      x: x,
      y: y,
      width: width,
      height: height,
      rotation: element.rotation.toDouble(),
      elevation: projection.cellSize * 0.25,
      color: const Color(0xFFF0194B),
    );

    _drawBox(
      canvas,
      x: x + width * 0.15,
      y: y + height * 0.2,
      width: width * 0.7,
      height: height * 0.6,
      rotation: element.rotation.toDouble(),
      baseZ: projection.cellSize * 0.25,
      elevation: projection.cellSize * 0.08,
      color: const Color(0xFF1F2937),
    );
  }

  // =====================================================
  // SELECTED SLOT
  // =====================================================

  void _drawSelectedLabel(Canvas canvas, MapElement element) {
    final slot = slotsById[element.slotId];

    final center = projection.project(
      element.x + element.width / 2,
      element.y + element.height / 2,
    );

    final labelCenter = center - Offset(0, projection.cellSize * 1.1);

    canvas.drawLine(
      center,
      labelCenter,
      Paint()
        ..color = _selectedColor
        ..strokeWidth = 2,
    );

    canvas.drawCircle(center, 4, Paint()..color = _selectedColor);

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: labelCenter, width: 80, height: 28),
      const Radius.circular(10),
    );

    canvas.drawRRect(rect.shift(const Offset(0, 2)), Paint()..color = Colors.black26..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawRRect(rect, Paint()..color = Colors.white);

    _drawText(
      canvas,
      slot?.code ?? element.label ?? '',
      labelCenter,
      color: const Color(0xFF111A31),
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
  }

  @override
  bool shouldRepaint(covariant IsometricParkingPainter oldDelegate) {
    return oldDelegate.elements != elements ||
        oldDelegate.slotsById != slotsById ||
        oldDelegate.projection != projection ||
        oldDelegate.selectedSlotId != selectedSlotId;
  }
}
