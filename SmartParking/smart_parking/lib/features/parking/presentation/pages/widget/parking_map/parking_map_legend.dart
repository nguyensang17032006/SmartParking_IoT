import 'package:flutter/material.dart';

class ParkingMapLegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const ParkingMapLegendItem({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF6F7C90)),
      ),
    ],
  );
}
