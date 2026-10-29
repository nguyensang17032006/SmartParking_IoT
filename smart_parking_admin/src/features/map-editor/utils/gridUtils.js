
import {
  MAP_COLUMNS,
  MAP_ROWS,
} from "../constants/mapConfig";

export function snapToGrid(pixel, gridSize) {
  return Math.round(pixel / gridSize);
}

export function isInsideMap(obj, mapSize) {
  return (
    obj.x >= 0 &&
    obj.y >= 0 &&
    obj.width >= 1 &&
    obj.height >= 1 &&
    obj.x + obj.width <= mapSize.columns &&
    obj.y + obj.height <= mapSize.rows
  );
}

export function canPlaceObject(
  candidate,
  objects,
  mapSize,
  roadCells = []
) {
  if (!isInsideMap(candidate, mapSize)) {
    return false;
  }

  const overlapObject = objects.some((obj) => {
    if (obj.id === candidate.id) return false;

    return isOverlapping(candidate, obj);
  });

  if (overlapObject) return false;

  const overlapRoad = roadCells.some((cell) => {
    return (
      cell.x >= candidate.x &&
      cell.x < candidate.x + candidate.width &&
      cell.y >= candidate.y &&
      cell.y < candidate.y + candidate.height
    );
  });

  return !overlapRoad;
}

export function isOverlapping(a, b) {
  return (
    a.x < b.x + b.width &&
    a.x + a.width > b.x &&
    a.y < b.y + b.height &&
    a.y + a.height > b.y
  );
}

