
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

// Đọc bản đồ đã lưu của từng tầng
function loadDraft(storageKey) {
  try {
    const saved = localStorage.getItem(storageKey);

    if (saved) {
      const parsed = JSON.parse(saved);

      return {
        objects: parsed.objects ?? [],
        roadCells: parsed.roadCells ?? [],
        mapSize: parsed.mapSize ?? DEFAULT_MAP_SIZE,
      };
    }
  } catch (error) {
    console.error("Lỗi tải bản đồ:", error);
  }

  return {
    objects: [],
    roadCells: [],
    mapSize: { ...DEFAULT_MAP_SIZE },
  };
}

export default function useMapEditor(floorId = "T1") {
  // Mỗi tầng có một storage key riêng
  const storageKey = `smartparking_map_draft_v3_${floorId}`;

  const [initial] = useState(() => loadDraft(storageKey));

  const [objects, setObjects] = useState(initial.objects);
  const [roadCells, setRoadCells] = useState(
    initial.roadCells
  );
  const [mapSize, setMapSize] = useState(initial.mapSize);

  const [selectedId, setSelectedId] = useState(null);
  const [tool, setTool] = useState("select");

  const [roadWidth, setRoadWidth] = useState(
    DEFAULT_ROAD_WIDTH
  );

  const [message, setMessage] = useState("");

  const selectedObject =
    objects.find((obj) => obj.id === selectedId) ?? null;

  // ================================
  // 1. THÊM ĐỐI TƯỢNG
  // ================================

  function addObject(type) {
    const config = OBJECT_TYPES[type];

    if (!config) return false;

    const count =
      objects.filter((obj) => obj.type === type).length + 1;

    // Tìm mã ô đỗ không bị trùng
    let label = `${config.label} ${count}`;

    if (type === "slot") {
      let number = 1;

      while (
        objects.some(
          (obj) =>
            obj.type === "slot" &&
            obj.label === `A${String(number).padStart(2, "0")}`
        )
      ) {
        number++;
      }

      label = `A${String(number).padStart(2, "0")}`;
    }

    const next = {
      id: crypto.randomUUID(),
      type,
      label,
      x: 0,
      y: 0,
      width: config.width,
      height: config.height,
      rotation: 0,
    };

    for (let y = 0; y < mapSize.rows; y++) {
      for (let x = 0; x < mapSize.columns; x++) {
        const candidate = { ...next, x, y };

        if (
          canPlaceObject(
            candidate,
            objects,
            mapSize,
            roadCells
          )
        ) {
          setObjects((prev) => [...prev, candidate]);
          setSelectedId(candidate.id);
          setTool("select");
          setMessage("");

          return true;
        }
      }
    }

    toast.error("Không còn vị trí hợp lệ trên bản đồ");
    return false;
  }

  // ================================
  // 2. CẬP NHẬT ĐỐI TƯỢNG
  // ================================

  function updateObject(id, changes) {
    const current = objects.find((obj) => obj.id === id);

    if (!current) return false;

    const candidate = {
      ...current,
      ...changes,
    };

    if (
      !canPlaceObject(
        candidate,
        objects,
        mapSize,
        roadCells
      )
    ) {
      setMessage(
        "Đối tượng bị chồng lấn hoặc vượt bản đồ"
      );

      return false;
    }

    // Không cho mã ô đỗ trùng nhau trong cùng tầng
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
      prev.map((obj) =>
        obj.id === id ? candidate : obj
      )
    );

    setMessage("");
    return true;
  }

  // ================================
  // 3. XÓA ĐỐI TƯỢNG
  // ================================

  function deleteObject(id) {
    setObjects((prev) =>
      prev.filter((obj) => obj.id !== id)
    );

    setSelectedId(null);
    setMessage("");
  }

  // ================================
  // 4. VẼ / XÓA ĐƯỜNG
  // ================================

  function paintRoad(points, erase = false) {
    setRoadCells((prev) => {
      const roadMap = new Map(
        prev.map((cell) => [
          roadKey(cell.x, cell.y),
          cell,
        ])
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

  // ================================
  // 5. THAY ĐỔI KÍCH THƯỚC BẢN ĐỒ
  // ================================

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
      toast.error(
        "Kích thước bản đồ phải từ 2 đến 200 ô"
      );
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

  // ================================
  // 6. GIẢM MÉP BẢN ĐỒ
  // ================================

  function trimMapEdge(edge) {
    const validEdges = [
      "left",
      "right",
      "top",
      "bottom",
    ];

    if (!validEdges.includes(edge)) {
      return false;
    }

    const horizontal =
      edge === "left" || edge === "right";

    if (
      (horizontal && mapSize.columns <= 2) ||
      (!horizontal && mapSize.rows <= 2)
    ) {
      toast.error("Bản đồ phải có ít nhất 2 hàng/cột");
      return false;
    }

    const nextSize = {
      columns:
        mapSize.columns - (horizontal ? 1 : 0),
      rows:
        mapSize.rows - (horizontal ? 0 : 1),
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
      toast.error(
        "Không thể giảm mép vì có đối tượng hoặc đường đi"
      );
      return false;
    }

    setObjects(nextObjects);
    setRoadCells(nextRoadCells);
    setMapSize(nextSize);

    setMessage("");

    toast.success("Đã giảm 1 hàng/cột bản đồ");
    return true;
  }

  function saveDraft(showToast = true) {
    try {
      const draft = {
        mapSize,
        objects,
        roadCells,
      };

      localStorage.setItem(
        storageKey,
        JSON.stringify(draft)
      );

      if (showToast) {
        toast.success(
          `Đã lưu bản đồ tầng ${floorId}!`
        );
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

  return {
    objects,
    roadCells,
    mapSize,

    selectedId,
    setSelectedId,
    selectedObject,

    tool,
    setTool,
    roadWidth,
    setRoadWidth,

    message,

    addObject,
    updateObject,
    deleteObject,
    paintRoad,
    updateMapSize,
    trimMapEdge,
    saveDraft,
  };
}
