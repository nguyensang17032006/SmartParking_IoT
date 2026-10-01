import 'package:flutter/material.dart';

import 'features/parking/presentation/pages/parking_home.dart';

void main() => runApp(const ParkingHomePreviewApp());

class ParkingHomePreviewApp extends StatelessWidget {
  const ParkingHomePreviewApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Campus Parking',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE21E49)),
      fontFamily: 'Roboto',
    ),
    home: const ParkingHome(),
  );
}
