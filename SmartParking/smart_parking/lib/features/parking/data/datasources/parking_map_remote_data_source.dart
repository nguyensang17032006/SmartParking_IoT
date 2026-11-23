import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/map_version_model.dart';
import '../models/map_element_model.dart';

abstract class ParkingMapRemoteDataSource {
  Future<List<MapElementModel>> getMapElements(
    String mapVersionId,
    String floorId,
  );
  
  Future<MapVersionModel?> getPublishedMapVersion(String campusId);
  Future<List<Map<String, dynamic>>> getFloors(String lotId);
}

class ParkingMapRemoteDataSourceImpl implements ParkingMapRemoteDataSource {
  final SupabaseClient supabase;

  ParkingMapRemoteDataSourceImpl(this.supabase);

  // Lấy các phần tử của bản đồ
  @override
  Future<List<MapElementModel>> getMapElements(
    String mapVersionId,
    String floorId,
  ) async {
    final response = await supabase
        .from('map_elements')
        .select()
        .eq('map_version_id', mapVersionId)
        .eq('floor_id', floorId);

    return response.map((json) => MapElementModel.fromJson(json)).toList();
  }

  // Lấy phiên bản bản đồ đã published theo campus
  @override
  @override
Future<MapVersionModel?> getPublishedMapVersion(
  String lotId,
) async {
  final response = await supabase
      .from('map_versions')
      .select('id, lot_id, version_number, published_at')
      .eq('lot_id', lotId)
      .eq('status', 'published')
      .order('version_number', ascending: false)
      .limit(1)
      .maybeSingle();

  if (response == null) return null;

  return MapVersionModel.fromJson(response);
}

  @override
  Future<List<Map<String, dynamic>>> getFloors(String lotId) async {
    final response = await supabase
        .from('parking_floors')
        .select('id, code, name, level_number')
        .eq('lot_id', lotId)
        .order('level_number', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}
