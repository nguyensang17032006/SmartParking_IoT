import '../../domain/entities/navigation_route.dart';
import '../../domain/entities/navigation_step.dart';

import 'navigation_location_model.dart';
import 'navigation_step_model.dart';

class NavigationRouteModel extends NavigationRoute {
  const NavigationRouteModel({
    required super.points,
    required super.steps,
    required super.distance,
    required super.duration,
  });

  factory NavigationRouteModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final geometry =
        json['geometry'] as Map<String, dynamic>;

    final coordinates =
        geometry['coordinates'] as List<dynamic>;

    final points = coordinates.map((coordinate) {
      return NavigationLocationModel.fromCoordinates(
        coordinate as List<dynamic>,
      );
    }).toList();

    final legs = json['legs'] as List<dynamic>;

    final steps = <NavigationStep>[];

    for (final leg in legs) {
      final legJson = leg as Map<String, dynamic>;

      final legSteps = legJson['steps'] as List<dynamic>;

      for (final step in legSteps) {
        steps.add(
          NavigationStepModel.fromJson(
            step as Map<String, dynamic>,
          ),
        );
      }
    }

    return NavigationRouteModel(
      points: points,
      steps: steps,
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
    );
  }
}