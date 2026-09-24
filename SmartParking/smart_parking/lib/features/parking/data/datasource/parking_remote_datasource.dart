import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/parking_slot_model.dart';

abstract class ParkingRemoteDataSource {
  Stream<List<ParkingSlotModel>> watchParkingSlots();
}

class ParkingRemoteDataSourceImpl implements ParkingRemoteDataSource {
  final SupabaseClient supabase;

  ParkingRemoteDataSourceImpl({required this.supabase});

  @override
  Stream<List<ParkingSlotModel>> watchParkingSlots() {
    return supabase
        .from('parking_slots')
        .stream(primaryKey: ['id'])
        .order('code')
        .map((rows) {
          debugPrint('SUPABASE ROWS: $rows');
          return rows.map(ParkingSlotModel.fromJson).toList();
        });
  }
}
