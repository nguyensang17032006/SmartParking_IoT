
import {
  MousePointer2,
  ParkingSquare,
  Paintbrush,
  Eraser,
  DoorOpen,
  LogOut,
  TrendingUp,
  Save,
  Trash2,
} from "lucide-react";

const objectTools = [
  { type: "slot", label: "Ô đỗ", icon: ParkingSquare },
  {
    type: "gate",
    label: "Cổng",
    icon: DoorOpen,
  },
  { type: "ramp", label: "Dốc", icon: TrendingUp },
];

export default function MapToolbar({
  tool,
  onToolChange,
  roadWidth,
  onRoadWidthChange,
  onAdd,
  onSave,
  onDelete,
  selectedId,
}) {
  return (
    <div className="map-toolbar">
      <div className="toolbar-tools">
        <button
          className={`map-tool-button ${tool === "select" ? "active" : ""
            }`}
          onClick={() => onToolChange("select")}
        >
          <MousePointer2 size={17} />
          Chọn
        </button>

        {objectTools.map(({ type, label, icon: Icon }) => (
          <button
            key={type}
            className="map-tool-button"
            onClick={() => onAdd(type)}
          >
            <Icon size={17} />
            {label}
          </button>
        ))}

        <button
          className={`map-tool-button ${tool === "road" ? "active" : ""
            }`}
          onClick={() => onToolChange("road")}
        >
          <Paintbrush size={17} />
          Vẽ đường
        </button>

        <button
          className={`map-tool-button ${tool === "eraser" ? "active" : ""
            }`}
          onClick={() => onToolChange("eraser")}
        >
          <Eraser size={17} />
          Xóa đường
        </button>

        {(tool === "road" || tool === "eraser") && (
          <label className="road-width-control">
            Độ rộng
            <select
              value={roadWidth}
              onChange={(e) =>
                onRoadWidthChange(Number(e.target.value))
              }
            >
              <option value={1}>1 ô</option>
              <option value={2}>2 ô</option>
              <option value={3}>3 ô</option>
              <option value={4}>4 ô</option>
            </select>
          </label>
        )}
      </div>

      <div className="toolbar-actions">
        <button
          className="map-delete-button"
          disabled={!selectedId || tool !== "select"}
          onClick={() => onDelete(selectedId)}
        >
          <Trash2 size={16} />
          Xóa
        </button>

        <button
          className="map-save-button"
          onClick={onSave}
        >
          <Save size={16} />
          Lưu
        </button>
      </div>
    </div>
  );
}
