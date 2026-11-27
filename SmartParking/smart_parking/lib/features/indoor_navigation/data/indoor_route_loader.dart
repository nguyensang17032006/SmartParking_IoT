import 'package:supabase_flutter/supabase_flutter.dart';
import '../../parking/domain/entities/map_element.dart';
import '../domain/services/a_star_pathfinder.dart';

class IndoorRouteLoader {
  final SupabaseClient client;
  const IndoorRouteLoader(this.client);
  Future<List<GridNode>> find({
    required List<String> floorIds,
    required Future<List<MapElement>> Function(String) loadFloor,
    required String slotId,
  }) async {
    final entries = await Future.wait(
      floorIds.map((id) async => MapEntry(id, await loadFloor(id))),
    );
    final floors = Map<String, List<MapElement>>.fromEntries(entries);
    final ramps = await client
        .from('ramp_connections')
        .select('from_element_id,to_element_id,direction');
    print('Floors count: ${floors.length}, keys: ${floors.keys.toList()}');
    print('Ramps connections: $ramps');
    return const AStarPathfinder().find(
      floors: floors,
      ramps: List<Map<String, dynamic>>.from(ramps),
      slotId: slotId,
    );
  }
}
