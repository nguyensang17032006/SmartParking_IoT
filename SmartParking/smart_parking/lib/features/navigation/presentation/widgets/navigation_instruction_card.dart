import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/navigation_instruction.dart';

class NavigationInstructionCard extends StatelessWidget {
  final NavigationInstruction instruction;

  const NavigationInstructionCard({super.key, required this.instruction});

  IconData _getIcon(NavigationManeuver maneuver) {
    switch (maneuver) {
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

  // Hướng dẫn chính.
  Widget _buildPrimaryInstruction() {
    return Row(
      children: [
        Icon(_getIcon(instruction.maneuver), size: 48, color: Colors.white),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDistance(instruction.distanceToManeuver),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                instruction.instruction,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Hướng dẫn tiếp theo.
  Widget _buildNextInstruction(NavigationInstruction next) {
    return Row(
      children: [
        Icon(_getIcon(next.maneuver), size: 28, color: Colors.white),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sau đó ${_formatDistance(next.distanceToManeuver)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 3),

              Text(
                next.instruction,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Tên đường đang di chuyển.
  Widget _buildCurrentStreet() {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 15,
          color: Colors.white.withValues(alpha: 0.7),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            'Đang đi trên ${instruction.currentStreetName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final next = instruction.nextInstruction;

    final hasCurrentStreet = instruction.currentStreetName.trim().isNotEmpty;

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

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,

        children: [
          _buildPrimaryInstruction(),

          if (next != null) ...[
            Divider(
              height: 24,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.15),
            ),

            _buildNextInstruction(next),
          ],

          if (hasCurrentStreet) ...[
            const SizedBox(height: 12),

            _buildCurrentStreet(),
          ],
        ],
      ),
    );
  }
}
