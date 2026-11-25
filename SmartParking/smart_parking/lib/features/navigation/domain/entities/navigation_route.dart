import 'navigation_location.dart';
import 'navigation_step.dart';

class NavigationRoute {
  final List<NavigationLocation> points;
  final List<NavigationStep> steps;
  final double distance;
  final double duration;

  const NavigationRoute({
    required this.points,
    required this.steps,
    required this.distance,
    required this.duration,
  });
}