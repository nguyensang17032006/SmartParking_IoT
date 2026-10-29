
import { Layers3, Plus } from "lucide-react";

export default function FloorSelector({
    floors,
    currentFloorId,
    onSelect,
    onAdd,
    onRename,
}) {
    const currentFloor = floors.find(
        (floor) => floor.id === currentFloorId
    );

    return (
        <div className="floor-selector">
            <div className="floor-selector-header">
                <Layers3 size={19} />
                <strong>Quản lý tầng</strong>
            </div>

            <div className="floor-selector-actions">
                {floors.map((floor) => (
                    <button
                        key={floor.id}
                        className={
                            currentFloorId === floor.id
                                ? "floor-button active"
                                : "floor-button"
                        }
                        onClick={() => onSelect(floor.id)}
                    >
                        {floor.name}
                    </button>
                ))}

                <button
                    className="floor-add-button"
                    onClick={onAdd}
                >
                    <Plus size={16} />
                    Thêm tầng
                </button>
            </div>

            <label className="floor-name-field">
                Tên tầng đang chọn
                <input
                    value={currentFloor?.name ?? ""}
                    onChange={(e) =>
                        onRename(currentFloorId, e.target.value)
                    }
                />
            </label>
        </div>
    );
}
