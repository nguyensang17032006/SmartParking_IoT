import {
  MousePointer2,
  ParkingSquare,
  Paintbrush,
  Eraser,
  DoorOpen,
  LogOut,
  TrendingUp,
  Ban,
  Save,
  Trash2,
  GitBranch,
  Database,
} from "lucide-react";

const objectTools = [
  { type: "slot", label: "Ô đỗ", icon: ParkingSquare },
  { type: "gate_in", label: "Cổng vào", icon: DoorOpen },
  { type: "gate_out", label: "Cổng ra", icon: LogOut },
  { type: "ramp", label: "Dốc", icon: TrendingUp },
  { type: "obstacle", label: "Vật cản", icon: Ban },
];

export default function MapToolbar({
  tool,
  onToolChange,
  roadWidth,
  onRoadWidthChange,
  onAdd,
  onSave,
  onPublish,
  onOpenRamps,
  onDelete,
  selectedId,
  isSaving = false,
}) {
  return (
    <div className="map-toolbar">
      <div className="toolbar-tools">
        <button
          className={`map-tool-button ${tool === "select" ? "active" : ""}`}
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
          className={`map-tool-button ${tool === "road" ? "active" : ""}`}
          onClick={() => onToolChange("road")}
        >
          <Paintbrush size={17} />
          Vẽ đường
        </button>

        <button
          className={`map-tool-button ${tool === "eraser" ? "active" : ""}`}
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
        {onOpenRamps && (
          <button
            type="button"
            className="map-tool-button"
            style={{
              background: "#fffbeb",
              borderColor: "#fde68a",
              color: "#b45309",
              fontWeight: "600",
            }}
            onClick={onOpenRamps}
            title="Thiết lập liên kết dốc giữa các tầng cho thuật toán A*"
          >
            <GitBranch size={16} />
            Kết nối dốc liên tầng
          </button>
        )}

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
          style={{
            background: "#0f766e",
            borderColor: "#0f766e",
          }}
          disabled={isSaving}
          onClick={() => onPublish && onPublish("published")}
          title="Lưu toàn bộ tầng, ô đỗ, dốc và liên kết lên CSDL Supabase"
        >
          <Database size={16} />
          {isSaving ? "Đang lưu CSDL..." : "Lưu vào Database"}
        </button>
      </div>
    </div>
  );
}
