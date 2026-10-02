import 'package:flutter/material.dart';

class ParkingMapGate extends StatelessWidget {
  final String label;
  final IconData icon;
  const ParkingMapGate({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 20, color: const Color(0xFF172A46)),
      const SizedBox(height: 5),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF172A46),
        ),
      ),
    ],
  );
}
