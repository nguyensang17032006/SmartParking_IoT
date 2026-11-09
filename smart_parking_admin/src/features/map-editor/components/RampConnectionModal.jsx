import { useState } from "react";
import {
  TrendingUp,
  ArrowRightLeft,
  ArrowRight,
  Trash2,
  Plus,
  X,
  Layers,
} from "lucide-react";
import toast from "react-hot-toast";

export default function RampConnectionModal({
  isOpen,
  onClose,
  floors = [],
  floorsData = {},
  rampConnections = [],
  onChangeConnections,
}) {
  const [fromElementId, setFromElementId] = useState("");
  const [toElementId, setToElementId] = useState("");
  const [direction, setDirection] = useState("two_way");

  if (!isOpen) return null;

  // Gom toàn bộ các đối tượng dốc (type === 'ramp') trên tất cả các tầng
  const allRamps = [];
  for (const floor of floors) {
    const fData = floorsData[floor.id] || { objects: [] };
    const floorRamps = fData.objects.filter((obj) => obj.type === "ramp");

    for (const ramp of floorRamps) {
      allRamps.push({
        id: ramp.id,
        label: ramp.label || "Dốc",
        floorId: floor.id,
        floorName: floor.name || `Tầng ${floor.code}`,
        floorCode: floor.code,
        display: `[${floor.name || floor.code}] ${ramp.label || "Dốc"} (x:${ramp.x}, y:${ramp.y})`,
      });
    }
  }

  function handleAddConnection(e) {
    e.preventDefault();

    if (!fromElementId || !toElementId) {
      toast.error("Vui lòng chọn cả dốc đầu và dốc đích!");
      return;
    }

    if (fromElementId === toElementId) {
      toast.error("Không thể kết nối một dốc với chính nó!");
      return;
    }

    // Kiểm tra xem kết nối đã tồn tại chưa
    const isExisted = rampConnections.some(
      (c) =>
        (c.from_element_id === fromElementId &&
          c.to_element_id === toElementId) ||
        (c.direction === "two_way" &&
          c.from_element_id === toElementId &&
          c.to_element_id === fromElementId)
    );

    if (isExisted) {
      toast.error("Kết nối giữa hai dốc này đã tồn tại!");
      return;
    }

    const newConn = {
      id: crypto.randomUUID(),
      from_element_id: fromElementId,
      to_element_id: toElementId,
      direction: direction,
    };

    onChangeConnections([...rampConnections, newConn]);
    toast.success("Đã thêm kết nối dốc liên tầng!");
    setFromElementId("");
    setToElementId("");
  }

  function handleDeleteConnection(connId) {
    onChangeConnections(rampConnections.filter((c) => c.id !== connId));
    toast.success("Đã xóa kết nối dốc");
  }

  function getRampDisplay(elementId) {
    const ramp = allRamps.find((r) => r.id === elementId);
    return ramp ? ramp.display : `Dốc #${elementId.slice(0, 8)}`;
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div
        className="modal-content"
        style={{ maxWidth: "620px" }}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="modal-header">
          <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
            <TrendingUp size={20} color="#f59e0b" />
            <div>
              <h3 style={{ margin: 0 }}>Kết nối dốc giữa các tầng (Ramps)</h3>
              <span style={{ fontSize: "12px", color: "#64748b" }}>
                Thuật toán A* sẽ dùng các liên kết này để điều hướng qua nhiều tầng
              </span>
            </div>
          </div>
          <button className="modal-close" onClick={onClose}>
            <X size={18} />
          </button>
        </div>

        <div className="modal-body" style={{ maxHeight: "65vh", overflowY: "auto" }}>
          {/* Form thêm kết nối */}
          <form
            onSubmit={handleAddConnection}
            style={{
              background: "#f8fafc",
              padding: "16px",
              borderRadius: "12px",
              border: "1px solid #e2e8f0",
              display: "flex",
              flexDirection: "column",
              gap: "12px",
            }}
          >
            <strong style={{ fontSize: "13px", color: "#1e293b" }}>
              Tạo kết nối mới:
            </strong>

            {allRamps.length < 2 ? (
              <div
                style={{
                  fontSize: "12px",
                  color: "#d97706",
                  background: "#fef3c7",
                  padding: "10px",
                  borderRadius: "8px",
                }}
              >
                ⚠️ Cần có ít nhất 2 đối tượng <strong>Dốc</strong> (ramp) ở các tầng
                để thiết lập liên kết! Hãy chuyển qua các tầng và thêm dốc trước.
              </div>
            ) : (
              <>
                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "1fr 1fr",
                    gap: "10px",
                  }}
                >
                  <div className="form-group">
                    <label>Dốc đầu (Tầng A) *</label>
                    <select
                      value={fromElementId}
                      onChange={(e) => setFromElementId(e.target.value)}
                      required
                    >
                      <option value="">-- Chọn dốc đầu --</option>
                      {allRamps.map((r) => (
                        <option key={r.id} value={r.id}>
                          {r.display}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="form-group">
                    <label>Dốc đích (Tầng B) *</label>
                    <select
                      value={toElementId}
                      onChange={(e) => setToElementId(e.target.value)}
                      required
                    >
                      <option value="">-- Chọn dốc đích --</option>
                      {allRamps
                        .filter((r) => r.id !== fromElementId)
                        .map((r) => (
                          <option key={r.id} value={r.id}>
                            {r.display}
                          </option>
                        ))}
                    </select>
                  </div>
                </div>

                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    gap: "10px",
                  }}
                >
                  <div className="form-group" style={{ flex: 1 }}>
                    <label>Hướng di chuyển</label>
                    <select
                      value={direction}
                      onChange={(e) => setDirection(e.target.value)}
                    >
                      <option value="two_way">Hai chiều (⮂⮀⮂)</option>
                      <option value="one_way">Một chiều (Tầng A ➔ Tầng B)</option>
                    </select>
                  </div>

                  <button
                    type="submit"
                    className="btn-primary"
                    style={{ alignSelf: "flex-end", height: "38px" }}
                  >
                    <Plus size={16} /> Thêm kết nối
                  </button>
                </div>
              </>
            )}
          </form>

          {/* Danh sách các kết nối hiện tại */}
          <div style={{ marginTop: "12px" }}>
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                marginBottom: "8px",
              }}
            >
              <strong style={{ fontSize: "13px", color: "#1e293b" }}>
                Danh sách kết nối đã thiết lập ({rampConnections.length}):
              </strong>
            </div>

            {rampConnections.length === 0 ? (
              <div
                style={{
                  textAlign: "center",
                  padding: "24px",
                  color: "#94a3b8",
                  background: "#fdfdfd",
                  border: "1px dashed #cbd5e1",
                  borderRadius: "10px",
                  fontSize: "13px",
                }}
              >
                Chưa có liên kết dốc nào giữa các tầng.
              </div>
            ) : (
              <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
                {rampConnections.map((conn) => (
                  <div
                    key={conn.id}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                      padding: "10px 14px",
                      background: "#ffffff",
                      border: "1px solid #e2e8f0",
                      borderRadius: "10px",
                    }}
                  >
                    <div
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: "10px",
                        fontSize: "12px",
                      }}
                    >
                      <span
                        style={{
                          fontWeight: "600",
                          color: "#1e293b",
                          maxWidth: "180px",
                          overflow: "hidden",
                          textOverflow: "ellipsis",
                          whiteSpace: "nowrap",
                        }}
                      >
                        {getRampDisplay(conn.from_element_id)}
                      </span>

                      {conn.direction === "two_way" ? (
                        <span
                          title="Hai chiều"
                          style={{
                            display: "inline-flex",
                            alignItems: "center",
                            gap: "4px",
                            padding: "3px 8px",
                            background: "#e0f2fe",
                            color: "#0369a1",
                            borderRadius: "12px",
                            fontSize: "11px",
                            fontWeight: "600",
                          }}
                        >
                          <ArrowRightLeft size={13} /> Hai chiều
                        </span>
                      ) : (
                        <span
                          title="Một chiều"
                          style={{
                            display: "inline-flex",
                            alignItems: "center",
                            gap: "4px",
                            padding: "3px 8px",
                            background: "#fef3c7",
                            color: "#b45309",
                            borderRadius: "12px",
                            fontSize: "11px",
                            fontWeight: "600",
                          }}
                        >
                          <ArrowRight size={13} /> Một chiều
                        </span>
                      )}

                      <span
                        style={{
                          fontWeight: "600",
                          color: "#1e293b",
                          maxWidth: "180px",
                          overflow: "hidden",
                          textOverflow: "ellipsis",
                          whiteSpace: "nowrap",
                        }}
                      >
                        {getRampDisplay(conn.to_element_id)}
                      </span>
                    </div>

                    <button
                      type="button"
                      className="btn-icon delete"
                      title="Xóa liên kết dốc này"
                      onClick={() => handleDeleteConnection(conn.id)}
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        <div className="modal-footer">
          <button type="button" className="btn-secondary" onClick={onClose}>
            Đóng
          </button>
        </div>
      </div>
    </div>
  );
}

