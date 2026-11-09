import { useMemo } from "react";
import { Stage, Layer, Rect, Text, Line, Group, Circle } from "react-konva";

const GRID_SIZE = 32;

function getAccessSidePoints(side, w, h) {
  const pad = 4;
  switch (side) {
    case "north":
      return [pad, 3, w - pad, 3];
    case "south":
      return [pad, h - 3, w - pad, h - 3];
    case "west":
      return [3, pad, 3, h - pad];
    case "east":
      return [w - 3, pad, w - 3, h - pad];
    default:
      return [pad, h - 3, w - pad, h - 3];
  }
}

export default function LiveMapCanvas({
  objects = [],
  roadCells = [],
  mapSize = { columns: 30, rows: 20 },
  activePath = [],
  currentFloorId,
  selectedSlot,
  onSelectSlot,
}) {
  const width = mapSize.columns * GRID_SIZE;
  const height = mapSize.rows * GRID_SIZE;

  const currentFloorPath = useMemo(() => {
    return activePath.filter((p) => p.floorId === currentFloorId);
  }, [activePath, currentFloorId]);

  const pathPoints = useMemo(() => {
    if (currentFloorPath.length < 2) return [];
    const pts = [];
    for (const p of currentFloorPath) {
      pts.push(p.x * GRID_SIZE + GRID_SIZE / 2);
      pts.push(p.y * GRID_SIZE + GRID_SIZE / 2);
    }
    return pts;
  }, [currentFloorPath]);

  return (
    <div
      style={{
        overflow: "auto",
        background: "#0f172a",
        padding: "20px",
        borderRadius: "14px",
        boxShadow: "inset 0 2px 8px rgba(0,0,0,0.3)",
        border: "1px solid #334155",
      }}
    >
      <Stage width={width} height={height}>
        <Layer>
          <Rect width={width} height={height} fill="#1e293b" />

          {Array.from({ length: mapSize.columns + 1 }).map((_, i) => (
            <Line
              key={`v-${i}`}
              points={[i * GRID_SIZE, 0, i * GRID_SIZE, height]}
              stroke="#334155"
              strokeWidth={1}
              opacity={0.3}
            />
          ))}
          {Array.from({ length: mapSize.rows + 1 }).map((_, j) => (
            <Line
              key={`h-${j}`}
              points={[0, j * GRID_SIZE, width, j * GRID_SIZE]}
              stroke="#334155"
              strokeWidth={1}
              opacity={0.3}
            />
          ))}

          {roadCells.map((cell, idx) => (
            <Rect
              key={`road-${idx}`}
              x={cell.x * GRID_SIZE}
              y={cell.y * GRID_SIZE}
              width={GRID_SIZE}
              height={GRID_SIZE}
              fill="#475569"
              stroke="#334155"
              strokeWidth={0.5}
            />
          ))}
        </Layer>

        <Layer>
          {objects.map((obj) => {
            const objW = (obj.width || 2) * GRID_SIZE;
            const objH = (obj.height || 2) * GRID_SIZE;
            const rotation = obj.rotation || 0;
            const isSelected = selectedSlot?.id === obj.id;

            let fill = "#64748b";
            if (obj.type === "slot") {
              if (obj.status === "occupied") {
                fill = "#ef4444"; 
              } else if (obj.status === "maintenance") {
                fill = "#f59e0b"; 
              } else {
                fill = "#22c55e"; 
              }
            } else if (obj.type === "gate_in" || obj.type === "gate") {
              fill = "#3b82f6"; 
            } else if (obj.type === "gate_out") {
              fill = "#8b5cf6"; 
            } else if (obj.type === "ramp") {
              fill = "#f97316"; 
            }

            return (
              <Group
                key={obj.id}
                x={obj.x * GRID_SIZE}
                y={obj.y * GRID_SIZE}
                onClick={() => onSelectSlot && onSelectSlot(obj)}
                onTap={() => onSelectSlot && onSelectSlot(obj)}
                style={{ cursor: obj.type === "slot" ? "pointer" : "default" }}
              >
                <Group
                  x={objW / 2}
                  y={objH / 2}
                  offsetX={objW / 2}
                  offsetY={objH / 2}
                  rotation={rotation}
                >
                  <Rect
                    width={objW}
                    height={objH}
                    fill={fill}
                    cornerRadius={5}
                    stroke={isSelected ? "#38bdf8" : "#ffffff"}
                    strokeWidth={isSelected ? 3 : 1}
                    shadowColor={isSelected ? "#38bdf8" : "black"}
                    shadowBlur={isSelected ? 10 : 2}
                    shadowOpacity={isSelected ? 0.8 : 0.2}
                  />

                  {obj.type === "slot" && (
                    <Line
                      points={getAccessSidePoints(
                        obj.access_side || "south",
                        objW,
                        objH
                      )}
                      stroke="#facc15"
                      strokeWidth={4}
                      lineCap="round"
                    />
                  )}

                  {(obj.type === "gate_in" ||
                    obj.type === "gate" ||
                    obj.type === "gate_out" ||
                    obj.type === "ramp") && (
                    <Text
                      x={0}
                      y={objH - 18}
                      width={objW}
                      height={14}
                      text={
                        obj.type === "gate_out"
                          ? "▼ RA"
                          : obj.type === "ramp"
                          ? "▲▼ DỐC"
                          : "▲ VÀO"
                      }
                      fontSize={10}
                      fontStyle="bold"
                      fill="#ffffff"
                      align="center"
                    />
                  )}

                  <Text
                    width={objW}
                    height={objH}
                    text={obj.label || ""}
                    fontSize={12}
                    fontStyle="bold"
                    fill="#ffffff"
                    align="center"
                    verticalAlign="middle"
                  />
                </Group>
              </Group>
            );
          })}
        </Layer>

        {pathPoints.length >= 4 && (
          <Layer>
            <Line
              points={pathPoints}
              stroke="#38bdf8"
              strokeWidth={10}
              opacity={0.3}
              lineCap="round"
              lineJoin="round"
            />
            <Line
              points={pathPoints}
              stroke="#0284c7"
              strokeWidth={4}
              dash={[8, 6]}
              lineCap="round"
              lineJoin="round"
            />

            <Circle
              x={pathPoints[0]}
              y={pathPoints[1]}
              radius={7}
              fill="#22c55e"
              stroke="#ffffff"
              strokeWidth={2}
            />

            <Circle
              x={pathPoints[pathPoints.length - 2]}
              y={pathPoints[pathPoints.length - 1]}
              radius={8}
              fill="#ef4444"
              stroke="#ffffff"
              strokeWidth={2}
            />
          </Layer>
        )}
      </Stage>
    </div>
  );
}
