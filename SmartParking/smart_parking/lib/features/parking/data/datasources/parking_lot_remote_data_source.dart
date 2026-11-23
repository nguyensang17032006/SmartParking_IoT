import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/parking_lot_model.dart';

abstract class ParkingLotRemoteDataSource {
  Future<List<ParkingLotModel>> getParkingLots(String campusId);
}

class ParkingLotRemoteDataSourceImpl
    implements ParkingLotRemoteDataSource {
  final SupabaseClient supabase;

  ParkingLotRemoteDataSourceImpl(this.supabase);

  @override
  Future<List<ParkingLotModel>> getParkingLots(
    String campusId,
  ) async {
    final response = await supabase
        .from('parking_lots')
        .select('id, campus_id, name, status')
        .eq('campus_id', campusId)
        .eq('status', 'active')
        .order('name', ascending: true);

    return response
        .map((json) => ParkingLotModel.fromJson(json))
        .toList();
  }
}