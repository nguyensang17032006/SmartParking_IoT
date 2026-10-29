
import { useEffect, useState } from "react";
import {
    Maximize2,
    ArrowLeft,
    ArrowRight,
    ArrowUp,
    ArrowDown,
} from "lucide-react";

export default function MapSizePanel({
    mapSize,
    onChange,
    onTrimEdge,
}) {
    const [columns, setColumns] = useState(
        String(mapSize.columns)
    );

    const [rows, setRows] = useState(
        String(mapSize.rows)
    );

    useEffect(() => {
        setColumns(String(mapSize.columns));
        setRows(String(mapSize.rows));
    }, [mapSize.columns, mapSize.rows]);

    function handleApply(e) {
        e.preventDefault();

        const nextColumns = Number(columns);
        const nextRows = Number(rows);

        if (
            !Number.isInteger(nextColumns) ||
            !Number.isInteger(nextRows) ||
            nextColumns < 2 ||
            nextRows < 2 ||
            nextColumns > 200 ||
            nextRows > 200
        ) {
            alert("Số hàng/cột phải từ 2 đến 200");
            return;
        }

        onChange(nextColumns, nextRows);
    }

    return (
        <div className="map-size-panel">
            <div className="map-size-title">
                <Maximize2 size={18} />
                <strong>Kích thước bản đồ</strong>
            </div>

            <form
                className="map-size-form"
                onSubmit={handleApply}
            >
                <label>
                    Số cột
                    <input
                        type="number"
                        min="2"
                        max="200"
                        value={columns}
                        onChange={(e) =>
                            setColumns(e.target.value)
                        }
                    />
                </label>

                <label>
                    Số hàng
                    <input
                        type="number"
                        min="2"
                        max="200"
                        value={rows}
                        onChange={(e) =>
                            setRows(e.target.value)
                        }
                    />
                </label>

                <button type="submit">
                    Áp dụng
                </button>
            </form>

            <div className="map-edge-controls">
                <button
                    type="button"
                    onClick={() => onTrimEdge("left")}
                    disabled={mapSize.columns <= 2}
                >
                    <ArrowLeft size={16} />
                    Giảm cột trái
                </button>

                <button
                    type="button"
                    onClick={() => onTrimEdge("right")}
                    disabled={mapSize.columns <= 2}
                >
                    <ArrowRight size={16} />
                    Giảm cột phải
                </button>

                <button
                    type="button"
                    onClick={() => onTrimEdge("top")}
                    disabled={mapSize.rows <= 2}
                >
                    <ArrowUp size={16} />
                    Giảm hàng trên
                </button>

                <button
                    type="button"
                    onClick={() => onTrimEdge("bottom")}
                    disabled={mapSize.rows <= 2}
                >
                    <ArrowDown size={16} />
                    Giảm hàng dưới
                </button>
            </div>
        </div>
    );
}
