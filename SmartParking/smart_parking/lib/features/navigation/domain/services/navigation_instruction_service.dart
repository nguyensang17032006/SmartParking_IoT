import 'dart:math' as math;

import '../entities/navigation_instruction.dart';
import '../entities/navigation_progress.dart';
import '../entities/navigation_route.dart';
import '../entities/navigation_step.dart';

import 'navigation_distance_service.dart';

class NavigationInstructionService {
  final NavigationDistanceService distanceService;

  const NavigationInstructionService({
    this.distanceService = const NavigationDistanceService(),
  });

  // Tính chiều dài geometry của từng bước.
  double _getStepGeometryDistance(NavigationStep step) {
    if (step.geometry.length >= 2) {
      final distance = distanceService.calculatePathDistance(step.geometry);

      if (distance.isFinite && distance > 0) {
        return distance;
      }
    }

    if (step.distance.isFinite && step.distance > 0) {
      return step.distance;
    }

    return 0;
  }

  // Tính vị trí bắt đầu của từng step
  // trên toàn bộ tuyến đường.
  List<double> _buildStepOffsets(List<NavigationStep> steps) {
    final offsets = <double>[];

    double accumulatedDistance = 0;

    for (final step in steps) {
      offsets.add(accumulatedDistance);

      accumulatedDistance += _getStepGeometryDistance(step);
    }

    return offsets;
  }

  // Xác định step người dùng đang di chuyển.
  int _findCurrentStepIndex({
    required List<double> offsets,
    required double traveledDistance,
  }) {
    int currentIndex = 0;

    for (int i = 0; i < offsets.length; i++) {
      if (offsets[i] <= traveledDistance) {
        currentIndex = i;
      } else {
        break;
      }
    }

    return currentIndex;
  }

  // Chuyển dữ liệu OSRM thành loại thao tác.
  NavigationManeuver _getManeuver(NavigationStep step) {
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

  // Tạo nội dung hướng dẫn tiếng Việt.
  String _buildInstruction(NavigationManeuver maneuver, NavigationStep step) {
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
        instruction = 'Nhập vào đường';
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

    final streetName = step.streetName.trim();

    if (streetName.isEmpty) {
      return instruction;
    }

    if (maneuver == NavigationManeuver.straight ||
        maneuver == NavigationManeuver.depart ||
        maneuver == NavigationManeuver.unknown) {
      return '$instruction trên $streetName';
    }

    return '$instruction vào $streetName';
  }

  // Tạo một đối tượng hướng dẫn.
  NavigationInstruction _createInstruction({
    required NavigationStep step,
    required int stepIndex,
    required double distance,
    required String currentStreetName,
    NavigationInstruction? nextInstruction,
  }) {
    final maneuver = _getManeuver(step);

    return NavigationInstruction(
      maneuver: maneuver,
      instruction: _buildInstruction(maneuver, step),
      streetName: step.streetName,
      distanceToManeuver: math.max(0.0, distance),
      stepIndex: stepIndex,
      currentStreetName: currentStreetName,
      nextInstruction: nextInstruction,
    );
  }

  // Xác định hướng dẫn hiện tại và tiếp theo.
  NavigationInstruction? getNextInstruction({
    required NavigationRoute route,
    required NavigationProgress progress,
  }) {
    final steps = route.steps;

    if (steps.isEmpty) {
      return null;
    }

    final offsets = _buildStepOffsets(steps);

    final traveledDistance = math.max(0.0, progress.traveledDistance);

    // 1. Xác định đường đang di chuyển.
    final currentStepIndex = _findCurrentStepIndex(
      offsets: offsets,
      traveledDistance: traveledDistance,
    );

    final currentStep = steps[currentStepIndex];

    // 2. Xác định thao tác sắp tới.
    final maneuverIndex = math.min(currentStepIndex + 1, steps.length - 1);

    final maneuverStep = steps[maneuverIndex];

    // 3. Tính khoảng cách đến thao tác sắp tới.
    final distanceToManeuver = math.max(
      0.0,
      offsets[maneuverIndex] - traveledDistance,
    );

    // 4. Xác định thao tác sau đó.
    NavigationInstruction? nextInstruction;

    final nextIndex = maneuverIndex + 1;

    if (nextIndex < steps.length) {
      final nextStep = steps[nextIndex];

      final nextDistance = offsets[nextIndex] - offsets[maneuverIndex];

      nextInstruction = _createInstruction(
        step: nextStep,
        stepIndex: nextIndex,
        distance: nextDistance,
        currentStreetName: maneuverStep.streetName,
      );
    }

    // 5. Trả về hướng dẫn.
    return _createInstruction(
      step: maneuverStep,
      stepIndex: maneuverIndex,
      distance: distanceToManeuver,
      currentStreetName: currentStep.streetName,
      nextInstruction: nextInstruction,
    );
  }
}
