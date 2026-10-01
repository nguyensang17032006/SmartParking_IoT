import 'dart:math';

import '../entities/parking_slot.dart';

class MapPoint {
  final String id;
  final double x;
  final double y;
  const MapPoint(this.id, this.x, this.y);
  double distanceTo(MapPoint other) =>
      sqrt(pow((x - other.x) * 30, 2) + pow((y - other.y) * 10, 2));
}

/// Dijkstra over a graph of permitted lanes. Coordinates are normalized;
/// distances assume a 30m x 10m sample map, not an actual surveyed campus.
List<MapPoint> shortestRoute(
  Map<String, MapPoint> nodes,
  Map<String, List<String>> edges,
  String start,
  String end,
) {
  if (!nodes.containsKey(start) || !nodes.containsKey(end)) return [];
  final distances = <String, double>{
    for (final id in nodes.keys) id: double.infinity,
  };
  final previous = <String, String>{};
  final pending = nodes.keys.toSet();
  distances[start] = 0;
  while (pending.isNotEmpty) {
    final current = pending.reduce(
      (a, b) => distances[a]! <= distances[b]! ? a : b,
    );
    if (distances[current]!.isInfinite) break;
    pending.remove(current);
    if (current == end) break;
    for (final neighbor in edges[current] ?? <String>[]) {
      if (!pending.contains(neighbor)) continue;
      final next =
          distances[current]! + nodes[current]!.distanceTo(nodes[neighbor]!);
      if (next < distances[neighbor]!) {
        distances[neighbor] = next;
        previous[neighbor] = current;
      }
    }
  }
  if (distances[end]!.isInfinite) return [];
  final ids = <String>[end];
  while (ids.last != start) {
    final parent = previous[ids.last];
    if (parent == null) return [];
    ids.add(parent);
  }
  return ids.reversed.map((id) => nodes[id]!).toList();
}

List<MapPoint> routeFromEntrance(ParkingSlot slot) {
  final nodes = <String, MapPoint>{
    'gate': const MapPoint('gate', 0.04, 0.5),
    'west': const MapPoint('west', 0.2, 0.5),
    'center': const MapPoint('center', 0.5, 0.5),
    'east': const MapPoint('east', 0.8, 0.5),
    'target': MapPoint('target', slot.mapX, slot.mapY),
  };
  final aisle = ['west', 'center', 'east'].reduce(
    (a, b) => (nodes[a]!.x - slot.mapX).abs() <= (nodes[b]!.x - slot.mapX).abs()
        ? a
        : b,
  );
  final edges = <String, List<String>>{
    'gate': ['west'],
    'west': ['gate', 'center'],
    'center': ['west', 'east'],
    'east': ['center'],
    'target': [aisle],
  };
  edges[aisle]!.add('target');
  return shortestRoute(nodes, edges, 'gate', 'target');
}

double routeLength(List<MapPoint> route) {
  var total = 0.0;
  for (var i = 1; i < route.length; i++) {
    total += route[i - 1].distanceTo(route[i]);
  }
  return total;
}
