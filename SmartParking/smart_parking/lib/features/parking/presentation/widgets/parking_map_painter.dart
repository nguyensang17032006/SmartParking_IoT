
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/entities/map_element.dart';
import '../../domain/entities/parking_slot.dart';

class ParkingMapPainter extends CustomPainter {
  final List<MapElement> elements;
  final Map<String, ParkingSlot> slotsById;
  final double cellSize;
  final String? selectedSlotId;

  ParkingMapPainter({
    required this.elements,
    required this.slotsById,
    this.cellSize = 32,
    this.selectedSlotId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    canvas.drawColor(
      const Color(0xFFF5F6FA),
      BlendMode.src,
    );

    for (final element in elements) {
      final width = element.width * cellSize;
      final height = element.height * cellSize;

      if (width <= 0 || height <= 0) continue;

      final centerX =
          (element.x + element.width / 2) * cellSize;
      final centerY =
          (element.y + element.height / 2) * cellSize;

      canvas.save();
      canvas.translate(centerX, centerY);
      canvas.rotate(element.rotation * math.pi / 180);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: width,
        height: height,
      );

      paint.color = _getElementColor(element);

      canvas.drawRect(rect, paint);

      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.black26
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      if (element.label != null &&
          element.label!.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: element.label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          maxLines: 1,
          ellipsis: '...',
        );

        textPainter.layout(maxWidth: width);

        textPainter.paint(
          canvas,
          Offset(
            -textPainter.width / 2,
            -textPainter.height / 2,
          ),
        );
      }

      canvas.restore();
    }
  }

  Color _getElementColor(MapElement element) {
    if (element.type == 'slot') {
      if (selectedSlotId != null && element.slotId == selectedSlotId) return const Color(0xFF2563EB);
      final slotId = element.slotId;

      if (slotId == null) {
        return Colors.grey;
      }

      final slot = slotsById[slotId];

      if (slot == null) {
        return Colors.grey;
      }

      if (!slot.isActive) {
        return Colors.grey;
      }

      switch (slot.status) {
        case 'available':
          return const Color(0xFF16A34A);

        case 'occupied':
          return const Color(0xFFDC2626);

        case 'reserved':
          return const Color(0xFFF59E0B);
        case 'maintenance':
          return const Color(0xFFFACC15);

        default:
          return Colors.grey;
      }
    }

    switch (element.type) {
      case 'road':
        return Colors.grey.shade400;

      case 'ramp':
        return Colors.orange.shade300;

      case 'gate_in':
        return Colors.blue.shade300;

      case 'gate_out':
        return Colors.purple.shade300;

      case 'obstacle':
        return Colors.blueGrey.shade600;

      case 'zone':
        return Colors.yellow.shade100;

      default:
        return Colors.white;
    }
  }

  @override
  bool shouldRepaint(covariant ParkingMapPainter oldDelegate) {
    return oldDelegate.elements != elements ||
        oldDelegate.slotsById != slotsById ||
        oldDelegate.cellSize != cellSize || oldDelegate.selectedSlotId != selectedSlotId;
  }
}
