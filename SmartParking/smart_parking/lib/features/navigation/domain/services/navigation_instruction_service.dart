import 'dart:math' as math;

import '../entities/navigation_instruction.dart';
import '../entities/navigation_progress.dart';
import '../entities/navigation_route.dart';
import '../entities/navigation_step.dart';

class NavigationInstructionService {
  const NavigationInstructionService();

  NavigationManeuver _getManeuver(
    NavigationStep step,
  ) {
    switch (step.maneuverType) {
      case 'arrive':
        return NavigationManeuver.arrive;

      case 'depart':
        return NavigationManeuver.depart;

      case 'roundabout':
      case 'rotary':
      case 'roundabout turn':
      case 'exit roundabout':
      case 'exit rotary':
        return NavigationManeuver.roundabout;

      case 'merge':
        return NavigationManeuver.merge;
    }

    switch (step.maneuverModifier) {
      case 'straight':
        return NavigationManeuver.straight;

      case 'left':
        return NavigationManeuver.turnLeft;

      case 'right':
        return NavigationManeuver.turnRight;

      case 'slight left':
        return NavigationManeuver.slightLeft;

      case 'slight right':
        return NavigationManeuver.slightRight;

      case 'sharp left':
        return NavigationManeuver.sharpLeft;

      case 'sharp right':
        return NavigationManeuver.sharpRight;

      case 'uturn':
        return NavigationManeuver.uTurn;

      default:
        return NavigationManeuver.unknown;
    }
  }

  String _buildInstruction(
    NavigationManeuver maneuver,
    NavigationStep step,
  ) {
    String instruction;

    switch (maneuver) {
      case NavigationManeuver.straight:
        instruction = 'Đi thẳng';
        break;

      case NavigationManeuver.turnLeft:
        instruction = 'Rẽ trái';
        break;

      case NavigationManeuver.turnRight:
        instruction = 'Rẽ phải';
        break;

      case NavigationManeuver.slightLeft:
        instruction = 'Đi chếch sang trái';
        break;

      case NavigationManeuver.slightRight:
        instruction = 'Đi chếch sang phải';
        break;

      case NavigationManeuver.sharpLeft:
        instruction = 'Rẽ gấp sang trái';
        break;

      case NavigationManeuver.sharpRight:
        instruction = 'Rẽ gấp sang phải';
        break;

      case NavigationManeuver.uTurn:
        instruction = 'Quay đầu xe';
        break;

      case NavigationManeuver.roundabout:
        if (step.maneuverType == 'exit roundabout' ||
            step.maneuverType == 'exit rotary') {
          instruction = 'Ra khỏi vòng xuyến';
        } else {
          instruction = 'Đi vào vòng xuyến';
        }
        break;

      case NavigationManeuver.merge:
        instruction = 'Nhập vào làn đường';
        break;

      case NavigationManeuver.arrive:
        return 'Điểm đến ở phía trước';

      case NavigationManeuver.depart:
        instruction = 'Bắt đầu di chuyển';
        break;

      case NavigationManeuver.unknown:
        instruction = 'Tiếp tục di chuyển';
        break;
    }

    if (step.streetName.trim().isNotEmpty) {
      return '$instruction vào ${step.streetName}';
    }

    return instruction;
  }

  NavigationInstruction? getNextInstruction({
    required NavigationRoute route,
    required NavigationProgress progress,
  }) {
    final steps = route.steps;

    if (steps.isEmpty) {
      return null;
    }

    final geometryDistance =
        progress.traveledDistance +
        progress.remainingDistance;

    final totalStepDistance = steps.fold<double>(
      0,
      (total, step) => total + step.distance,
    );

    final distanceScale = geometryDistance > 0
        ? totalStepDistance / geometryDistance
        : 1.0;

    final traveledDistance =
        progress.traveledDistance * distanceScale;

    double accumulatedDistance = 0;

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];

      final maneuverDistance = accumulatedDistance;

      accumulatedDistance += step.distance;

      if (step.maneuverType == 'depart' &&
          steps.length > 1) {
        continue;
      }

      if (maneuverDistance < traveledDistance &&
          i < steps.length - 1) {
        continue;
      }

      final maneuver = _getManeuver(step);

      return NavigationInstruction(
        maneuver: maneuver,
        instruction: _buildInstruction(
          maneuver,
          step,
        ),
        streetName: step.streetName,
        distanceToManeuver: math.max(
          0.0,
          maneuverDistance - traveledDistance,
        ),
        stepIndex: i,
      );
    }

    return null;
  }
}