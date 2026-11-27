/**
 * Thuật toán A* tìm đường đi đa tầng trong bãi đỗ xe
 * Tuân thủ nghiêm ngặt quy tắc giao thông:
 * 1. Xe CHỈ ĐƯỢC CHẠY TRÊN ĐƯỜNG ĐI (roadCells). Không được đi xuyên tường/xuyên dốc/xuyên ô khác.
 * 2. Cổng vào chỉ ra đường qua cửa cổng (hướng về phía đường đi).
 * 3. Dốc chỉ được đi vào/ra từ mép dốc tiếp giáp với đường đi (không được đâm ngang hông dốc).
 * 4. Ô đỗ xe chỉ được tiếp cận từ đúng cạnh tiếp cận (access_side) theo góc xoay (rotation).
 */

// Tính hướng tiếp cận thực tế trên lưới sau khi ô đỗ bị xoay (rotation: 0, 90, 180, 270)
export function getEffectiveAccessSide(accessSide = "south", rotation = 0) {
  const sides = ["north", "east", "south", "west"];
  let index = sides.indexOf(accessSide);
  if (index === -1) index = 2; // mặc định south

  const steps = Math.round(((rotation % 360) + 360) % 360 / 90);
  const effectiveIndex = (index + steps) % 4;
  return sides[effectiveIndex];
}

// Tính khoảng cách Manhattan
function manhattan(p1, p2) {
  return Math.abs(p1.x - p2.x) + Math.abs(p1.y - p2.y);
}

/**
 * Tìm mép đường đi tiếp giáp với cổng (gate_in / gate_out)
 */
export function getGateRoadPort(gate, roadCells = []) {
  const roadSet = new Set(roadCells.map((c) => `${c.x},${c.y}`));
  const gx = gate.x;
  const gy = gate.y;
  const gw = gate.width || 2;
  const gh = gate.height || 3;
  const effectiveSide = getEffectiveAccessSide(
    gate.access_side || "south",
    gate.rotation || 0
  );

  function getCandidates(side) {
    const candidates = [];
    if (side === "north" || side === "south") {
      const y = side === "north" ? gy - 1 : gy + gh;
      for (let x = gx; x < gx + gw; x++) {
        if (roadSet.has(`${x},${y}`)) candidates.push({ x, y });
      }
    } else {
      const x = side === "west" ? gx - 1 : gx + gw;
      for (let y = gy; y < gy + gh; y++) {
        if (roadSet.has(`${x},${y}`)) candidates.push({ x, y });
      }
    }
    return candidates;
  }

  const preferredCandidates = getCandidates(effectiveSide);
  if (preferredCandidates.length > 0) {
    return preferredCandidates[Math.floor(preferredCandidates.length / 2)];
  }

  const sides = ["north", "east", "south", "west"];
  for (const side of sides) {
    if (side === effectiveSide) continue;
    const candidates = getCandidates(side);
    if (candidates.length > 0) {
      return candidates[Math.floor(candidates.length / 2)];
    }
  }

  if (effectiveSide === "north") {
    return { x: gx + Math.floor(gw / 2), y: gy - 1 };
  }
  if (effectiveSide === "south") {
    return { x: gx + Math.floor(gw / 2), y: gy + gh };
  }
  if (effectiveSide === "west") {
    return { x: gx - 1, y: gy + Math.floor(gh / 2) };
  }
  return { x: gx + gw, y: gy + Math.floor(gh / 2) };
}

/**
 * Tìm cửa ngõ tiếp giáp đường đi của Dốc liên tầng (ramp)
 * Xe chỉ được vào/ra dốc từ mép tiếp giáp đường đi, không được đi xuyên hông dốc!
 */
export function getRampRoadPort(ramp, roadCells = []) {
  const roadSet = new Set(roadCells.map((c) => `${c.x},${c.y}`));
  const rx = ramp.x;
  const ry = ramp.y;
  const rw = ramp.width || 3;
  const rh = ramp.height || 2;
  const effectiveSide = getEffectiveAccessSide(
    ramp.access_side || "west",
    ramp.rotation || 0
  );

  function getCandidates(side) {
    const candidates = [];
    if (side === "north" || side === "south") {
      const roadY = side === "north" ? ry - 1 : ry + rh;
      const insideY = side === "north" ? ry : ry + rh - 1;
      for (let x = rx; x < rx + rw; x++) {
        if (roadSet.has(`${x},${roadY}`)) {
          candidates.push({ x, y: roadY, insideX: x, insideY });
        }
      }
    } else {
      const roadX = side === "west" ? rx - 1 : rx + rw;
      const insideX = side === "west" ? rx : rx + rw - 1;
      for (let y = ry; y < ry + rh; y++) {
        if (roadSet.has(`${roadX},${y}`)) {
          candidates.push({ x: roadX, y, insideX, insideY: y });
        }
      }
    }
    return candidates;
  }

  const preferredCandidates = getCandidates(effectiveSide);
  if (preferredCandidates.length > 0) {
    return preferredCandidates[Math.floor(preferredCandidates.length / 2)];
  }

  const sides = ["north", "east", "south", "west"];
  for (const side of sides) {
    if (side === effectiveSide) continue;
    const candidates = getCandidates(side);
    if (candidates.length > 0) {
      return candidates[Math.floor(candidates.length / 2)];
    }
  }

  if (effectiveSide === "north") {
    return {
      x: rx + Math.floor(rw / 2),
      y: ry - 1,
      insideX: rx + Math.floor(rw / 2),
      insideY: ry,
    };
  }
  if (effectiveSide === "south") {
    return {
      x: rx + Math.floor(rw / 2),
      y: ry + rh,
      insideX: rx + Math.floor(rw / 2),
      insideY: ry + rh - 1,
    };
  }
  if (effectiveSide === "east") {
    return {
      x: rx + rw,
      y: ry + Math.floor(rh / 2),
      insideX: rx + rw - 1,
      insideY: ry + Math.floor(rh / 2),
    };
  }
  return {
    x: rx - 1,
    y: ry + Math.floor(rh / 2),
    insideX: rx,
    insideY: ry + Math.floor(rh / 2),
  };
}

/**
 * Tìm ô đường đi tiếp giáp với vạch vàng (access_side) của ô đỗ xe
 */
export function getSlotEntryPoint(slot, roadCells = []) {
  const roadSet = new Set(roadCells.map((c) => `${c.x},${c.y}`));
  const effectiveSide = getEffectiveAccessSide(
    slot.access_side || "south",
    slot.rotation || 0
  );

  const x = slot.x;
  const y = slot.y;
  const w = slot.width || 2;
  const h = slot.height || 2;

  const candidates = [];

  if (effectiveSide === "south") {
    // Phía dưới ô đỗ
    for (let cx = x; cx < x + w; cx++) {
      if (roadSet.has(`${cx},${y + h}`)) {
        candidates.push({ x: cx, y: y + h });
      }
    }
  } else if (effectiveSide === "north") {
    // Phía trên ô đỗ
    for (let cx = x; cx < x + w; cx++) {
      if (roadSet.has(`${cx},${y - 1}`)) {
        candidates.push({ x: cx, y: y - 1 });
      }
    }
  } else if (effectiveSide === "west") {
    // Phía bên trái ô đỗ
    for (let cy = y; cy < y + h; cy++) {
      if (roadSet.has(`${x - 1},${cy}`)) {
        candidates.push({ x: x - 1, y: cy });
      }
    }
  } else if (effectiveSide === "east") {
    // Phía bên phải ô đỗ
    for (let cy = y; cy < y + h; cy++) {
      if (roadSet.has(`${x + w},${cy}`)) {
        candidates.push({ x: x + w, y: cy });
      }
    }
  }

  if (candidates.length > 0) {
    const mid = Math.floor(candidates.length / 2);
    return candidates[mid];
  }

  // Nếu mép trực tiếp không có đường (do vẽ sát), tìm ô đường gần nhất ở mép tiếp cận
  if (effectiveSide === "south") return { x: x + Math.floor(w / 2), y: y + h };
  if (effectiveSide === "north") return { x: x + Math.floor(w / 2), y: y - 1 };
  if (effectiveSide === "west") return { x: x - 1, y: y + Math.floor(h / 2) };
  return { x: x + w, y: y + Math.floor(h / 2) };
}

/**
 * Thuật toán A* tìm đường đa tầng:
 * Buộc xe PHẢI ĐI TRÊN ĐƯỜNG ĐI, không được đi tắt qua tường hay hông dốc!
 */
export function findPathAStar({
  startNode,
  goalNode,
  floorsData,
  rampConnections = [],
}) {
  if (!startNode || !goalNode || !floorsData) return null;

  // Xây dựng tập ô đường đi (chỉ được đi trên roadCells)
  const walkableByFloor = {};
  const rampPortsByRampId = {};
  const rampFloorMap = {};

  for (const [floorId, fData] of Object.entries(floorsData)) {
    const walkable = new Set();

    // 1. Chỉ thêm các ô ĐƯỜNG ĐI
    for (const r of fData.roadCells || []) {
      walkable.add(`${r.x},${r.y}`);
    }

    // 2. Tìm cửa dốc liên tầng kết nối với đường đi
    for (const obj of fData.objects || []) {
      if (obj.type === "ramp") {
        const port = getRampRoadPort(obj, fData.roadCells || []);
        rampPortsByRampId[obj.id] = {
          ...port,
          rampId: obj.id,
          floorId,
        };
        rampFloorMap[obj.id] = floorId;

        // Cho phép đi ở ô cửa dốc
        walkable.add(`${port.x},${port.y}`);
        walkable.add(`${port.insideX},${port.insideY}`);
      }
    }

    // Đảm bảo điểm bắt đầu và điểm kết thúc có trong tập đi được
    if (startNode.floorId === floorId) {
      walkable.add(`${startNode.x},${startNode.y}`);
    }
    if (goalNode.floorId === floorId) {
      walkable.add(`${goalNode.x},${goalNode.y}`);
    }

    walkableByFloor[floorId] = walkable;
  }

  const nodeKey = (n) => `${n.floorId}:${n.x},${n.y}`;

  const openSet = [startNode];
  const cameFrom = new Map();

  const gScore = new Map();
  gScore.set(nodeKey(startNode), 0);

  const fScore = new Map();
  fScore.set(
    nodeKey(startNode),
    manhattan(startNode, goalNode) +
      (startNode.floorId !== goalNode.floorId ? 40 : 0)
  );

  const closedSet = new Set();

  while (openSet.length > 0) {
    let currentIndex = 0;
    let currentF = fScore.get(nodeKey(openSet[0])) ?? Infinity;

    for (let i = 1; i < openSet.length; i++) {
      const f = fScore.get(nodeKey(openSet[i])) ?? Infinity;
      if (f < currentF) {
        currentF = f;
        currentIndex = i;
      }
    }

    const current = openSet.splice(currentIndex, 1)[0];
    const currentK = nodeKey(current);

    // Đến đích thành công!
    if (
      current.x === goalNode.x &&
      current.y === goalNode.y &&
      current.floorId === goalNode.floorId
    ) {
      return reconstructPath(cameFrom, current);
    }

    closedSet.add(currentK);

    const neighbors = [];
    const floorWalkable = walkableByFloor[current.floorId];

    // 1. Di chuyển 4 hướng trên ĐƯỜNG ĐI của tầng hiện tại
    const deltas = [
      { dx: 0, dy: -1 },
      { dx: 0, dy: 1 },
      { dx: -1, dy: 0 },
      { dx: 1, dy: 0 },
    ];

    for (const d of deltas) {
      const nx = current.x + d.dx;
      const ny = current.y + d.dy;

      // CHỈ ĐI ĐƯỢC NẾU Ô ĐÓ LÀ ĐƯỜNG ĐI!
      if (floorWalkable && floorWalkable.has(`${nx},${ny}`)) {
        neighbors.push({
          node: { x: nx, y: ny, floorId: current.floorId },
          cost: 1,
        });
      }
    }

    // 2. Chuyển tầng qua Dốc liên tầng (chỉ khi đang ở điểm inside của dốc)
    for (const [rampId, port] of Object.entries(rampPortsByRampId)) {
      if (
        port.floorId === current.floorId &&
        current.x === port.insideX &&
        current.y === port.insideY
      ) {
        // Tìm dốc kết nối ở tầng kia
        for (const conn of rampConnections) {
          let targetRampId = null;
          if (conn.from_element_id === rampId) {
            targetRampId = conn.to_element_id;
          } else if (
            conn.to_element_id === rampId &&
            conn.direction === "two_way"
          ) {
            targetRampId = conn.from_element_id;
          }

          if (targetRampId && rampPortsByRampId[targetRampId]) {
            const targetPort = rampPortsByRampId[targetRampId];

            // Chuyển sang điểm trong của dốc ở tầng đích, sau đó xe sẽ đi ra cửa dốc tầng đích
            neighbors.push({
              node: {
                x: targetPort.insideX,
                y: targetPort.insideY,
                floorId: targetPort.floorId,
                isRampTransition: true,
              },
              cost: 6, // Chi phí di chuyển qua độ dốc
            });
          }
        }
      }
    }

    // Đánh giá các láng giềng
    for (const { node: neighbor, cost } of neighbors) {
      const nK = nodeKey(neighbor);
      if (closedSet.has(nK)) continue;

      const tentativeG = (gScore.get(currentK) ?? Infinity) + cost;

      if (tentativeG < (gScore.get(nK) ?? Infinity)) {
        cameFrom.set(nK, current);
        gScore.set(nK, tentativeG);

        const h =
          manhattan(neighbor, goalNode) +
          (neighbor.floorId !== goalNode.floorId ? 40 : 0);

        fScore.set(nK, tentativeG + h);

        if (!openSet.some((n) => nodeKey(n) === nK)) {
          openSet.push(neighbor);
        }
      }
    }
  }

  return null;
}

function reconstructPath(cameFrom, current) {
  const totalPath = [current];
  const nodeKey = (n) => `${n.floorId}:${n.x},${n.y}`;

  let currKey = nodeKey(current);
  while (cameFrom.has(currKey)) {
    current = cameFrom.get(currKey);
    totalPath.unshift(current);
    currKey = nodeKey(current);
  }

  return totalPath;
}
