
import { useEffect, useRef } from "react";
import {
  Group,
  Rect,
  Text,
  Transformer,
} from "react-konva";

import {
  GRID_SIZE,
  OBJECT_TYPES,
} from "../constants/mapConfig";

import { snapToGrid } from "../utils/gridUtils";

export default function MapObject({
  object,
  selected,
  onSelect,
  onChange,
}) {
  const groupRef = useRef(null);
  const transformerRef = useRef(null);

  const config = OBJECT_TYPES[object.type] || { color: "#94a3b8", label: "" };
  const width = (object.width || 1) * GRID_SIZE;
  const height = (object.height || 1) * GRID_SIZE;

  useEffect(() => {
    if (selected && groupRef.current && transformerRef.current) {
      transformerRef.current.nodes([groupRef.current]);
      transformerRef.current.getLayer()?.batchDraw();
    }
  }, [selected]);

  function handleDragEnd(e) {
    const node = e.target;

    const x = snapToGrid(node.x(), GRID_SIZE);
    const y = snapToGrid(node.y(), GRID_SIZE);

    const success = onChange(object.id, { x, y });

    if (!success) {
      node.position({
        x: object.x * GRID_SIZE,
        y: object.y * GRID_SIZE,
      });
    }
  }

  function handleTransformEnd() {
    const node = groupRef.current;

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

    // Reset scale sau khi resize
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
  }

  return (
    <>
      <Group
        ref={groupRef}
        x={object.x * GRID_SIZE}
        y={object.y * GRID_SIZE}
        draggable
        onClick={onSelect}
        onTap={onSelect}
        onDragEnd={handleDragEnd}
        onTransformEnd={handleTransformEnd}
      >
        <Rect
          width={width}
          height={height}
          fill={config.color}
          cornerRadius={5}
          stroke={selected ? "#0f172a" : "#ffffff"}
          strokeWidth={selected ? 2 : 1}
        />

        <Text
          width={width}
          height={height}
          text={object.label}
          fontSize={12}
          fontStyle="bold"
          fill="#ffffff"
          align="center"
          verticalAlign="middle"
          listening={false}
        />
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
