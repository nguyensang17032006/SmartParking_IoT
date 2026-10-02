import 'package:flutter/material.dart';

import '../../../domain/entities/parking_route.dart';
import 'parking_map_style.dart';

class ParkingMapRouteSummary extends StatelessWidget {
  final ParkingRoute? route;
  final VoidCallback onClear;
  const ParkingMapRouteSummary({
    super.key,
    required this.route,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final selectedRoute = route;
    if (selectedRoute == null) {
      return const Text(
        'Đường màu xanh dẫn đến ô bạn chọn.',
        style: TextStyle(fontSize: 12, color: Color(0xFF6F7C90)),
      );
    }
    return Container(
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.alt_route_rounded,
            size: 20,
            color: ParkingMapColors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cổng vào → ${selectedRoute.slotCode}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ParkingMapColors.blue,
              ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text(
              'Bỏ chọn',
              style: TextStyle(color: ParkingMapColors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
