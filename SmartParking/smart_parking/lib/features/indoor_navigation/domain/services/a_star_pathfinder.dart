import '../../../parking/domain/entities/map_element.dart';

typedef GridNode = ({String floor, int x, int y});

class AStarPathfinder {
  const AStarPathfinder();

  static const _sides = ['north', 'east', 'south', 'west'];

  String _effectiveSide(String? side, int rotation) {
    final normalizedSide = _sides.contains(side) ? side! : 'south';
    final steps = ((rotation % 360) + 360) ~/ 90 % 4;
    final idx = _sides.indexOf(normalizedSide);
    return _sides[(idx + steps) % 4];
  }

  String? _readRampField(dynamic item, List<String> keys) {
    if (item == null) return null;
    if (item is Map) {
      for (final k in keys) {
        if (item.containsKey(k) && item[k] != null) {
          return item[k].toString();
        }
      }
      return null;
    }
    try {
      final d = item as dynamic;
      for (final k in keys) {
        if (k == 'from_element_id' || k == 'fromElementId') {
          final v = k == 'from_element_id'
              ? d.from_element_id
              : d.fromElementId;
          if (v != null) return v.toString();
        } else if (k == 'to_element_id' || k == 'toElementId') {
          final v = k == 'to_element_id' ? d.to_element_id : d.toElementId;
          if (v != null) return v.toString();
        } else if (k == 'direction') {
          final v = d.direction;
          if (v != null) return v.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  List<GridNode> _adjacentWalkCells({
    required String floor,
    required MapElement element,
    required String side,
    required Set<GridNode> walkable,
  }) {
    final result = <GridNode>[];
    for (int y = element.y; y < element.y + element.height; y++) {
      for (int x = element.x; x < element.x + element.width; x++) {
        final GridNode? neighbor = switch (side) {
          'north' when y == element.y => (floor: floor, x: x, y: y - 1),
          'south' when y == element.y + element.height - 1 => (
            floor: floor,
            x: x,
            y: y + 1,
          ),
          'west' when x == element.x => (floor: floor, x: x - 1, y: y),
          'east' when x == element.x + element.width - 1 => (
            floor: floor,
            x: x + 1,
            y: y,
          ),
          _ => null,
        };
        if (neighbor != null && walkable.contains(neighbor)) {
          result.add(neighbor);
        }
      }
    }
    return result;
  }

  List<GridNode> find({
    required Map<String, List<MapElement>> floors,
    required List<dynamic> ramps,
    required String slotId,
  }) {
    final walk = <GridNode, Set<String>>{};
    final blocked = <GridNode>{};
    final rampCellsSet = <GridNode>{};
    final gateInElements =
        <(String floor, MapElement el, List<GridNode> cells)>{};
    final rampElements =
        <String, (String floor, MapElement el, List<GridNode> cells)>{};
    final goals = <GridNode>{};

    MapElement? target;
    String? targetFloor;

    for (final entry in floors.entries) {
      final floorName = entry.key;
      for (final e in entry.value) {
        if (e.rotation % 90 != 0) {
          throw StateError(
            'Bản đồ có phần tử góc xoay không hợp lệ: ${e.rotation}',
          );
        }

        final cells = <GridNode>[
          for (int y = e.y; y < e.y + e.height; y++)
            for (int x = e.x; x < e.x + e.width; x++)
              (floor: floorName, x: x, y: y),
        ];

        if (e.type == 'slot' || e.type == 'obstacle' || e.type == 'wall') {
          blocked.addAll(cells);
        }

        if (e.type == 'slot' && e.slotId == slotId) {
          target = e;
          targetFloor = floorName;
        }

        if (e.type == 'ramp') {
          rampCellsSet.addAll(cells);
          rampElements[e.id] = (floorName, e, cells);
          continue;
        }

        if (['road', 'gate_in', 'gate_out'].contains(e.type)) {
          if (![
            'two_way',
            'north',
            'south',
            'east',
            'west',
          ].contains(e.direction)) {
            throw StateError(
              'Hướng lưu thông chưa được hỗ trợ: ${e.direction}',
            );
          }
          for (final c in cells) {
            (walk[c] ??= <String>{}).add(e.direction);
          }
          if (e.type == 'gate_in') {
            gateInElements.add((floorName, e, cells));
          }
        }
      }
    }

    for (final c in blocked) {
      walk.remove(c);
    }
    for (final c in rampCellsSet) {
      walk.remove(c);
    }

    final walkableSet = walk.keys.toSet();
    final t = target;
    final f = targetFloor;
    if (t == null || f == null) return [];

    // 1. Điểm đích (goals): ô đường kề cạnh accessSide của slot
    final targetSide = _effectiveSide(t.accessSide, t.rotation);
    goals.addAll(
      _adjacentWalkCells(
        floor: f,
        element: t,
        side: targetSide,
        walkable: walkableSet,
      ),
    );
    if (goals.isEmpty) return [];

    // 2. Điểm xuất phát (starts): ưu tiên ô đường kề cạnh accessSide của gate_in
    final starts = <GridNode>{};
    for (final (floorName, gate, cells) in gateInElements) {
      final gateSide = _effectiveSide(gate.accessSide, gate.rotation);
      final sidePorts = _adjacentWalkCells(
        floor: floorName,
        element: gate,
        side: gateSide,
        walkable: walkableSet,
      );
      if (sidePorts.isNotEmpty) {
        starts.addAll(sidePorts);
      } else {
        starts.addAll(cells.where(walkableSet.contains));
      }
    }
    if (starts.isEmpty) return [];

    // 3. Cổng đường tiếp giáp theo accessSide của từng đầu dốc (không đi vào bên trong ô dốc)
    List<GridNode> rampRoadPorts(
      (String floor, MapElement el, List<GridNode> cells) info,
    ) {
      final (floorName, rampEl, _) = info;
      final rampSide = _effectiveSide(rampEl.accessSide, rampEl.rotation);
      return _adjacentWalkCells(
        floor: floorName,
        element: rampEl,
        side: rampSide,
        walkable: walkableSet,
      );
    }

    final links = <GridNode, Set<GridNode>>{};
    for (final r in ramps) {
      final fromId = _readRampField(r, ['from_element_id', 'fromElementId']);
      final toId = _readRampField(r, ['to_element_id', 'toElementId']);
      final fromInfo = fromId != null ? rampElements[fromId] : null;
      final toInfo = toId != null ? rampElements[toId] : null;
      if (fromInfo == null || toInfo == null) continue;

      final rampDir = _readRampField(r, ['direction']) ?? 'two_way';
      if (!['two_way', 'one_way'].contains(rampDir)) {
        throw StateError('Hướng dốc chưa được hỗ trợ: $rampDir');
      }

      final fromPorts = rampRoadPorts(fromInfo);
      final toPorts = rampRoadPorts(toInfo);
      if (fromPorts.isEmpty || toPorts.isEmpty) continue;

      for (final u in fromPorts) {
        for (final v in toPorts) {
          (links[u] ??= <GridNode>{}).add(v);
          if (rampDir == 'two_way') {
            (links[v] ??= <GridNode>{}).add(u);
          }
        }
      }
    }

    int h(GridNode n) {
      if (links.isNotEmpty || n.floor != f) return 0;
      return goals
          .map((g) => (g.x - n.x).abs() + (g.y - n.y).abs())
          .reduce((a, b) => a < b ? a : b);
    }

    final open = starts.toSet();
    final cost = <GridNode, int>{for (final s in starts) s: 0};
    final parent = <GridNode, GridNode>{};
    const moves = [
      (0, -1, 'north'),
      (0, 1, 'south'),
      (-1, 0, 'west'),
      (1, 0, 'east'),
    ];

    while (open.isNotEmpty) {
      final n = open.reduce(
        (a, b) => cost[a]! + h(a) <= cost[b]! + h(b) ? a : b,
      );
      open.remove(n);

      if (goals.contains(n)) {
        final path = <GridNode>[n];
        var p = n;
        while (parent.containsKey(p)) {
          p = parent[p]!;
          path.add(p);
        }
        return path.reversed.toList();
      }

      final next = <GridNode>{...?(links[n])};
      for (final (dx, dy, d) in moves) {
        final v = (floor: n.floor, x: n.x + dx, y: n.y + dy);
        final a = walk[n];
        final b = walk[v];
        if (a != null &&
            b != null &&
            (a.contains('two_way') || a.contains(d)) &&
            (b.contains('two_way') || b.contains(d))) {
          next.add(v);
        }
      }

      for (final v in next) {
        final g = cost[n]! + 1;
        if (g < (cost[v] ?? 0x7fffffff)) {
          cost[v] = g;
          parent[v] = n;
          open.add(v);
        }
      }
    }

    return [];
  }
}
