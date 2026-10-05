import 'package:flutter/material.dart';

import 'parking_map_legend.dart';
import 'parking_map_style.dart';

class ParkingMapHeader extends StatelessWidget {
  const ParkingMapHeader({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Sơ đồ bãi xe',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF172A46),
        ),
      ),
      SizedBox(height: 6),
      Text(
        'Chạm ô trống để xem đường từ cổng vào.',
        style: TextStyle(fontSize: 12, color: Color(0xFF6F7C90)),
      ),
      SizedBox(height: 16),
      Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          ParkingMapLegendItem(label: 'Trống', color: ParkingMapColors.green),
          ParkingMapLegendItem(label: 'Có xe', color: ParkingMapColors.red),
          ParkingMapLegendItem(label: 'Đã chọn', color: ParkingMapColors.blue),
        ],
      ),
    ],
  );
}
