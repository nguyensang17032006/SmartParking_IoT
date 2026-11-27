import { OBJECT_TYPES } from "../constants/mapConfig";

export default function PropertiesPanel({
  selectedObject,
  onChange,
  zones = [],
}) {
  if (!selectedObject) {
    return (
      <aside className="map-properties">
        <h3>Thuộc tính</h3>
        <p className="property-empty">
          Chọn một đối tượng trên bản đồ để chỉnh sửa.
        </p>
      </aside>
    );
  }

  const obj = selectedObject;

  function changeNumber(field, value) {
    if (value === "") return;

    const number = Number(value);
    if (!Number.isInteger(number)) return;

    onChange(obj.id, { [field]: number });
  }

  const typeLabels = {
    slot: "Ô đỗ xe",
    road: "Đường đi",
    gate_in: "Cổng vào",
    gate_out: "Cổng ra",
    gate: "Cổng vào",
    ramp: "Dốc liên tầng",
    obstacle: "Vật cản",
  };

  return (
    <aside className="map-properties">
      <h3>Thuộc tính đối tượng</h3>

      <label>
        Loại đối tượng
        <input value={typeLabels[obj.type] || obj.type} disabled />
      </label>

      <label>
        Mã / Tên hiển thị
        <input
          value={obj.label || ""}
          onChange={(e) =>
            onChange(obj.id, { label: e.target.value })
          }
        />
      </label>

      {/* Thuộc tính riêng cho ô đỗ xe */}
      {obj.type === "slot" && zones && zones.length > 0 && (
        <label>
          Phân khu (Zone)
          <select
            value={obj.zone_id || zones[0]?.id || ""}
            onChange={(e) => {
              const selectedZoneId = e.target.value;
              const targetZone = zones.find((z) => z.id === selectedZoneId);
              onChange(obj.id, {
                zone_id: selectedZoneId,
                zone_code: targetZone?.code,
              });
            }}
          >
            {zones.map((z) => (
              <option key={z.id} value={z.id}>
                {z.name} ({z.code})
              </option>
            ))}
          </select>
        </label>
      )}

      {obj.type === "slot" && (
        <label>
          Loại phương tiện
          <select
            value={obj.vehicle_type || "motorbike"}
            onChange={(e) =>
              onChange(obj.id, { vehicle_type: e.target.value })
            }
          >
            <option value="car">Ô tô (car)</option>
          </select>
        </label>
      )}

      {/* Hướng di chuyển */}
      {(obj.type === "road" || obj.type === "ramp" || obj.type?.startsWith("gate")) && (
        <label>
          Hướng lưu thông
          <select
            value={obj.direction || "two_way"}
            onChange={(e) =>
              onChange(obj.id, { direction: e.target.value })
            }
          >
            <option value="two_way">Hai chiều (two_way)</option>
            <option value="one_way">Một chiều (one_way)</option>
            <option value="none">Không có (none)</option>
          </select>
        </label>
      )}

      {/* Hướng lối vào (Access Side) */}
      {["slot", "gate_in", "gate_out", "gate", "ramp"].includes(obj.type) && (
        <label>
          {obj.type === "slot"
            ? "Hướng xe ra/vào ô đỗ"
            : "Hướng tiếp cận / cửa vào ra"}
          <select
            value={obj.access_side || OBJECT_TYPES[obj.type]?.accessSide || "south"}
            onChange={(e) =>
              onChange(obj.id, { access_side: e.target.value })
            }
          >
            <option value="south">Phía Dưới (South)</option>
            <option value="north">Phía Trên (North)</option>
            <option value="west">Bên Trái (West)</option>
            <option value="east">Bên Phải (East)</option>
          </select>
        </label>
      )}

      {/* Góc xoay */}
      <label>
        Góc xoay
        <select
          value={obj.rotation || 0}
          onChange={(e) =>
            changeNumber("rotation", e.target.value)
          }
        >
          <option value={0}>0°</option>
          <option value={90}>90°</option>
          <option value={180}>180°</option>
          <option value={270}>270°</option>
        </select>
      </label>

      <div className="property-grid">
        {["x", "y", "width", "height"].map((field) => (
          <label key={field}>
            {field.toUpperCase()}
            <input
              type="number"
              min={field === "width" || field === "height" ? 1 : 0}
              value={obj[field]}
              onChange={(e) =>
                changeNumber(field, e.target.value)
              }
            />
          </label>
        ))}
      </div>

      <div className="property-info">
        Các thông số này sẽ được lưu vào bảng <code>map_elements</code> và <code>parking_slots</code> để ứng dụng Flutter và thuật toán dẫn đường A* sử dụng.
      </div>
    </aside>
  );
}
