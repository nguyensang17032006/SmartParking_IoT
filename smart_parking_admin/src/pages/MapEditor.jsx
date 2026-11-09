import { useEffect, useState } from "react";
import toast from "react-hot-toast";

import MapCanvas from "../features/map-editor/components/MapCanvas";
import MapToolbar from "../features/map-editor/components/MapToolbar";
import PropertiesPanel from "../features/map-editor/components/PropertiesPanel";
import MapSizePanel from "../features/map-editor/components/MapSizePanel";
import FloorSelector from "../features/map-editor/components/FloorSelector";
import ParkingLotSelector from "../components/layout/ParkingLotSelector";
import RampConnectionModal from "../features/map-editor/components/RampConnectionModal";
import ZoneSelector from "../features/map-editor/components/ZoneSelector";

import useMapEditor from "../features/map-editor/hooks/useMapEditor";
import useFloors from "../features/map-editor/hooks/useFloors";

import {
  saveMapToDatabase,
  loadMapFromDatabase,
} from "../features/map-editor/service/mapPersistenceService";

import "../styles/map-editor.css";

// Editor riêng cho từng tầng
function FloorMapEditor({
  lotId,
  floorId,
  floors,
  onOpenRamps,
  onPublish,
  isSaving,
}) {
  const {
    objects,
    roadCells,
    mapSize,
    updateMapSize,
    trimMapEdge,

    // Quản lý phân khu (Zones)
    zones,
    activeZoneId,
    setActiveZoneId,
    addZone,
    updateZone,
    deleteZone,

    selectedIds,
    selectedObject,
    selectObject,
    selectMultiple,

    tool,
    setTool,
    roadWidth,
    setRoadWidth,
    message,

    addObject,
    updateObject,
    deleteSelectedObjects,
    moveSelectedObjects,
    paintRoad,
    saveDraft,
  } = useMapEditor(`${lotId}_${floorId}`);

  useEffect(() => {
    function handleKeyDown(e) {
      const target = e.target;

      const isTyping =
        target instanceof HTMLElement &&
        (
          ["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName) ||
          target.isContentEditable
        );

      if (isTyping) return;
      if (tool !== "select") return;

      if (
        (e.key === "Delete" || e.key === "Backspace") &&
        selectedIds.length > 0
      ) {
        e.preventDefault();
        deleteSelectedObjects();
      }
    }

    window.addEventListener("keydown", handleKeyDown);

    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [selectedIds, tool, deleteSelectedObjects]);

  // Tự động lưu bản nháp vào localStorage mỗi khi thay đổi
  useEffect(() => {
    saveDraft(false);
  }, [objects, roadCells, mapSize, zones]);

  return (
    <>
      <MapToolbar
        tool={tool}
        onToolChange={setTool}
        roadWidth={roadWidth}
        onRoadWidthChange={setRoadWidth}
        onAdd={addObject}
        onSave={() => saveDraft(true)}
        onPublish={onPublish}
        onOpenRamps={onOpenRamps}
        onDelete={deleteSelectedObjects}
        selectedId={selectedIds.length > 0 ? selectedIds[0] : null}
        isSaving={isSaving}
      />

      <ZoneSelector
        zones={zones}
        activeZoneId={activeZoneId}
        onSelectZone={setActiveZoneId}
        onAddZone={addZone}
        onUpdateZone={updateZone}
        onDeleteZone={deleteZone}
        objects={objects}
      />

      <MapSizePanel
        mapSize={mapSize}
        onChange={updateMapSize}
        onTrimEdge={trimMapEdge}
      />

      {message && <div className="map-editor-message">{message}</div>}

      <div className="map-editor-workspace">
        <MapCanvas
          objects={objects}
          roadCells={roadCells}
          mapSize={mapSize}
          selectedIds={selectedIds}
          onSelect={selectObject}
          onSelectMultiple={selectMultiple}
          onChange={updateObject}
          onMoveSelected={moveSelectedObjects}
          tool={tool}
          onPaintRoad={paintRoad}
        />

        <PropertiesPanel
          selectedObject={selectedObject}
          onChange={updateObject}
          zones={zones}
        />
      </div>
    </>
  );
}

function ParkingLotEditor({ lotId }) {
  const {
    floors,
    setAllFloors,
    currentFloorId,
    setCurrentFloorId,
    addFloor,
    renameFloor,
    deleteFloor,
  } = useFloors(lotId);

  const [rampConnections, setRampConnections] = useState(() => {
    try {
      const saved = localStorage.getItem(`smartparking_ramps_${lotId}`);
      return saved ? JSON.parse(saved) : [];
    } catch {
      return [];
    }
  });

  const [isOpenRampModal, setIsOpenRampModal] = useState(false);
  const [mapVersion, setMapVersion] = useState(null);
  const [isSaving, setIsSaving] = useState(false);

  // Tự động tải dữ liệu từ CSDL Supabase khi chọn bãi xe
  useEffect(() => {
    let active = true;

    async function loadData() {
      try {
        const res = await loadMapFromDatabase(lotId);
        if (!active) return;

        if (res.hasData) {
          setAllFloors(res.floors);
          setRampConnections(res.rampConnections || []);
          setMapVersion(res.mapVersion);

          // Cập nhật lại localStorage của từng tầng để component editor đồng bộ
          for (const floor of res.floors) {
            const key = `smartparking_map_draft_${lotId}_${floor.id}`;
            if (res.floorsData[floor.id]) {
              localStorage.setItem(
                key,
                JSON.stringify(res.floorsData[floor.id])
              );
            }
          }

          toast.success(
            `Đã tải bản đồ phiên bản v${res.mapVersion.version_number} từ CSDL!`
          );
        }
      } catch (err) {
        console.error("Lỗi tải bản đồ từ CSDL:", err);
      }
    }

    loadData();

    return () => {
      active = false;
    };
  }, [lotId]);

  function handleDeleteFloor(floorId) {
    if (!window.confirm("Xóa tầng và toàn bộ dữ liệu đối tượng của tầng này?")) {
      return;
    }
    deleteFloor(floorId);
  }

  function handleRampConnectionsChange(newConns) {
    setRampConnections(newConns);
    localStorage.setItem(
      `smartparking_ramps_${lotId}`,
      JSON.stringify(newConns)
    );
  }

  // Thu thập dữ liệu của tất cả các tầng
  function getAllFloorsData() {
    const data = {};
    for (const f of floors) {
      const key = `smartparking_map_draft_${lotId}_${f.id}`;
      try {
        const parsed = JSON.parse(localStorage.getItem(key));
        data[f.id] = parsed || {
          objects: [],
          roadCells: [],
          mapSize: { columns: 30, rows: 20 },
          zones: [],
        };
      } catch {
        data[f.id] = {
          objects: [],
          roadCells: [],
          mapSize: { columns: 30, rows: 20 },
          zones: [],
        };
      }
    }
    return data;
  }

  // Lưu toàn bộ bản đồ lên Supabase (map_versions, parking_floors, zones, slots, elements, ramp_connections)
  async function handleSaveToDatabase(status = "published") {
    setIsSaving(true);
    const toastId = toast.loading("Đang lưu bản đồ vào CSDL Supabase...");

    try {
      const floorsData = getAllFloorsData();

      const result = await saveMapToDatabase(lotId, {
        floors,
        floorsData,
        rampConnections,
        status,
      });

      // Cập nhật lại localStorage với các ID mới sau khi lưu thành công
      for (const f of floors) {
        const key = `smartparking_map_draft_${lotId}_${f.id}`;
        if (floorsData[f.id]) {
          localStorage.setItem(key, JSON.stringify(floorsData[f.id]));
        }
      }
      localStorage.setItem(
        `smartparking_ramps_${lotId}`,
        JSON.stringify(rampConnections)
      );

      setMapVersion({
        id: result.mapVersionId,
        version_number: result.versionNumber,
        status: status,
      });

      toast.success(
        `Lưu bản đồ thành công (v${result.versionNumber})! Đã lưu ${result.zonesCount} phân khu, ${result.slotsCount} ô đỗ, ${result.elementsCount} phần tử bản đồ.`,
        { id: toastId, duration: 5000 }
      );
    } catch (error) {
      console.error("Lỗi lưu bản đồ vào CSDL:", error);
      toast.error("Lưu bản đồ thất bại: " + error.message, {
        id: toastId,
        duration: 5000,
      });
    } finally {
      setIsSaving(false);
    }
  }

  return (
    <>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          flexWrap: "wrap",
          gap: "10px",
          background: "#ffffff",
          padding: "12px 18px",
          borderRadius: "12px",
          border: "1px solid #e5ebf1",
        }}
      >
        <FloorSelector
          floors={floors}
          currentFloorId={currentFloorId}
          onSelect={setCurrentFloorId}
          onAdd={addFloor}
          onRename={renameFloor}
          onDelete={handleDeleteFloor}
        />

        <span
          className="map-editor-badge"
          style={{
            background: mapVersion ? "#e0f2fe" : "#fff2d8",
            color: mapVersion ? "#0369a1" : "#a76b12",
          }}
        >
          {mapVersion
            ? `Phiên bản: v${mapVersion.version_number} (${mapVersion.status === "published" ? "Đã xuất bản" : "Bản nháp"})`
            : "Bản vẽ mới (Chưa lưu CSDL)"}
        </span>
      </div>

      {currentFloorId && (
        <FloorMapEditor
          key={`${lotId}_${currentFloorId}`}
          lotId={lotId}
          floorId={currentFloorId}
          floors={floors}
          onOpenRamps={() => setIsOpenRampModal(true)}
          onPublish={handleSaveToDatabase}
          isSaving={isSaving}
        />
      )}

      {/* Modal kết nối dốc giữa các tầng */}
      <RampConnectionModal
        isOpen={isOpenRampModal}
        onClose={() => setIsOpenRampModal(false)}
        floors={floors}
        floorsData={getAllFloorsData()}
        rampConnections={rampConnections}
        onChangeConnections={handleRampConnectionsChange}
      />
    </>
  );
}

export default function MapEditor() {
  const [campusId, setCampusId] = useState("");
  const [lotId, setLotId] = useState("");

  return (
    <div className="map-editor-page">
      <div className="map-editor-header">
        <div>
          <h2>Thiết kế sơ đồ bãi xe</h2>
          <p>
            Vẽ sơ đồ, bố trí ô đỗ, dốc liên tầng và xuất bản bản đồ lên hệ thống.
          </p>
        </div>
      </div>

      <ParkingLotSelector
        campusId={campusId}
        lotId={lotId}
        onCampusChange={setCampusId}
        onLotChange={setLotId}
      />

      {lotId ? (
        <ParkingLotEditor key={lotId} lotId={lotId} />
      ) : (
        <div className="map-editor-message">
          Vui lòng chọn cơ sở và bãi xe để bắt đầu thiết kế sơ đồ.
        </div>
      )}
    </div>
  );
}
