import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/navigation_instruction.dart';

class NavigationInstructionCard extends StatelessWidget {
  final NavigationInstruction instruction;

  const NavigationInstructionCard({
    super.key,
    required this.instruction,
  });

  IconData _getIcon() {
    switch (instruction.maneuver) {
      case NavigationManeuver.straight:
        return Icons.straight;

      case NavigationManeuver.turnLeft:
        return Icons.turn_left;

      case NavigationManeuver.turnRight:
        return Icons.turn_right;

      case NavigationManeuver.slightLeft:
        return Icons.turn_slight_left;

      case NavigationManeuver.slightRight:
        return Icons.turn_slight_right;

      case NavigationManeuver.sharpLeft:
        return Icons.turn_sharp_left;

      case NavigationManeuver.sharpRight:
        return Icons.turn_sharp_right;

      case NavigationManeuver.uTurn:
        return Icons.u_turn_left;

      case NavigationManeuver.roundabout:
        return Icons.roundabout_right;

      case NavigationManeuver.merge:
        return Icons.merge;

      case NavigationManeuver.arrive:
        return Icons.location_on;

      case NavigationManeuver.depart:
      case NavigationManeuver.unknown:
        return Icons.navigation;
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _getIcon(),
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDistance(
                    instruction.distanceToManeuver,
                  ),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  instruction.instruction,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}