import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/parking_map_layout.dart';
import '../../../../domain/entities/parking_slot.dart';
import '../../../parking_map_cubit/parking_map_cubit.dart';
import '../../../parking_map_cubit/parking_map_state.dart';
import 'parking_map_view.dart';

/// Public widget with the same parameters as the original ParkingMap.
/// Its State owns the Cubit lifecycle; selection rules are outside the widget.
class ParkingMap extends StatefulWidget {
  final List<ParkingSlot> slots;
  final List<String> topRowCodes;
  final List<String> bottomRowCodes;
  final Set<String>? highlightedCodes;

  const ParkingMap({
    super.key,
    required this.slots,
    this.topRowCodes = const ['A01', 'A02', 'A03'],
    this.bottomRowCodes = const ['B01', 'B02', 'B03'],
    this.highlightedCodes,
  });

  @override
  State<ParkingMap> createState() => _ParkingMapState();
}

class _ParkingMapState extends State<ParkingMap> {
  late final ParkingMapCubit _cubit;

  ParkingMapLayout _layout() => ParkingMapLayout(
    topRowCodes: widget.topRowCodes,
    bottomRowCodes: widget.bottomRowCodes,
  );

  @override
  void initState() {
    super.initState();
    _cubit = ParkingMapCubit(
      slots: widget.slots,
      layout: _layout(),
      highlightedCodes: widget.highlightedCodes,
    );
  }

  @override
  void didUpdateWidget(covariant ParkingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _cubit.updateData(
      slots: widget.slots,
      layout: _layout(),
      highlightedCodes: widget.highlightedCodes,
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ParkingMapCubit, ParkingMapState>(
        bloc: _cubit,
        builder: (context, state) => ParkingMapView(
          state: state,
          onSelectSlot: _cubit.selectSlot,
          onClear: _cubit.clearSelection,
        ),
      );
}
