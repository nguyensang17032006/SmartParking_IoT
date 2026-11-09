import { useState } from "react";
import { Plus, Tag, Pencil, Trash2, Check, X } from "lucide-react";
import toast from "react-hot-toast";

export default function ZoneSelector({
  zones = [],
  activeZoneId,
  onSelectZone,
  onAddZone,
  onUpdateZone,
  onDeleteZone,
  objects = [],
}) {
  const [isAdding, setIsAdding] = useState(false);
  const [newCode, setNewCode] = useState("");
  const [newName, setNewName] = useState("");

  const [editingZoneId, setEditingZoneId] = useState(null);
  const [editName, setEditName] = useState("");

  function handleStartAdd() {
    const existingCodes = zones.map((z) => (z.code || "").toUpperCase());
    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("");
    const nextChar = alphabet.find((char) => !existingCodes.includes(char)) || "Z";

    setNewCode(nextChar);
    setNewName(`Khu ${nextChar}`);
    setIsAdding(true);
  }

  function handleConfirmAdd(e) {
    e.preventDefault();
    const code = newCode.trim().toUpperCase();
    if (!code) {
      toast.error("Vui lòng nhập mã phân khu (VD: A, B, C)!");
      return;
    }
    if (zones.some((z) => (z.code || "").toUpperCase() === code)) {
      toast.error(`Mã khu ${code} đã tồn tại ở tầng này!`);
      return;
    }

    onAddZone({
      code,
      name: newName.trim() || `Khu ${code}`,
      color: "#22c55e",
    });

    setIsAdding(false);
  }

  function handleStartEdit(zone, e) {
    e.stopPropagation();
    setEditingZoneId(zone.id);
    setEditName(zone.name);
  }

  function handleSaveEdit(zoneId, e) {
    e?.stopPropagation();
    onUpdateZone(zoneId, {
      name: editName.trim() || "Khu vực",
    });
    setEditingZoneId(null);
  }

  function handleDelete(zoneId, zoneName, e) {
    e.stopPropagation();
    if (zones.length <= 1) {
      toast.error("Mỗi tầng cần có ít nhất một phân khu!");
      return;
    }
    if (window.confirm(`Xóa "${zoneName}"? Các ô đỗ thuộc khu này sẽ được chuyển sang khu còn lại.`)) {
      onDeleteZone(zoneId);
    }
  }

  function getSlotCount(zoneId) {
    return objects.filter((o) => o.type === "slot" && o.zone_id === zoneId).length;
  }

  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        flexWrap: "wrap",
        gap: "10px",
        background: "#ffffff",
        padding: "10px 16px",
        borderRadius: "12px",
        border: "1px solid #e2e8f0",
        marginBottom: "12px",
      }}
    >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: "6px",
          color: "#475569",
          fontSize: "13px",
          fontWeight: "700",
        }}
      >
        <Tag size={16} color="#0284c7" />
        <span>Phân khu (Zones) tầng này:</span>
      </div>

      <div style={{ display: "flex", alignItems: "center", gap: "8px", flexWrap: "wrap" }}>
        {zones.map((zone) => {
          const isActive = zone.id === activeZoneId;
          const slotCount = getSlotCount(zone.id);
          const isEditing = editingZoneId === zone.id;

          if (isEditing) {
            return (
              <div
                key={zone.id}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "6px",
                  padding: "4px 8px",
                  background: "#f8fafc",
                  borderRadius: "8px",
                  border: "1px solid #cbd5e1",
                }}
              >
                <input
                  type="text"
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  style={{
                    padding: "4px 8px",
                    border: "1px solid #cbd5e1",
                    borderRadius: "6px",
                    fontSize: "12px",
                    width: "110px",
                  }}
                  autoFocus
                />
                <button
                  type="button"
                  onClick={(e) => handleSaveEdit(zone.id, e)}
                  style={{
                    background: "#10b981",
                    color: "white",
                    border: "none",
                    borderRadius: "6px",
                    padding: "4px 8px",
                    cursor: "pointer",
                    display: "flex",
                    alignItems: "center",
                  }}
                  title="Lưu"
                >
                  <Check size={14} />
                </button>
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation();
                    setEditingZoneId(null);
                  }}
                  style={{
                    background: "#ef4444",
                    color: "white",
                    border: "none",
                    borderRadius: "6px",
                    padding: "4px 8px",
                    cursor: "pointer",
                    display: "flex",
                    alignItems: "center",
                  }}
                  title="Hủy"
                >
                  <X size={14} />
                </button>
              </div>
            );
          }

          return (
            <div
              key={zone.id}
              onClick={() => onSelectZone(zone.id)}
              style={{
                display: "flex",
                alignItems: "center",
                gap: "8px",
                padding: "6px 12px",
                borderRadius: "8px",
                cursor: "pointer",
                background: isActive ? "#eff6ff" : "#f8fafc",
                border: `1.5px solid ${isActive ? "#3b82f6" : "#e2e8f0"}`,
                boxShadow: isActive ? "0 1px 3px rgba(59, 130, 246, 0.15)" : "none",
                transition: "all 0.15s ease",
              }}
              title={`Click để chọn ${zone.name} làm khu vực mặc định khi thêm ô đỗ`}
            >
              <span
                style={{
                  fontSize: "13px",
                  fontWeight: isActive ? "700" : "500",
                  color: isActive ? "#1d4ed8" : "#475569",
                }}
              >
                {zone.name} ({zone.code})
              </span>
              <span
                style={{
                  fontSize: "11px",
                  background: isActive ? "#dbeafe" : "#e2e8f0",
                  color: isActive ? "#1e40af" : "#64748b",
                  padding: "1px 6px",
                  borderRadius: "10px",
                  fontWeight: "600",
                }}
              >
                {slotCount} ô
              </span>

              <button
                type="button"
                onClick={(e) => handleStartEdit(zone, e)}
                style={{
                  background: "transparent",
                  border: "none",
                  cursor: "pointer",
                  color: "#94a3b8",
                  padding: "2px",
                  display: "flex",
                  alignItems: "center",
                }}
                title="Đổi tên khu"
              >
                <Pencil size={13} />
              </button>

              {zones.length > 1 && (
                <button
                  type="button"
                  onClick={(e) => handleDelete(zone.id, zone.name, e)}
                  style={{
                    background: "transparent",
                    border: "none",
                    cursor: "pointer",
                    color: "#ef4444",
                    padding: "2px",
                    display: "flex",
                    alignItems: "center",
                  }}
                  title="Xóa khu"
                >
                  <Trash2 size={13} />
                </button>
              )}
            </div>
          );
        })}

        {isAdding ? (
          <form
            onSubmit={handleConfirmAdd}
            style={{
              display: "flex",
              alignItems: "center",
              gap: "6px",
              padding: "4px 8px",
              background: "#eff6ff",
              borderRadius: "8px",
              border: "1px dashed #3b82f6",
            }}
          >
            <input
              type="text"
              placeholder="Mã (A, B...)"
              value={newCode}
              onChange={(e) => setNewCode(e.target.value.toUpperCase())}
              style={{
                padding: "4px 6px",
                border: "1px solid #93c5fd",
                borderRadius: "6px",
                fontSize: "12px",
                width: "60px",
                textTransform: "uppercase",
              }}
              maxLength={3}
              autoFocus
            />
            <input
              type="text"
              placeholder="Tên khu (VD: Khu A)"
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
              style={{
                padding: "4px 6px",
                border: "1px solid #93c5fd",
                borderRadius: "6px",
                fontSize: "12px",
                width: "90px",
              }}
            />
            <button
              type="submit"
              style={{
                background: "#2563eb",
                color: "white",
                border: "none",
                borderRadius: "6px",
                padding: "4px 8px",
                cursor: "pointer",
                fontSize: "12px",
                fontWeight: "600",
              }}
            >
              Thêm
            </button>
            <button
              type="button"
              onClick={() => setIsAdding(false)}
              style={{
                background: "#94a3b8",
                color: "white",
                border: "none",
                borderRadius: "6px",
                padding: "4px 8px",
                cursor: "pointer",
                fontSize: "12px",
              }}
            >
              Hủy
            </button>
          </form>
        ) : (
          <button
            type="button"
            onClick={handleStartAdd}
            style={{
              display: "flex",
              alignItems: "center",
              gap: "4px",
              padding: "6px 12px",
              background: "#ffffff",
              border: "1px dashed #cbd5e1",
              borderRadius: "8px",
              color: "#2563eb",
              fontSize: "12px",
              fontWeight: "600",
              cursor: "pointer",
              transition: "all 0.15s ease",
            }}
          >
            <Plus size={14} />
            <span>Thêm khu (Zone)</span>
          </button>
        )}
      </div>
    </div>
  );
}
