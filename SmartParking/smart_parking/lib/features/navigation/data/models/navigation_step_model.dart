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
  });

  factory NavigationStepModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final maneuver =
        json['maneuver'] as Map<String, dynamic>;

    return NavigationStepModel(
      streetName: json['name'] as String? ?? '',
      maneuverType: maneuver['type'] as String? ?? '',
      maneuverModifier:
          maneuver['modifier'] as String? ?? '',
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      location: NavigationLocationModel.fromCoordinates(
        maneuver['location'] as List<dynamic>,
      ),
    );
  }
}