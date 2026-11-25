import 'package:geolocator/geolocator.dart';

import '../../domain/entities/navigation_location.dart';

class NavigationLocationModel extends NavigationLocation {
  const NavigationLocationModel({
    required super.latitude,
    required super.longitude,
    super.accuracy,
    super.speed,
    super.heading,
  });

  factory NavigationLocationModel.fromPosition(Position position) {
    return NavigationLocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      speed: position.speed,
      heading: position.heading,
    );
  }

  factory NavigationLocationModel.fromCoordinates(
    List<dynamic> coordinates,
  ) {
    return NavigationLocationModel(
      latitude: (coordinates[1] as num).toDouble(),
      longitude: (coordinates[0] as num).toDouble(),
    );
  }
}