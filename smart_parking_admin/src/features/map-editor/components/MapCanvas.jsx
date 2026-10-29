
import { useRef } from "react";
import {
  Stage,
  Layer,
  Line,
  Rect,
} from "react-konva";

import MapObject from "./MapObject";
import RoadLayer from "./RoadLayer";

import { GRID_SIZE } from "../constants/mapConfig";
import { getCellsBetween } from "../utils/roadUtils";

export default function MapCanvas({
  objects,
  roadCells,
  mapSize,
  selectedId,
  onSelect,
  onChange,
  tool,
  onPaintRoad,
}) {
  const isPainting = useRef(false);
  const lastCell = useRef(null);

  const canvasWidth = mapSize.columns * GRID_SIZE;
  const canvasHeight = mapSize.rows * GRID_SIZE;

  function getGridPosition(e) {
    const stage = e.target.getStage();
    const pos = stage.getPointerPosition();

    if (!pos) return null;

    const x = Math.floor(pos.x / GRID_SIZE);
    const y = Math.floor(pos.y / GRID_SIZE);

    if (
      x < 0 ||
      y < 0 ||
      x >= mapSize.columns ||
      y >= mapSize.rows
    ) {
      return null;
    }

    return { x, y };
  }

  function handleMouseDown(e) {
    if (tool !== "road" && tool !== "eraser") {
      return;
    }

    if (e.evt.button !== 0) return;

    const cell = getGridPosition(e);
    if (!cell) return;

    isPainting.current = true;
    lastCell.current = cell;

    onPaintRoad([cell], tool === "eraser");
  }

  function handleMouseMove(e) {
    if (!isPainting.current) return;

    const cell = getGridPosition(e);
    if (!cell) return;

    const previous = lastCell.current ?? cell;

    if (
      previous.x === cell.x &&
      previous.y === cell.y
    ) {
      return;
    }

    const points = getCellsBetween(previous, cell);

    onPaintRoad(points, tool === "eraser");
    lastCell.current = cell;
  }

  function handleMouseUp() {
    isPainting.current = false;
    lastCell.current = null;
  }

  return (
    <div className="map-canvas-container">
      <Stage
        width={canvasWidth}
        height={canvasHeight}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
      >
        {/* NỀN BẢN ĐỒ */}
        <Layer>
          <Rect
            width={canvasWidth}
            height={canvasHeight}
            fill="#f8fafc"
          />
        </Layer>

        {/* LỚP ĐƯỜNG */}
        <Layer listening={false}>
          <RoadLayer roadCells={roadCells} />
        </Layer>

        {/* LƯỚI */}
        <Layer listening={false}>
          {Array.from(
            { length: mapSize.columns + 1 },
            (_, index) => (
              <Line
                key={`col-${index}`}
                points={[
                  index * GRID_SIZE,
                  0,
                  index * GRID_SIZE,
                  canvasHeight,
                ]}
                stroke="#dce4eb"
                strokeWidth={0.5}
              />
            )
          )}

          {Array.from(
            { length: mapSize.rows + 1 },
            (_, index) => (
              <Line
                key={`row-${index}`}
                points={[
                  0,
                  index * GRID_SIZE,
                  canvasWidth,
                  index * GRID_SIZE,
                ]}
                stroke="#dce4eb"
                strokeWidth={0.5}
              />
            )
          )}
        </Layer>

        {/* CÁC ĐỐI TƯỢNG */}
        <Layer listening={tool === "select"}>
          {objects.map((obj) => (
            <MapObject
              key={obj.id}
              object={obj}
              selected={
                tool === "select" &&
                obj.id === selectedId
              }
              onSelect={() => onSelect(obj.id)}
              onChange={onChange}
            />
          ))}
        </Layer>
      </Stage>
    </div>
  );
}
