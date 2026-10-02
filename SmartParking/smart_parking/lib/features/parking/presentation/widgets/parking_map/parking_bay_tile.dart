import 'package:flutter/material.dart';

import '../../../domain/entities/parking_slot.dart';
import 'parking_map_style.dart';

class ParkingBayTile extends StatelessWidget {
  final String code;
  final ParkingSlot? slot;
  final bool selected;
  final bool highlighted;
  final VoidCallback onTap;
  const ParkingBayTile({
    super.key,
    required this.code,
    required this.slot,
    required this.selected,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = slot != null && !slot!.occupied;
    final color = selected
        ? ParkingMapColors.blue
        : slot == null
        ? ParkingMapColors.muted
        : slot!.occupied
        ? ParkingMapColors.red
        : ParkingMapColors.green;
    final label = slot == null
        ? 'Chưa có dữ liệu'
        : slot!.occupied
        ? 'Có xe'
        : 'Trống';
    return Opacity(
      opacity: highlighted ? 1 : 0.3,
      child: Semantics(
        label: '$code, $label${selected ? ', đã chọn' : ''}',
        button: available && highlighted,
        selected: selected,
        child: Material(
          color: color.withAlpha(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: BorderSide(
              color: color.withAlpha(selected ? 255 : 110),
              width: selected ? 3 : 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: available && highlighted ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172A46),
                    ),
                  ),
                  Icon(
                    slot == null
                        ? Icons.help_outline_rounded
                        : slot!.occupied
                        ? Icons.directions_car_rounded
                        : Icons.local_parking_rounded,
                    color: color,
                    size: 28,
                  ),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
