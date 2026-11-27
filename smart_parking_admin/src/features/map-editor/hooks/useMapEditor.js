import { useState } from "react";
import toast from "react-hot-toast";

import {
  MAP_COLUMNS,
  MAP_ROWS,
  OBJECT_TYPES,
  DEFAULT_ROAD_WIDTH,
} from "../constants/mapConfig";

import {
  canPlaceObject,
  isInsideMap,
} from "../utils/gridUtils";

import {
  roadKey,
  getBrushCells,
} from "../utils/roadUtils";

const DEFAULT_MAP_SIZE = {
  columns: MAP_COLUMNS,
  rows: MAP_ROWS,
};

// ====================================
// ĐỌC BẢN NHÁP THEO TỪNG TẦNG
// ====================================

function loadDraft(storageKey) {
  try {
    const saved = localStorage.getItem(storageKey);

    if (saved) {
      const parsed = JSON.parse(saved);

      const parsedZones =
        Array.isArray(parsed.zones) && parsed.zones.length > 0
          ? parsed.zones
          : [
              {
                id: crypto.randomUUID(),
                code: "A",
                name: "Khu A",
                color: "#10b981",
              },
            ];

      // Đảm bảo các ô đỗ xe đều có zone_id và trạng thái
      const parsedObjects = (
        Array.isArray(parsed.objects) ? parsed.objects : []
      ).map((obj) => {
        const defaultAccessSide = OBJECT_TYPES[obj.type]?.accessSide;
        const accessSide = ["north", "south", "east", "west"].includes(
          obj.access_side
        )
          ? obj.access_side
          : defaultAccessSide;

        if (obj.type === "slot") {
          const zone =
            parsedZones.find((z) => z.id === obj.zone_id) || parsedZones[0];
          return {
            ...obj,
            zone_id: zone?.id || obj.zone_id,
            zone_code: zone?.code || obj.zone_code || "A",
            status: obj.status || "available",
            access_side: accessSide,
          };
        }
        return defaultAccessSide ? { ...obj, access_side: accessSide } : obj;
      });

      return {
        objects: parsedObjects,
        roadCells: Array.isArray(parsed.roadCells) ? parsed.roadCells : [],
        mapSize: parsed.mapSize ?? { ...DEFAULT_MAP_SIZE },
        zones: parsedZones,
      };
    }
  } catch (error) {
    console.error("Lỗi tải bản đồ:", error);
  }

  const defaultZoneId = crypto.randomUUID();
  return {
    objects: [],
    roadCells: [],
    mapSize: { ...DEFAULT_MAP_SIZE },
    zones: [
      {
        id: defaultZoneId,
        code: "A",
        name: "Khu A",
        color: "#10b981",
      },
    ],
  };
}

// ====================================
// CUSTOM HOOK MAP EDITOR
// ====================================

export default function useMapEditor(floorId = "T1") {
  const storageKey = `smartparking_map_draft_${floorId}`;

  const [initial] = useState(() => loadDraft(storageKey));

  // Dữ liệu bản đồ
  const [objects, setObjects] = useState(initial.objects);
  const [roadCells, setRoadCells] = useState(initial.roadCells);
  const [mapSize, setMapSize] = useState(initial.mapSize);

  // Phân khu (Zones) của tầng này
  const [zones, setZones] = useState(initial.zones);
  const [activeZoneId, setActiveZoneId] = useState(
    () => initial.zones?.[0]?.id || null
  );

  function addZone({ code, name }) {
    const newCode = (code || "A").toUpperCase();
    const newZone = {
      id: crypto.randomUUID(),
      code: newCode,
      name: name || `Khu ${newCode}`,
      color: "#22c55e",
    };

    setZones((prev) => [...prev, newZone]);
    setActiveZoneId(newZone.id);
    return newZone;
  }

  function updateZone(zoneId, updates) {
    setZones((prev) =>
      prev.map((z) => (z.id === zoneId ? { ...z, ...updates } : z))
    );

    // Đồng bộ mã khu cho các ô đỗ thuộc khu này nếu mã đổi
    if (updates.code) {
      setObjects((prev) =>
        prev.map((obj) => {
          if (obj.type === "slot" && obj.zone_id === zoneId) {
            return {
              ...obj,
              zone_code: updates.code,
            };
          }
          return obj;
        })
      );
    }
  }

  function deleteZone(zoneId) {
    if (zones.length <= 1) {
      toast.error("Mỗi tầng cần có ít nhất một phân khu (Zone)!");
      return false;
    }

    const remainingZones = zones.filter((z) => z.id !== zoneId);
    const fallbackZone = remainingZones[0];

    setZones(remainingZones);

    if (activeZoneId === zoneId) {
      setActiveZoneId(fallbackZone.id);
    }

    // Chuyển các ô đỗ thuộc khu bị xóa sang khu còn lại
    setObjects((prev) =>
      prev.map((obj) => {
        if (obj.type === "slot" && obj.zone_id === zoneId) {
          return {
            ...obj,
            zone_id: fallbackZone.id,
            zone_code: fallbackZone.code,
          };
        }
        return obj;
      })
    );

    toast.success("Đã xóa phân khu!");
    return true;
  }

  // Chọn nhiều đối tượng
  const [selectedIds, setSelectedIds] = useState([]);

  // Công cụ đang sử dụng
  const [tool, setTool] = useState("select");

  const [roadWidth, setRoadWidth] = useState(DEFAULT_ROAD_WIDTH);

  const [message, setMessage] = useState("");

  // Chỉ hiện thuộc tính khi chọn 1 đối tượng
  const selectedObject =
    selectedIds.length === 1
      ? objects.find((obj) => obj.id === selectedIds[0]) ?? null
      : null;

  // ====================================
  // 1. CHỌN MỘT / NHIỀU ĐỐI TƯỢNG
  // ====================================

  function selectObject(id, multiSelect = false) {
    if (!multiSelect) {
      setSelectedIds(id ? [id] : []);
      return;
    }

    if (!id) return;

    setSelectedIds((prev) => {
      if (prev.includes(id)) {
        return prev.filter((item) => item !== id);
      }

      return [...prev, id];
    });
  }

  function selectMultiple(ids, additive = false) {
    const validIds = new Set(objects.map((obj) => obj.id));

    const nextIds = ids.filter((id) => validIds.has(id));

    setSelectedIds((prev) => {
      if (!additive) {
        return [...new Set(nextIds)];
      }

      return [...new Set([...prev, ...nextIds])];
    });
  }

  function clearSelection() {
    setSelectedIds([]);
  }

  // ====================================
  // 2. THÊM Ô ĐỖ, CỔNG, DỐC
  // ====================================

  function addObject(type) {
    const config = OBJECT_TYPES[type];

    if (!config) return false;

    const count = objects.filter((obj) => obj.type === type).length + 1;

    let label = `${config.label} ${count}`;
    let zoneId = null;
    let zoneCode = "A";

    // Tạo mã ô đỗ A01, A02... theo Zone đang chọn không trùng
    if (type === "slot") {
      const activeZone =
        zones.find((z) => z.id === activeZoneId) || zones[0];
      if (activeZone) {
        zoneId = activeZone.id;
        zoneCode = activeZone.code || "A";
      }

      let number = 1;
      while (
        objects.some(
          (obj) =>
            obj.type === "slot" &&
            obj.label === `${zoneCode}${String(number).padStart(2, "0")}`
        )
      ) {
        number++;
      }

      label = `${zoneCode}${String(number).padStart(2, "0")}`;
    }

    const newObject = {
      id: crypto.randomUUID(),
      type,
      label,
      zone_id: type === "slot" ? zoneId : null,
      zone_code: type === "slot" ? zoneCode : null,
      status: type === "slot" ? "available" : undefined,
      vehicle_type: type === "slot" ? "car" : undefined,
      direction: "two_way",
      access_side: config.accessSide,
      x: 0,
      y: 0,
      width: config.width,
      height: config.height,
      rotation: 0,
    };

    // Tìm vị trí trống đầu tiên
    for (let y = 0; y < mapSize.rows; y++) {
      for (let x = 0; x < mapSize.columns; x++) {
        const candidate = {
          ...newObject,
          x,
          y,
        };

        if (
          canPlaceObject(candidate, objects, mapSize, roadCells)
        ) {
          setObjects((prev) => [...prev, candidate]);

          // Chọn ngay đối tượng vừa tạo
          setSelectedIds([candidate.id]);
          setTool("select");
          setMessage("");

          return true;
        }
      }
    }

    toast.error("Không còn vị trí hợp lệ trên bản đồ");
    return false;
  }

  // ====================================
  // 3. CẬP NHẬT ĐỐI TƯỢNG
  // ====================================

  function updateObject(id, changes) {
    const current = objects.find((obj) => obj.id === id);

    if (!current) return false;

    let zoneChanges = {};
    if (changes.zone_id && changes.zone_id !== current.zone_id) {
      const targetZone = zones.find((z) => z.id === changes.zone_id);
      if (targetZone) {
        zoneChanges = {
          zone_id: targetZone.id,
          zone_code: targetZone.code,
        };
      }
    }

    const candidate = {
      ...current,
      ...changes,
      ...zoneChanges,
    };

    if (
      !canPlaceObject(candidate, objects, mapSize, roadCells)
    ) {
      setMessage("Đối tượng bị chồng lấn hoặc vượt bản đồ");
      return false;
    }

    // Không cho trùng mã ô đỗ trong cùng tầng
    if (candidate.type === "slot") {
      const duplicated = objects.some(
        (obj) =>
          obj.id !== id &&
          obj.type === "slot" &&
          obj.label === candidate.label
      );

      if (duplicated) {
        setMessage("Mã ô đỗ đã tồn tại trong tầng này");
        return false;
      }
    }

    setObjects((prev) =>
      prev.map((obj) => (obj.id === id ? candidate : obj))
    );

    setMessage("");
    return true;
  }

  // ====================================
  // 4. XÓA MỘT ĐỐI TƯỢNG
  // ====================================

  function deleteObject(id) {
    if (!id) return;

    setObjects((prev) => prev.filter((obj) => obj.id !== id));

    setSelectedIds((prev) => prev.filter((item) => item !== id));

    setMessage("");
  }

  // ====================================
  // 5. XÓA TOÀN BỘ NHÓM ĐANG CHỌN
  // ====================================

  function deleteSelectedObjects() {
    if (selectedIds.length === 0) return false;

    const idSet = new Set(selectedIds);

    setObjects((prev) => prev.filter((obj) => !idSet.has(obj.id)));

    setSelectedIds([]);
    setMessage("");

    return true;
  }

  // ====================================
  // 6. DI CHUYỂN CẢ NHÓM ĐỐI TƯỢNG
  // ====================================

  function moveSelectedObjects(draggedId, newX, newY) {
    const dragged = objects.find((obj) => obj.id === draggedId);

    if (!dragged) return false;

    // Nếu kéo đối tượng đã được chọn,
    // di chuyển toàn bộ nhóm đang chọn.
    const movingIds = selectedIds.includes(draggedId)
      ? selectedIds
      : [draggedId];

    const dx = newX - dragged.x;
    const dy = newY - dragged.y;

    if (dx === 0 && dy === 0) return true;

    const movingSet = new Set(movingIds);

    const movingObjects = objects.filter((obj) =>
      movingSet.has(obj.id)
    );

    const stationaryObjects = objects.filter(
      (obj) => !movingSet.has(obj.id)
    );

    const nextMovingObjects = movingObjects.map((obj) => ({
      ...obj,
      x: obj.x + dx,
      y: obj.y + dy,
    }));

    // Kiểm tra với các đối tượng đứng yên
    // Không coi các ô cùng nhóm là vật cản.
    const valid = nextMovingObjects.every((obj) =>
      canPlaceObject(obj, stationaryObjects, mapSize, roadCells)
    );

    if (!valid) {
      setMessage(
        "Không thể di chuyển: Nhóm bị chồng lấn hoặc vượt bản đồ"
      );
      return false;
    }

    const movedMap = new Map(
      nextMovingObjects.map((obj) => [obj.id, obj])
    );

    // Cập nhật toàn bộ nhóm cùng lúc
    setObjects((prev) =>
      prev.map((obj) => movedMap.get(obj.id) ?? obj)
    );

    setMessage("");
    return true;
  }

  // ====================================
  // 7. VẼ / XÓA ĐƯỜNG
  // ====================================

  function paintRoad(points, erase = false) {
    setRoadCells((prev) => {
      const roadMap = new Map(
        prev.map((cell) => [roadKey(cell.x, cell.y), cell])
      );

      for (const point of points) {
        const cells = getBrushCells(
          point.x,
          point.y,
          roadWidth,
          mapSize,
          objects
        );

        for (const cell of cells) {
          const key = roadKey(cell.x, cell.y);

          if (erase) {
            roadMap.delete(key);
          } else {
            roadMap.set(key, cell);
          }
        }
      }

      return Array.from(roadMap.values());
    });
  }

  // ====================================
  // 8. THAY ĐỔI KÍCH THƯỚC BẢN ĐỒ
  // ====================================

  function updateMapSize(columns, rows) {
    const nextSize = {
      columns: Number(columns),
      rows: Number(rows),
    };

    if (
      !Number.isInteger(nextSize.columns) ||
      !Number.isInteger(nextSize.rows) ||
      nextSize.columns < 2 ||
      nextSize.rows < 2 ||
      nextSize.columns > 200 ||
      nextSize.rows > 200
    ) {
      toast.error("Kích thước bản đồ phải từ 2 đến 200 ô");
      return false;
    }

    const invalidObject = objects.some(
      (obj) => !isInsideMap(obj, nextSize)
    );

    const invalidRoad = roadCells.some(
      (cell) =>
        cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= nextSize.columns ||
        cell.y >= nextSize.rows
    );

    if (invalidObject || invalidRoad) {
      toast.error(
        "Không thể thu nhỏ vì có đối tượng hoặc đường nằm ngoài"
      );
      return false;
    }

    setMapSize(nextSize);
    setMessage("");

    toast.success("Đã cập nhật kích thước bản đồ");
    return true;
  }

  // ====================================
  // 9. GIẢM MÉP BẢN ĐỒ
  // ====================================

  function trimMapEdge(edge) {
    const validEdges = ["left", "right", "top", "bottom"];

    if (!validEdges.includes(edge)) return false;

    const horizontal = edge === "left" || edge === "right";

    if (
      (horizontal && mapSize.columns <= 2) ||
      (!horizontal && mapSize.rows <= 2)
    ) {
      toast.error("Bản đồ phải có ít nhất 2 hàng/cột");
      return false;
    }

    const nextSize = {
      columns: mapSize.columns - (horizontal ? 1 : 0),
      rows: mapSize.rows - (horizontal ? 0 : 1),
    };

    const offsetX = edge === "left" ? 1 : 0;
    const offsetY = edge === "top" ? 1 : 0;

    const nextObjects = objects.map((obj) => ({
      ...obj,
      x: obj.x - offsetX,
      y: obj.y - offsetY,
    }));

    const nextRoadCells = roadCells.map((cell) => ({
      x: cell.x - offsetX,
      y: cell.y - offsetY,
    }));

    const invalidObject = nextObjects.some(
      (obj) => !isInsideMap(obj, nextSize)
    );

    const invalidRoad = nextRoadCells.some(
      (cell) =>
        cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= nextSize.columns ||
        cell.y >= nextSize.rows
    );

    if (invalidObject || invalidRoad) {
      toast.error("Không thể giảm mép vì có đối tượng hoặc đường đi");
      return false;
    }

    setObjects(nextObjects);
    setRoadCells(nextRoadCells);
    setMapSize(nextSize);
    setMessage("");

    toast.success("Đã giảm 1 hàng/cột bản đồ");
    return true;
  }

  // ====================================
  // 10. LƯU BẢN NHÁP THEO TẦNG
  // ====================================

  function saveDraft(showToast = true) {
    try {
      const draft = {
        mapSize,
        objects,
        roadCells,
        zones,
      };

      localStorage.setItem(storageKey, JSON.stringify(draft));

      if (showToast) {
        toast.success(`Đã lưu bản đồ tầng ${floorId}!`);
      }

      return true;
    } catch (error) {
      console.error("Lỗi lưu bản đồ:", error);

      if (showToast) {
        toast.error("Không thể lưu bản nháp");
      }

      return false;
    }
  }

  // ====================================
  // TRẢ VỀ STATE VÀ CÁC HÀM
  // ====================================

  return {
    objects,
    roadCells,
    mapSize,

    // Quản lý Zones (khu vực)
    zones,
    setZones,
    activeZoneId,
    setActiveZoneId,
    addZone,
    updateZone,
    deleteZone,

    selectedIds,
    selectedObject,
    selectObject,
    selectMultiple,
    clearSelection,

    tool,
    setTool,
    roadWidth,
    setRoadWidth,
    message,

    addObject,
    updateObject,
    deleteObject,
    deleteSelectedObjects,
    moveSelectedObjects,

    paintRoad,
    updateMapSize,
    trimMapEdge,
    saveDraft,
  };
}
