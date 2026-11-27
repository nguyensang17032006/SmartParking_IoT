import '../../../parking/domain/entities/map_element.dart';

typedef GridNode = ({String floor, int x, int y});

class AStarPathfinder {
  const AStarPathfinder();

  List<GridNode> find({required Map<String, List<MapElement>> floors,
    required List<Map<String, dynamic>> ramps, required String slotId}) {
    final walk = <GridNode, Set<String>>{};
    final blocked = <GridNode>{};
    final starts = <GridNode>{};
    final rampCells = <String, List<GridNode>>{};
    final goals = <GridNode>{};
    MapElement? target;
    String? targetFloor;
    for (final entry in floors.entries) {
      for (final e in entry.value) {
        if (e.rotation % 360 != 0) {
          throw StateError('Bản đồ có phần tử xoay chưa được hỗ trợ.');
        }
        final cells = <GridNode>[
          for (int y=e.y; y<e.y+e.height; y++)
            for (int x=e.x; x<e.x+e.width; x++) (floor:entry.key,x:x,y:y),
        ];
        if (e.type == 'slot' || e.type == 'obstacle' || e.type == 'wall') {
          blocked.addAll(cells);
        }
        if (e.type == 'slot' && e.slotId == slotId) {
          target=e; targetFloor=entry.key;
        }
        if (['road','ramp','gate_in','gate_out'].contains(e.type)) {
          if (!['two_way','north','south','east','west'].contains(e.direction)) {
            throw StateError('Hướng lưu thông chưa được hỗ trợ: ${e.direction}');
          }
          for (final c in cells) {
            (walk[c] ??= <String>{}).add(e.direction);
          }
          if (e.type=='gate_in') starts.addAll(cells);
          if (e.type=='ramp') rampCells[e.id]=cells;
        }
      }
    }
    for (final c in blocked) { walk.remove(c); }
    starts.retainAll(walk.keys.toSet());
    final t=target; final f=targetFloor;
    if (t==null || f==null || starts.isEmpty) return [];
    final side=t.accessSide;
    for (int y=t.y; y<t.y+t.height; y++) {
      for (int x=t.x; x<t.x+t.width; x++) {
        final GridNode? n=switch(side) {
          'north' when y==t.y => (floor:f,x:x,y:y-1),
          'south' when y==t.y+t.height-1 => (floor:f,x:x,y:y+1),
          'west' when x==t.x => (floor:f,x:x-1,y:y),
          'east' when x==t.x+t.width-1 => (floor:f,x:x+1,y:y),
          _ => null,
        };
        if(n!=null && walk.containsKey(n)) goals.add(n);
      }
    }
    if(goals.isEmpty) return [];
    final links=<GridNode,Set<GridNode>>{};
    for(final r in ramps){
      final a=rampCells[r['from_element_id']]; final b=rampCells[r['to_element_id']];
      if(a==null || b==null) continue;
      if(r['direction']!='two_way') throw StateError('Hướng dốc chưa được hỗ trợ.');
      for(final u in a.where(walk.containsKey)) {
        for(final v in b.where(walk.containsKey)) {
          (links[u]??=<GridNode>{}).add(v); (links[v]??=<GridNode>{}).add(u);
        }
      }
    }
    // Manhattan is admissible without ramp shortcuts; otherwise use zero.
    int h(GridNode n) {
      if(links.isNotEmpty || n.floor!=f) return 0;
      return goals.map((g)=>(g.x-n.x).abs()+(g.y-n.y).abs()).reduce((a,b)=>a<b?a:b);
    }
    final open=starts.toSet(); final cost={for(final s in starts) s:0};
    final parent=<GridNode,GridNode>{};
    const moves=[(0,-1,'north'),(0,1,'south'),(-1,0,'west'),(1,0,'east')];
    while(open.isNotEmpty){
      final n=open.reduce((a,b)=>cost[a]!+h(a)<=cost[b]!+h(b)?a:b);
      open.remove(n);
      if(goals.contains(n)){
        final path=<GridNode>[n]; var p=n;
        while(parent.containsKey(p)){p=parent[p]!;path.add(p);}
        return path.reversed.toList();
      }
      final next=<GridNode>{...?(links[n])};
      for(final (dx,dy,d) in moves){
        final v=(floor:n.floor,x:n.x+dx,y:n.y+dy);
        final a=walk[n]!; final b=walk[v];
        if(b!=null && (a.contains('two_way')||a.contains(d)) && (b.contains('two_way')||b.contains(d))) next.add(v);
      }
      for(final v in next){
        final g=cost[n]!+1;
        if(g<(cost[v]??0x7fffffff)){cost[v]=g;parent[v]=n;open.add(v);}
      }
    }
    return [];
  }
}
