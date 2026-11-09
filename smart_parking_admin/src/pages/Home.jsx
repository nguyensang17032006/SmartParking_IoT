import { useEffect, useState, useMemo } from "react";
import { Link } from "react-router-dom";
import toast from "react-hot-toast";
import {
  Car,
  CheckCircle2,
  AlertTriangle,
  ParkingSquare,
  Navigation,
  ArrowRight,
  RotateCcw,
  PencilRuler,
  Layers,
  MapPin,
  TrendingUp,
} from "lucide-react";

import { supabase } from "../lib/supabaseClient";
import { getCampuses, getParkingLots } from "../features/map-editor/service/mapService";
import { loadMapFromDatabase } from "../features/map-editor/service/mapPersistenceService";
import LiveMapCanvas from "../features/dashboard/components/LiveMapCanvas";
import { findPathAStar, getSlotEntryPoint, getGateRoadPort } from "../utils/pathfinding";

import "../styles/dashboard.css";

export default function Home() {
  // 1. Quản lý Cơ sở và Bãi xe
  const [campuses, setCampuses] = useState([]);
  const [lots, setLots] = useState([]);
  const [campusId, setCampusId] = useState("");
  const [lotId, setLotId] = useState("");
  const [loadingLots, setLoadingLots] = useState(false);

  // 2. Dữ liệu bản đồ từ CSDL
  const [mapData, setMapData] = useState(null);
  const [floors, setFloors] = useState([]);
  const [floorsData, setFloorsData] = useState({});
  const [rampConnections, setRampConnections] = useState([]);
  const [currentFloorId, setCurrentFloorId] = useState(null);
  const [loadingMap, setLoadingMap] = useState(false);

  // 3. Đường đi thuật toán A* và ô đỗ đang chọn
  const [activePath, setActivePath] = useState([]);
  const [routeSummary, setRouteSummary] = useState(null);
  const [selectedSlot, setSelectedSlot] = useState(null);

  // ==========================================
  // TẢI DANH SÁCH CƠ SỞ (Mặc định chọn Cơ sở đầu tiên)
  // ==========================================
  useEffect(() => {
    let active = true;

    async function fetchCampuses() {
      try {
        const data = await getCampuses();
        if (!active) return;
        setCampuses(data);

        // Mặc định chọn cơ sở đầu tiên (Cơ sở 1)
        if (data && data.length > 0) {
          setCampusId((prev) => prev || data[0].id);
        }
      } catch (err) {
        console.error("Lỗi tải cơ sở:", err);
      }
    }

    fetchCampuses();
    return () => {
      active = false;
    };
  }, []);

  // ==========================================
  // TẢI DANH SÁCH BÃI XE THEO CƠ SỞ (Mặc định chọn Bãi đầu tiên)
  // ==========================================
  useEffect(() => {
    if (!campusId) return;

    let active = true;

    async function fetchLots() {
      setLoadingLots(true);
      try {
        const data = await getParkingLots(campusId);
        if (!active) return;
        setLots(data);

        // Mặc định chọn bãi xe đầu tiên (Bãi 1)
        if (data && data.length > 0) {
          setLotId(data[0].id);
        } else {
          setLotId("");
          setMapData(null);
        }
      } catch (err) {
        console.error("Lỗi tải bãi xe:", err);
      } finally {
        if (active) setLoadingLots(false);
      }
    }

    fetchLots();
    return () => {
      active = false;
    };
  }, [campusId]);

  // ==========================================
  // TẢI BẢN ĐỒ TỪ CSDL SUPABASE KHI CHỌN BÃI XE
  // ==========================================
  useEffect(() => {
    let active = true;

    async function fetchMap() {
      if (!lotId) {
        setMapData(null);
        setFloors([]);
        setFloorsData({});
        return;
      }

      setLoadingMap(true);
      setActivePath([]);
      setRouteSummary(null);
      setSelectedSlot(null);

      try {
        const res = await loadMapFromDatabase(lotId);
        if (!active) return;

        if (res.hasData && res.floors.length > 0) {
          setMapData(res);
          setFloors(res.floors);
          setFloorsData(res.floorsData);
          setRampConnections(res.rampConnections || []);
          setCurrentFloorId(res.floors[0].id);
        } else {
          setMapData(null);
          setFloors([]);
          setFloorsData({});
        }
      } catch (err) {
        console.error("Lỗi tải bản đồ từ CSDL:", err);
      } finally {
        if (active) setLoadingMap(false);
      }
    }

    fetchMap();
    return () => {
      active = false;
    };
  }, [lotId]);

  // ==========================================
  // LẮNG NGHE SUPABASE REALTIME ĐỂ CẬP NHẬT TRẠNG THÁI Ô ĐỖ TỨC THÌ
  // ==========================================
  useEffect(() => {
    if (!lotId) return;

    const channel = supabase
      .channel(`realtime-dashboard-${lotId}`)
      .on(
        "postgres_changes",
        { event: "UPDATE", schema: "public", table: "parking_slots" },
        (payload) => {
          const updatedSlot = payload.new;

          // Cập nhật trạng thái slot trong floorsData
          setFloorsData((prev) => {
            const next = { ...prev };
            for (const fId of Object.keys(next)) {
              next[fId] = {
                ...next[fId],
                objects: next[fId].objects.map((obj) => {
                  if (obj.slot_id === updatedSlot.id) {
                    return { ...obj, status: updatedSlot.status };
                  }
                  return obj;
                }),
              };
            }
            return next;
          });
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [lotId]);

  // ==========================================
  // TÍNH TOÁN THỐNG KÊ (TRỐNG, CÓ XE, BẢO TRÌ)
  // ==========================================
  const stats = useMemo(() => {
    let total = 0;
    let available = 0;
    let occupied = 0;
    let maintenance = 0;

    for (const f of floors) {
      const fObjects = floorsData[f.id]?.objects || [];
      for (const obj of fObjects) {
        if (obj.type === "slot") {
          total++;
          if (obj.status === "occupied") occupied++;
          else if (obj.status === "maintenance") maintenance++;
          else available++;
        }
      }
    }

    const rate = total > 0 ? Math.round((occupied / total) * 100) : 0;
    return { total, available, occupied, maintenance, rate };
  }, [floors, floorsData]);

  // ==========================================
  // THUẬT TOÁN A*: TÌM ĐƯỜNG ĐẾN Ô ĐỖ BẤT KỲ
  // ==========================================
  function runPathfindingToSlot(slot, targetFloorId) {
    if (!slot || !targetFloorId) return;

    // 1. Tìm cổng vào (gate_in) ở tầng thấp nhất (thường là Tầng 1)
    let startNode = null;
    let gateObj = null;
    const sortedFloors = [...floors].sort(
      (a, b) => (a.level_number || 1) - (b.level_number || 1)
    );

    for (const f of sortedFloors) {
      const fObjs = floorsData[f.id]?.objects || [];
      const gate = fObjs.find(
        (o) => o.type === "gate_in" || o.type === "gate"
      );
      if (gate) {
        gateObj = gate;
        const port = getGateRoadPort(gate, floorsData[f.id]?.roadCells || []);
        startNode = {
          x: port.x,
          y: port.y,
          floorId: f.id,
        };
        break;
      }
    }

    if (!startNode || !gateObj) {
      toast.error("Không tìm thấy Cổng vào (gate_in) trong bãi xe!");
      return;
    }

    // 2. Tìm điểm tiếp cận ô đỗ theo đúng hướng mặt tiền (access_side)
    const targetFloorData = floorsData[targetFloorId];
    const roadCells = targetFloorData?.roadCells || [];
    const entryPoint = getSlotEntryPoint(slot, roadCells);

    const goalNode = {
      x: entryPoint.x,
      y: entryPoint.y,
      floorId: targetFloorId,
    };

    // 3. Thực thi thuật toán A* buộc xe chỉ đi trên đường
    const rawPath = findPathAStar({
      startNode,
      goalNode,
      floorsData,
      rampConnections,
    });

    if (!rawPath || rawPath.length === 0) {
      toast.error(
        `Không tìm được đường đi từ Cổng vào đến ô ${slot.label}! Kiểm tra xem đường đi có bị đứt quãng không.`
      );
      return;
    }

    // Nối thêm điểm xuất phát từ trong cổng và điểm kết thúc vào tâm ô đỗ
    const fullPath = [
      {
        x: gateObj.x + Math.floor((gateObj.width || 2) / 2),
        y: gateObj.y + Math.floor((gateObj.height || 3) / 2),
        floorId: startNode.floorId,
      },
      ...rawPath,
      {
        x: slot.x + Math.floor((slot.width || 2) / 2),
        y: slot.y + Math.floor((slot.height || 2) / 2),
        floorId: targetFloorId,
      },
    ];

    setActivePath(fullPath);

    // Kiểm tra tuyến đường có đi qua nhiều tầng không
    const floorsInPath = [...new Set(fullPath.map((p) => p.floorId))];
    const isMultiFloor = floorsInPath.length > 1;

    const startFloorName =
      floors.find((f) => f.id === startNode.floorId)?.name || "Tầng 1";
    const targetFloorName =
      floors.find((f) => f.id === targetFloorId)?.name || "Tầng 2";

    setRouteSummary({
      slotCode: slot.label,
      targetFloorId,
      targetFloorName,
      isMultiFloor,
      stepCount: fullPath.length,
      startFloorName,
    });

    // Chuyển sang xem tầng có cổng vào trước, hoặc tầng đích
    if (isMultiFloor && currentFloorId !== startNode.floorId) {
      setCurrentFloorId(startNode.floorId);
    } else if (!isMultiFloor) {
      setCurrentFloorId(targetFloorId);
    }

    toast.success(
      `Đã tìm thấy tuyến đường đến ô ${slot.label} (${fullPath.length} bước)!`
    );
  }

  // ==========================================
  // MÔ PHỎNG: XE VÀO CỔNG (Entry Simulation)
  // ==========================================
  async function handleSimulateEntry() {
    // 1. Tìm tất cả ô đang TRỐNG trong toàn bãi
    const availableSlots = [];
    for (const f of floors) {
      const fObjs = floorsData[f.id]?.objects || [];
      for (const obj of fObjs) {
        if (obj.type === "slot" && (obj.status || "available") === "available") {
          availableSlots.push({ slot: obj, floorId: f.id });
        }
      }
    }

    if (availableSlots.length === 0) {
      toast.error("Bãi xe đã hết chỗ đỗ trống!");
      return;
    }

    // 2. Chọn ngẫu nhiên 1 ô trống
    const chosen =
      availableSlots[Math.floor(Math.random() * availableSlots.length)];

    // 3. Chạy thuật toán A* chỉ đường đến ô đó
    runPathfindingToSlot(chosen.slot, chosen.floorId);

    // 4. Cập nhật trạng thái ô sang 'occupied' (Có xe - Màu đỏ)
    try {
      const { error } = await supabase
        .from("parking_slots")
        .update({
          status: "occupied",
          updated_at: new Date().toISOString(),
        })
        .eq("id", chosen.slot.slot_id);

      if (error) throw error;

      // Cập nhật state nội bộ ngay lập tức
      setFloorsData((prev) => {
        const next = { ...prev };
        next[chosen.floorId] = {
          ...next[chosen.floorId],
          objects: next[chosen.floorId].objects.map((o) =>
            o.id === chosen.slot.id ? { ...o, status: "occupied" } : o
          ),
        };
        return next;
      });

      const floorName =
        floors.find((f) => f.id === chosen.floorId)?.name || "Tầng 1";
      toast.success(
        `[MÔ PHỎNG] Xe đã vào bãi! Được điều hướng đến ô ${chosen.slot.label} tại ${floorName}.`
      );
    } catch (err) {
      console.error("Lỗi cập nhật trạng thái ô:", err);
    }
  }

  // ==========================================
  // MÔ PHỎNG: XE RA CỔNG (Exit Simulation)
  // ==========================================
  async function handleSimulateExit() {
    // 1. Tìm các ô ĐANG CÓ XE
    const occupiedSlots = [];
    for (const f of floors) {
      const fObjs = floorsData[f.id]?.objects || [];
      for (const obj of fObjs) {
        if (obj.type === "slot" && obj.status === "occupied") {
          occupiedSlots.push({ slot: obj, floorId: f.id });
        }
      }
    }

    if (occupiedSlots.length === 0) {
      toast.error("Hiện không có xe nào đang đỗ trong bãi!");
      return;
    }

    // 2. Chọn ngẫu nhiên 1 ô có xe
    const chosen =
      occupiedSlots[Math.floor(Math.random() * occupiedSlots.length)];

    // 3. Tìm Cổng ra (gate_out)
    let exitNode = null;
    let gateOutObj = null;
    for (const f of floors) {
      const fObjs = floorsData[f.id]?.objects || [];
      const gate = fObjs.find((o) => o.type === "gate_out");
      if (gate) {
        gateOutObj = gate;
        const port = getGateRoadPort(gate, floorsData[f.id]?.roadCells || []);
        exitNode = {
          x: port.x,
          y: port.y,
          floorId: f.id,
        };
        break;
      }
    }

    if (exitNode && gateOutObj) {
      const entryPoint = getSlotEntryPoint(
        chosen.slot,
        floorsData[chosen.floorId]?.roadCells || []
      );
      const rawPath = findPathAStar({
        startNode: {
          x: entryPoint.x,
          y: entryPoint.y,
          floorId: chosen.floorId,
        },
        goalNode: exitNode,
        floorsData,
        rampConnections,
      });

      if (rawPath && rawPath.length > 0) {
        const fullPath = [
          {
            x: chosen.slot.x + Math.floor((chosen.slot.width || 2) / 2),
            y: chosen.slot.y + Math.floor((chosen.slot.height || 2) / 2),
            floorId: chosen.floorId,
          },
          ...rawPath,
          {
            x: gateOutObj.x + Math.floor((gateOutObj.width || 2) / 2),
            y: gateOutObj.y + Math.floor((gateOutObj.height || 3) / 2),
            floorId: exitNode.floorId,
          },
        ];

        setActivePath(fullPath);
        setRouteSummary({
          slotCode: chosen.slot.label,
          targetFloorId: exitNode.floorId,
          targetFloorName: "Cổng ra",
          isMultiFloor: chosen.floorId !== exitNode.floorId,
          stepCount: fullPath.length,
          startFloorName:
            floors.find((f) => f.id === chosen.floorId)?.name || "",
        });
      }
    }

    // 4. Đổi trạng thái ô về 'available' (Trống - Màu xanh)
    try {
      const { error } = await supabase
        .from("parking_slots")
        .update({
          status: "available",
          updated_at: new Date().toISOString(),
        })
        .eq("id", chosen.slot.slot_id);

      if (error) throw error;

      setFloorsData((prev) => {
        const next = { ...prev };
        next[chosen.floorId] = {
          ...next[chosen.floorId],
          objects: next[chosen.floorId].objects.map((o) =>
            o.id === chosen.slot.id ? { ...o, status: "available" } : o
          ),
        };
        return next;
      });

      toast.success(
        `[MÔ PHỎNG] Xe tại ô ${chosen.slot.label} đã rời bãi! Ô đã chuyển về trạng thái Trống.`
      );
    } catch (err) {
      console.error("Lỗi cập nhật trạng thái ô:", err);
    }
  }

  // ==========================================
  // ĐỔI TRẠNG THÁI Ô KHI ADMIN CLICK TRỰC TIẾP
  // ==========================================
  async function handleToggleSlotStatus(slot) {
    if (!slot || !slot.slot_id) return;
    const nextStatus = slot.status === "occupied" ? "available" : "occupied";

    try {
      const { error } = await supabase
        .from("parking_slots")
        .update({ status: nextStatus, updated_at: new Date().toISOString() })
        .eq("id", slot.slot_id);

      if (error) throw error;

      setFloorsData((prev) => {
        const next = { ...prev };
        for (const fId of Object.keys(next)) {
          next[fId] = {
            ...next[fId],
            objects: next[fId].objects.map((o) =>
              o.id === slot.id ? { ...o, status: nextStatus } : o
            ),
          };
        }
        return next;
      });

      setSelectedSlot((prev) =>
        prev ? { ...prev, status: nextStatus } : null
      );

      toast.success(`Đã đổi ô ${slot.label} sang ${nextStatus === "occupied" ? "CÓ XE" : "TRỐNG"}!`);
    } catch (err) {
      toast.error("Không thể cập nhật trạng thái ô: " + err.message);
    }
  }

  const currentFloorData = currentFloorId ? floorsData[currentFloorId] : null;

  return (
    <div className="dashboard-page">
      {/* 1. Header & Bộ chọn Cơ sở, Bãi xe */}
      <div className="dashboard-header">
        <div className="dashboard-title">
          <h2>Tổng quan bãi đỗ xe</h2>
          <p>Giám sát ô đỗ thời gian thực và mô phỏng dẫn đường thuật toán A*.</p>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: "12px", flexWrap: "wrap" }}>
          <label style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "13px", fontWeight: "600", color: "#475569" }}>
            <MapPin size={16} color="#0284c7" />
            Cơ sở:
            <select
              value={campusId}
              onChange={(e) => {
                setCampusId(e.target.value);
                setLotId("");
              }}
              style={{
                padding: "6px 12px",
                borderRadius: "8px",
                border: "1px solid #cbd5e1",
                fontSize: "13px",
                fontWeight: "600",
                background: "#ffffff",
              }}
            >
              {campuses.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.code} - {c.name}
                </option>
              ))}
            </select>
          </label>

          <label style={{ display: "flex", alignItems: "center", gap: "6px", fontSize: "13px", fontWeight: "600", color: "#475569" }}>
            <ParkingSquare size={16} color="#10b981" />
            Bãi xe:
            <select
              value={lotId}
              disabled={loadingLots || lots.length === 0}
              onChange={(e) => setLotId(e.target.value)}
              style={{
                padding: "6px 12px",
                borderRadius: "8px",
                border: "1px solid #cbd5e1",
                fontSize: "13px",
                fontWeight: "600",
                background: "#ffffff",
              }}
            >
              {lots.length === 0 ? (
                <option value="">Không có bãi xe</option>
              ) : (
                lots.map((l) => (
                  <option key={l.id} value={l.id}>
                    {l.name}
                  </option>
                ))
              )}
            </select>
          </label>
        </div>
      </div>

      {/* 2. Trường hợp bãi xe chưa có bản đồ */}
      {!loadingMap && (!mapData || floors.length === 0) ? (
        <div className="empty-state-box">
          <PencilRuler size={48} color="#94a3b8" />
          <h3>Bãi xe này chưa có bản đồ sơ đồ</h3>
          <p>
            Vui lòng chuyển sang trang <strong>Thiết kế bản đồ</strong> để vẽ các tầng, bố trí ô đỗ, đường đi và xuất bản lên CSDL.
          </p>
          <Link
            to="/map-editor"
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: "8px",
              padding: "10px 20px",
              background: "#0284c7",
              color: "#ffffff",
              borderRadius: "8px",
              fontWeight: "600",
              textDecoration: "none",
            }}
          >
            <PencilRuler size={16} />
            Đến trang Thiết kế bản đồ
          </Link>
        </div>
      ) : (
        <>
          {/* 3. Thẻ thống kê thời gian thực */}
          <div className="stats-grid">
            <div className="stat-card" style={{ borderLeft: "4px solid #22c55e" }}>
              <div className="stat-icon" style={{ background: "#dcfce7", color: "#16a34a" }}>
                <CheckCircle2 size={26} />
              </div>
              <div className="stat-info">
                <span className="stat-label">Vị trí trống</span>
                <span className="stat-value" style={{ color: "#16a34a" }}>
                  {stats.available}
                </span>
                <span className="stat-sub">Sẵn sàng nhận xe</span>
              </div>
            </div>

            <div className="stat-card" style={{ borderLeft: "4px solid #ef4444" }}>
              <div className="stat-icon" style={{ background: "#fee2e2", color: "#dc2626" }}>
                <Car size={26} />
              </div>
              <div className="stat-info">
                <span className="stat-label">Vị trí có xe</span>
                <span className="stat-value" style={{ color: "#dc2626" }}>
                  {stats.occupied}
                </span>
                <span className="stat-sub">Đang đỗ xe</span>
              </div>
            </div>

            <div className="stat-card" style={{ borderLeft: "4px solid #f59e0b" }}>
              <div className="stat-icon" style={{ background: "#fef3c7", color: "#d97706" }}>
                <AlertTriangle size={26} />
              </div>
              <div className="stat-info">
                <span className="stat-label">Bảo trì</span>
                <span className="stat-value" style={{ color: "#d97706" }}>
                  {stats.maintenance}
                </span>
                <span className="stat-sub">Tạm ngưng nhận</span>
              </div>
            </div>

            <div className="stat-card" style={{ borderLeft: "4px solid #0284c7" }}>
              <div className="stat-icon" style={{ background: "#e0f2fe", color: "#0284c7" }}>
                <ParkingSquare size={26} />
              </div>
              <div className="stat-info">
                <span className="stat-label">Tổng số ô đỗ</span>
                <span className="stat-value" style={{ color: "#0284c7" }}>
                  {stats.total}
                </span>
                <span className="stat-sub">{floors.length} tầng đỗ xe</span>
              </div>
            </div>

            <div className="stat-card" style={{ borderLeft: "4px solid #8b5cf6" }}>
              <div className="stat-icon" style={{ background: "#f3e8ff", color: "#7c3aed" }}>
                <TrendingUp size={26} />
              </div>
              <div className="stat-info">
                <span className="stat-label">Tỷ lệ lấp đầy</span>
                <span className="stat-value" style={{ color: "#7c3aed" }}>
                  {stats.rate}%
                </span>
                <span className="stat-sub">Công suất bãi xe</span>
              </div>
            </div>
          </div>

          {/* 4. Thanh điều khiển mô phỏng & Chọn tầng */}
          <div className="controls-bar">
            {/* Bộ chuyển tầng */}
            <div className="floor-tabs">
              <span style={{ fontSize: "13px", fontWeight: "700", color: "#475569", marginRight: "4px", display: "flex", alignItems: "center", gap: "4px" }}>
                <Layers size={16} color="#0284c7" />
                Tầng:
              </span>
              {floors.map((floor) => (
                <button
                  key={floor.id}
                  type="button"
                  onClick={() => setCurrentFloorId(floor.id)}
                  className={`floor-tab-btn ${currentFloorId === floor.id ? "active" : ""}`}
                >
                  {floor.name}
                </button>
              ))}
            </div>

            {/* Các nút hành động mô phỏng */}
            <div className="controls-group">
              <button
                type="button"
                onClick={handleSimulateEntry}
                className="btn-sim btn-sim-entry"
                title="Chọn ngẫu nhiên 1 ô trống, chạy thuật toán A* dẫn đường và đổi trạng thái có xe"
              >
                <Car size={16} />
                🚗 Mô phỏng xe vào cổng
              </button>

              <button
                type="button"
                onClick={handleSimulateExit}
                className="btn-sim btn-sim-exit"
                title="Chọn 1 ô có xe, chạy thuật toán A* ra cổng và trả lại ô trống"
              >
                <ArrowRight size={16} />
                🚙 Mô phỏng xe ra cổng
              </button>

              {activePath.length > 0 && (
                <button
                  type="button"
                  onClick={() => {
                    setActivePath([]);
                    setRouteSummary(null);
                  }}
                  className="btn-sim btn-sim-clear"
                >
                  <RotateCcw size={14} />
                  Xóa đường dẫn
                </button>
              )}
            </div>
          </div>

          {/* 5. Banner thông báo lộ trình A* */}
          {routeSummary && (
            <div className="route-banner">
              <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                <Navigation size={18} color="#2563eb" />
                <span>
                  Đang hiển thị tuyến đường dẫn đến ô{" "}
                  <strong>{routeSummary.slotCode}</strong> ({routeSummary.targetFloorName}) — Độ dài:{" "}
                  <strong>{routeSummary.stepCount} bước</strong>.
                  {routeSummary.isMultiFloor && (
                    <span style={{ marginLeft: "6px", color: "#d97706" }}>
                      (Lộ trình liên tầng: {routeSummary.startFloorName} ➔ Dốc ➔ {routeSummary.targetFloorName})
                    </span>
                  )}
                </span>
              </div>

              {routeSummary.isMultiFloor && (
                <button
                  type="button"
                  onClick={() => setCurrentFloorId(routeSummary.targetFloorId)}
                  style={{
                    background: "#2563eb",
                    color: "#ffffff",
                    border: "none",
                    padding: "4px 10px",
                    borderRadius: "6px",
                    fontSize: "12px",
                    fontWeight: "600",
                    cursor: "pointer",
                  }}
                >
                  Chuyển sang {routeSummary.targetFloorName}
                </button>
              )}
            </div>
          )}

          {/* 6. Chi tiết ô đỗ khi Click */}
          {selectedSlot && (
            <div className="slot-detail-card">
              <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                <span
                  style={{
                    fontSize: "18px",
                    fontWeight: "800",
                    color: "#0f172a",
                    background: "#f1f5f9",
                    padding: "6px 12px",
                    borderRadius: "8px",
                  }}
                >
                  {selectedSlot.label}
                </span>
                <div>
                  <div style={{ fontSize: "14px", fontWeight: "700", color: "#1e293b" }}>
                    Loại: {selectedSlot.vehicle_type === "car" ? "Ô tô" : "Xe máy"} • Phân khu:{" "}
                    {selectedSlot.zone_code || "A"}
                  </div>
                  <div style={{ fontSize: "12px", color: "#64748b" }}>
                    Trạng thái:{" "}
                    <strong
                      style={{
                        color:
                          selectedSlot.status === "occupied"
                            ? "#ef4444"
                            : selectedSlot.status === "maintenance"
                            ? "#f59e0b"
                            : "#10b981",
                      }}
                    >
                      {selectedSlot.status === "occupied"
                        ? "Có xe (Occupied)"
                        : selectedSlot.status === "maintenance"
                        ? "Bảo trì"
                        : "Trống (Available)"}
                    </strong>
                  </div>
                </div>
              </div>

              <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                <button
                  type="button"
                  onClick={() => runPathfindingToSlot(selectedSlot, currentFloorId)}
                  style={{
                    background: "#0284c7",
                    color: "#ffffff",
                    border: "none",
                    padding: "6px 14px",
                    borderRadius: "8px",
                    fontSize: "13px",
                    fontWeight: "600",
                    cursor: "pointer",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px",
                  }}
                >
                  <Navigation size={14} />
                  Dẫn đường đến ô này
                </button>

                <button
                  type="button"
                  onClick={() => handleToggleSlotStatus(selectedSlot)}
                  style={{
                    background: "#f8fafc",
                    color: "#334155",
                    border: "1px solid #cbd5e1",
                    padding: "6px 12px",
                    borderRadius: "8px",
                    fontSize: "13px",
                    fontWeight: "600",
                    cursor: "pointer",
                  }}
                >
                  Đổi trạng thái ({selectedSlot.status === "occupied" ? "Thành Trống" : "Thành Có xe"})
                </button>
              </div>
            </div>
          )}

          {/* 7. Canvas vẽ trực tiếp từ Database */}
          {currentFloorData && (
            <LiveMapCanvas
              objects={currentFloorData.objects || []}
              roadCells={currentFloorData.roadCells || []}
              mapSize={currentFloorData.mapSize || { columns: 20, rows: 14 }}
              activePath={activePath}
              currentFloorId={currentFloorId}
              selectedSlot={selectedSlot}
              onSelectSlot={(slot) => {
                if (slot.type === "slot") {
                  setSelectedSlot(slot);
                } else {
                  setSelectedSlot(null);
                }
              }}
            />
          )}
        </>
      )}
    </div>
  );
}
