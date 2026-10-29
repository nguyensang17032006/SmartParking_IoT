
import { Rect } from "react-konva";
import { GRID_SIZE } from "../constants/mapConfig";

export default function RoadLayer({ roadCells = [] }) {
    return (
        <>
            {roadCells.map((cell) => (
                <Rect
                    key={`${cell.x}-${cell.y}`}
                    x={cell.x * GRID_SIZE}
                    y={cell.y * GRID_SIZE}
                    width={GRID_SIZE}
                    height={GRID_SIZE}
                    fill="#94a3b8"
                    strokeEnabled={false}
                    listening={false}
                />
            ))}
        </>
    );
}
