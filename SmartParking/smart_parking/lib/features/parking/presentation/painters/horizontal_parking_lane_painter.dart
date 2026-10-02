import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/parking_map/parking_map_geometry.dart';
import '../widgets/parking_map/parking_map_style.dart';

class HorizontalParkingLanePainter extends CustomPainter {
  final Offset? destination;
  const HorizontalParkingLanePainter(this.destination);

  @override
  void paint(Canvas canvas, Size size) {
    final leftGate = ParkingMapGeometry.gateInset;
    final rightGate = size.width - ParkingMapGeometry.gateInset;
    final centerY = ParkingMapGeometry.roadCenter;
    final road = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        leftGate,
        ParkingMapGeometry.roadTop,
        rightGate,
        ParkingMapGeometry.roadBottom,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(road, Paint()..color = const Color(0xFFEDF1F6));
    canvas.drawRRect(
      road,
      Paint()
        ..color = const Color(0xFFDDE4ED)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final lane = Paint()
      ..color = const Color(0xFFB9C5D5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = leftGate + 16; x < rightGate - 16; x += 24) {
      canvas.drawLine(
        Offset(x, centerY),
        Offset(math.min(x + 12, rightGate - 16), centerY),
        lane,
      );
    }
    // Traffic runs from the left entrance toward the right exit.
    for (var x = leftGate + 30; x < rightGate - 20; x += 108) {
      _arrow(
        canvas,
        Offset(x, centerY - 17),
        Offset(x + 24, centerY - 17),
        lane,
      );
    }

    final post = Paint()
      ..color = const Color(0xFF172A46)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final x in [leftGate, rightGate]) {
      canvas.drawLine(
        Offset(x, ParkingMapGeometry.roadTop + 2),
        Offset(x, ParkingMapGeometry.roadTop + 14),
        post,
      );
      canvas.drawLine(
        Offset(x, ParkingMapGeometry.roadBottom - 14),
        Offset(x, ParkingMapGeometry.roadBottom - 2),
        post,
      );
    }

    final end = destination;
    if (end == null) return;
    final start = Offset(leftGate + 12, centerY);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, centerY)
      ..lineTo(end.dx, end.dy);
    final route = Paint()
      ..color = ParkingMapColors.blue
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, route);
    canvas.drawCircle(start, 6, Paint()..color = ParkingMapColors.blue);
    _arrow(
      canvas,
      Offset(end.dx, end.dy < centerY ? end.dy + 16 : end.dy - 16),
      end,
      route,
    );
  }

  void _arrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final direction = (end - start).direction;
    for (final angle in [-0.65, 0.65]) {
      canvas.drawLine(
        end,
        end -
            Offset(
              math.cos(direction + angle) * 8,
              math.sin(direction + angle) * 8,
            ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HorizontalParkingLanePainter oldDelegate) =>
      oldDelegate.destination != destination;
}
