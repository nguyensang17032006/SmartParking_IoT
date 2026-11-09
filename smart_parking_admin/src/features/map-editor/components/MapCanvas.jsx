import { useRef, useState } from "react";
import { Stage, Layer, Line, Rect } from "react-konva";

import MapObject from "./MapObject";
import RoadLayer from "./RoadLayer";

import { GRID_SIZE } from "../constants/mapConfig";
import { getCellsBetween } from "../utils/roadUtils";
import { snapToGrid } from "../utils/gridUtils";

export default function MapCanvas({
  objects,
  roadCells,
  mapSize,
  selectedIds,
  onSelect,
  onSelectMultiple,
  onChange,
  onMoveSelected,
  tool,
  onPaintRoad,
}) {
  const stageRef = useRef(null);
  const isPainting = useRef(false);
  const lastCell = useRef(null);
  const dragIdsRef = useRef([]);
  const suppressClickRef = useRef(false);

  const [selectionBox, setSelectionBox] = useState(null);
  const selectionStartRef = useRef(null);
  const additiveSelectionRef = useRef(false);

  const canvasWidth = mapSize.columns * GRID_SIZE;
  const canvasHeight = mapSize.rows * GRID_SIZE;

  function getPointer(e) {
    return e.target.getStage()?.getPointerPosition() ?? null;
  }

  function getCell(e) {
    const pos = getPointer(e);
    if (!pos) return null;

    const x = Math.floor(pos.x / GRID_SIZE);
    const y = Math.floor(pos.y / GRID_SIZE);

    if (
      x < 0 || y < 0 ||
      x >= mapSize.columns ||
      y >= mapSize.rows
    ) return null;

    return { x, y };
  }

  function handleMouseDown(e) {
    if (e.evt.button !== 0) return;

    if (tool === "road" || tool === "eraser") {
      const cell = getCell(e);
      if (!cell) return;

      isPainting.current = true;
      lastCell.current = cell;
      onPaintRoad([cell], tool === "eraser");
      return;
    }

    if (tool !== "select") return;

    const isBackground =
      e.target === e.target.getStage() ||
      e.target.name() === "map-background";

    if (!isBackground) return;

    const pos = getPointer(e);
    if (!pos) return;

    selectionStartRef.current = pos;
    additiveSelectionRef.current = e.evt.shiftKey;

    setSelectionBox({
      x: pos.x,
      y: pos.y,
      width: 0,
      height: 0,
    });
  }

  function handleMouseMove(e) {
    if (isPainting.current) {
      const cell = getCell(e);
      if (!cell) return;

      const previous = lastCell.current ?? cell;

      if (
        previous.x !== cell.x ||
        previous.y !== cell.y
      ) {
        onPaintRoad(
          getCellsBetween(previous, cell),
          tool === "eraser"
        );
        lastCell.current = cell;
      }
      return;
    }

    if (!selectionStartRef.current) return;

    const pos = getPointer(e);
    if (!pos) return;

    const start = selectionStartRef.current;

    setSelectionBox({
      x: Math.min(start.x, pos.x),
      y: Math.min(start.y, pos.y),
      width: Math.abs(pos.x - start.x),
      height: Math.abs(pos.y - start.y),
    });
  }

  function handleMouseUp() {
    isPainting.current = false;
    lastCell.current = null;

    if (!selectionStartRef.current) return;

    if (selectionBox) {
      const hasDragged =
        selectionBox.width >= 4 ||
        selectionBox.height >= 4;

      if (hasDragged) {
        const hits = objects
          .filter((obj) => {
            const x = obj.x * GRID_SIZE;
            const y = obj.y * GRID_SIZE;
            const w = obj.width * GRID_SIZE;
            const h = obj.height * GRID_SIZE;

            return (
              x < selectionBox.x + selectionBox.width &&
              x + w > selectionBox.x &&
              y < selectionBox.y + selectionBox.height &&
              y + h > selectionBox.y
            );
          })
          .map((obj) => obj.id);

        onSelectMultiple(
          hits,
          additiveSelectionRef.current
        );
      } else if (!additiveSelectionRef.current) {
        onSelect(null);
      }
    }

    selectionStartRef.current = null;
    setSelectionBox(null);
  }

  function restorePositions() {
    const stage = stageRef.current;
    if (!stage) return;

    for (const obj of objects) {
      const node = stage.findOne(
        `#map-object-${obj.id}`
      );

      if (!node) continue;

      node.position({
        x: obj.x * GRID_SIZE,
        y: obj.y * GRID_SIZE,
      });
    }

    stage.batchDraw();
  }

  function handleDragStart(id) {
    const ids = selectedIds.includes(id)
      ? selectedIds
      : [id];

    dragIdsRef.current = ids;

    if (!selectedIds.includes(id)) {
      onSelect(id);
    }
  }

  function handleDragMove(id, node) {
    const dragged = objects.find((obj) => obj.id === id);
    const stage = stageRef.current;

    if (!dragged || !stage) return;

    const dx = node.x() - dragged.x * GRID_SIZE;
    const dy = node.y() - dragged.y * GRID_SIZE;

    for (const obj of objects) {
      if (
        obj.id === id ||
        !dragIdsRef.current.includes(obj.id)
      ) continue;

      const other = stage.findOne(
        `#map-object-${obj.id}`
      );

      if (!other) continue;

      other.position({
        x: obj.x * GRID_SIZE + dx,
        y: obj.y * GRID_SIZE + dy,
      });
    }

    stage.batchDraw();
  }

  function handleDragEnd(id, node) {
    const x = snapToGrid(node.x(), GRID_SIZE);
    const y = snapToGrid(node.y(), GRID_SIZE);

    const success = onMoveSelected(id, x, y);

    if (!success) {
      restorePositions();
    } else {
      const dragged = objects.find((obj) => obj.id === id);
      const dx = (x - dragged.x) * GRID_SIZE;
      const dy = (y - dragged.y) * GRID_SIZE;

      for (const obj of objects) {
        if (!dragIdsRef.current.includes(obj.id)) continue;

        stageRef.current
          ?.findOne(`#map-object-${obj.id}`)
          ?.position({
            x: obj.x * GRID_SIZE + dx,
            y: obj.y * GRID_SIZE + dy,
          });
      }

      stageRef.current?.batchDraw();
    }

    dragIdsRef.current = [];
    suppressClickRef.current = true;
  }

  function handleObjectSelect(e, id) {
    if (suppressClickRef.current) {
      suppressClickRef.current = false;
      return;
    }

    onSelect(id, e.evt?.shiftKey ?? false);
  }

  return (
    <div className="map-canvas-container">
      <Stage
        ref={stageRef}
        width={canvasWidth}
        height={canvasHeight}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
      >
        <Layer>
          <Rect
            name="map-background"
            width={canvasWidth}
            height={canvasHeight}
            fill="#f8fafc"
          />
        </Layer>

        <Layer listening={false}>
          <RoadLayer roadCells={roadCells} />
        </Layer>

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
                stroke="#e2e8f0"
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
                stroke="#e2e8f0"
                strokeWidth={0.5}
              />
            )
          )}
        </Layer>

        <Layer listening={tool === "select"}>
          {objects.map((obj) => (
            <MapObject
              key={obj.id}
              object={obj}
              selected={selectedIds.includes(obj.id)}
              onSelect={(e) =>
                handleObjectSelect(e, obj.id)
              }
              onChange={onChange}
              onDragStart={handleDragStart}
              onDragMove={handleDragMove}
              onDragEnd={handleDragEnd}
            />
          ))}
        </Layer>

        {selectionBox && (
          <Layer listening={false}>
            <Rect
              x={selectionBox.x}
              y={selectionBox.y}
              width={selectionBox.width}
              height={selectionBox.height}
              fill="rgba(59,130,246,0.12)"
              stroke="#3b82f6"
              dash={[6, 4]}
              strokeWidth={1}
            />
          </Layer>
        )}
      </Stage>
    </div>
  );
}
