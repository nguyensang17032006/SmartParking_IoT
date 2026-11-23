
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/parking_slot_model.dart';

abstract class ParkingSlotRemoteDataSource {
  Stream<List<ParkingSlotModel>> watchParkingSlots();
}

class ParkingSlotRemoteDataSourceImpl
    implements ParkingSlotRemoteDataSource {
  final SupabaseClient supabase;

  ParkingSlotRemoteDataSourceImpl(this.supabase);

  @override
  Stream<List<ParkingSlotModel>> watchParkingSlots() {
    return supabase
        .from('parking_slots')
        .stream(primaryKey: ['id'])
        .map(
          (rows) => rows
              .map((json) => ParkingSlotModel.fromJson(json))
              .toList(),
        );
  }
}
