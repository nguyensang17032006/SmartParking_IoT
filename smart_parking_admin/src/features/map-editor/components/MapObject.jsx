import { useEffect, useRef } from "react";
import {
  Group,
  Rect,
  Text,
  Line,
  Transformer,
} from "react-konva";

import {
  GRID_SIZE,
  OBJECT_TYPES,
} from "../constants/mapConfig";

import { snapToGrid } from "../utils/gridUtils";

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

export default function MapObject({
  object,
  selected,
  onSelect,
  onChange,
  onDragStart,
  onDragMove,
  onDragEnd,
}) {
  const groupRef = useRef(null);
  const transformerRef = useRef(null);

  const config = OBJECT_TYPES[object.type] ?? {
    color: "#94a3b8",
  };

  let fillColor = config.color;
  if (object.type === "slot") {
    if (object.status === "occupied") {
      fillColor = "#ef4444";
    } else if (object.status === "maintenance") {
      fillColor = "#f59e0b";
    } else {
      fillColor = "#22c55e";
    }
  }

  const width = object.width * GRID_SIZE;
  const height = object.height * GRID_SIZE;
  const rotation = object.rotation || 0;

  useEffect(() => {
    if (
      selected &&
      groupRef.current &&
      transformerRef.current
    ) {
      transformerRef.current.nodes([groupRef.current]);
      transformerRef.current.getLayer()?.batchDraw();
    }
  }, [selected]);

  function handleTransformEnd() {
    const node = groupRef.current;
    if (!node) return;

    const x = snapToGrid(node.x(), GRID_SIZE);
    const y = snapToGrid(node.y(), GRID_SIZE);

    const newWidth = Math.max(
      1,
      snapToGrid(width * node.scaleX(), GRID_SIZE)
    );

    const newHeight = Math.max(
      1,
      snapToGrid(height * node.scaleY(), GRID_SIZE)
    );

    node.scale({ x: 1, y: 1 });

    const success = onChange(object.id, {
      x,
      y,
      width: newWidth,
      height: newHeight,
    });

    if (!success) {
      node.position({
        x: object.x * GRID_SIZE,
        y: object.y * GRID_SIZE,
      });
    }

    node.getLayer()?.batchDraw();
  }

  return (
    <>
      <Group
        ref={groupRef}
        id={`map-object-${object.id}`}
        name="map-object"
        x={object.x * GRID_SIZE}
        y={object.y * GRID_SIZE}
        draggable
        onClick={onSelect}
        onTap={onSelect}
        onDragStart={() => onDragStart(object.id)}
        onDragMove={(e) =>
          onDragMove(object.id, e.target)
        }
        onDragEnd={(e) =>
          onDragEnd(object.id, e.target)
        }
        onTransformEnd={handleTransformEnd}
      >
        <Group
          x={width / 2}
          y={height / 2}
          offsetX={width / 2}
          offsetY={height / 2}
          rotation={rotation}
        >
          <Rect
            width={width}
            height={height}
            fill={fillColor}
            cornerRadius={5}
            stroke={selected ? "#0f172a" : "#ffffff"}
            strokeWidth={selected ? 2 : 1}
          />

          {["slot", "gate_in", "gate_out", "gate", "ramp"].includes(object.type) && (
            <Line
              points={getAccessSidePoints(
                object.access_side ||
                OBJECT_TYPES[object.type]?.accessSide ||
                "south",
                width,
                height
              )}
              stroke={object.type === "slot" ? "#facc15" : "#22d3ee"}
              strokeWidth={5}
              lineCap="round"
            />
          )}

          {(object.type === "gate_in" || object.type === "gate" || object.type === "gate_out" || object.type === "ramp") && (
            <Text
              x={0}
              y={height - 18}
              width={width}
              height={14}
              text={
                object.type === "gate_out"
                  ? "▼ RA"
                  : object.type === "ramp"
                    ? "▲▼ DỐC"
                    : "▲ VÀO"
              }
              fontSize={10}
              fontStyle="bold"
              fill="#ffffff"
              align="center"
              listening={false}
            />
          )}

          <Text
            width={width}
            height={height}
            text={object.label}
            fontSize={12}
            fontStyle="bold"
            fill="white"
            align="center"
            verticalAlign="middle"
            listening={false}
          />
        </Group>
      </Group>

      {selected && (
        <Transformer
          ref={transformerRef}
          rotateEnabled={false}
          flipEnabled={false}
          anchorSize={9}
          enabledAnchors={[
            "top-left",
            "top-center",
            "top-right",
            "middle-left",
            "middle-right",
            "bottom-left",
            "bottom-center",
            "bottom-right",
          ]}
          boundBoxFunc={(oldBox, newBox) => {
            if (
              newBox.width < GRID_SIZE ||
              newBox.height < GRID_SIZE
            ) {
              return oldBox;
            }

            return newBox;
          }}
        />
      )}
    </>
  );
}
