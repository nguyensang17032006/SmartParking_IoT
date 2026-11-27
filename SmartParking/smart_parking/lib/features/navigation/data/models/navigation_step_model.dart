import '../../domain/entities/navigation_location.dart';
import '../../domain/entities/navigation_step.dart';

import 'navigation_location_model.dart';

class NavigationStepModel extends NavigationStep {
  const NavigationStepModel({
    required super.streetName,
    required super.maneuverType,
    required super.maneuverModifier,
    required super.distance,
    required super.duration,
    required super.location,
    super.geometry,
    super.bearingBefore,
    super.bearingAfter,
  });

  factory NavigationStepModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final maneuver =
        json['maneuver'] as Map<String, dynamic>;

    // Lấy geometry của từng bước.
    final geometryJson =
        json['geometry'] as Map<String, dynamic>?;

    final coordinates =
        geometryJson?['coordinates'] as List<dynamic>?;

    final geometry = <NavigationLocation>[];

    if (coordinates != null) {
      for (final coordinate in coordinates) {
        geometry.add(
          NavigationLocationModel.fromCoordinates(
            coordinate as List<dynamic>,
          ),
        );
      }
    }

    return NavigationStepModel(
      streetName: json['name'] as String? ?? '',

      maneuverType:
          maneuver['type'] as String? ?? '',

      maneuverModifier:
          maneuver['modifier'] as String? ?? '',

      distance: (json['distance'] as num).toDouble(),

      duration: (json['duration'] as num).toDouble(),

      location: NavigationLocationModel.fromCoordinates(
        maneuver['location'] as List<dynamic>,
      ),

      geometry: List.unmodifiable(geometry),

      bearingBefore:
          (maneuver['bearing_before'] as num?)?.toInt(),

      bearingAfter:
          (maneuver['bearing_after'] as num?)?.toInt(),
    );
  }
}