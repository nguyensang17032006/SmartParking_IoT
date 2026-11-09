export const GRID_SIZE = 32;

export const MAP_COLUMNS = 30;
export const MAP_ROWS = 20;

export const DEFAULT_ROAD_WIDTH = 2;

export const OBJECT_TYPES = {
  slot: {
    label: "Ô đỗ",
    width: 2,
    height: 2,
    color: "#10b981",
  },
  gate_in: {
    label: "Cổng vào",
    width: 2,
    height: 3,
    color: "#3b82f6",
  },
  gate_out: {
    label: "Cổng ra",
    width: 2,
    height: 3,
    color: "#8b5cf6",
  },
  gate: {
    label: "Cổng vào",
    width: 2,
    height: 3,
    color: "#3b82f6",
  },
  ramp: {
    label: "Dốc",
    width: 2,
    height: 3,
    color: "#f59e0b",
  },
  obstacle: {
    label: "Vật cản",
    width: 2,
    height: 2,
    color: "#64748b",
  },
};
