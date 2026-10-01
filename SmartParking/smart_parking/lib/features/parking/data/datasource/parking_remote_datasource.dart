import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/parking_slot_model.dart';

abstract class ParkingRemoteDataSource {
  Stream<List<ParkingSlotModel>> watchParkingSlots();
  Future<Map<String, dynamic>> getMyParking();
  Future<void> mutate(String function, Map<String, dynamic> params);
  Future<Map<String, dynamic>> getReport();
}

class ParkingRemoteDataSourceImpl implements ParkingRemoteDataSource {
  final SupabaseClient supabase;
  ParkingRemoteDataSourceImpl({required this.supabase});

  @override
  Stream<List<ParkingSlotModel>> watchParkingSlots() => supabase
      .from('parking_slots')
      .stream(primaryKey: ['id'])
      .order('code')
      .map((rows) => rows.map(ParkingSlotModel.fromJson).toList());

  @override
  Future<Map<String, dynamic>> getMyParking() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw StateError('Vui lòng đăng nhập');
    final bookings = await supabase
        .from('parking_reservations')
        .select('id,slot_code,status,expires_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(10);
    final position = await supabase
        .from('parking_positions')
        .select('slot_code,note,source,saved_at')
        .eq('user_id', userId)
        .maybeSingle();
    final visit = await supabase
        .from('parking_visits')
        .select('slot_code,started_at')
        .eq('user_id', userId)
        .isFilter('ended_at', null)
        .maybeSingle();
    return {'bookings': bookings, 'position': position, 'visit': visit};
  }

  @override
  Future<void> mutate(String function, Map<String, dynamic> params) async {
    await supabase.rpc(function, params: params);
  }

  @override
  Future<Map<String, dynamic>> getReport() async =>
      Map<String, dynamic>.from(await supabase.rpc('parking_report') as Map);
}
