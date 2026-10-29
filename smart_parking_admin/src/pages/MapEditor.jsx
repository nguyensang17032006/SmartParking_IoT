
import { useEffect } from "react";

import MapCanvas from "../features/map-editor/components/MapCanvas";
import MapToolbar from "../features/map-editor/components/MapToolbar";
import PropertiesPanel from "../features/map-editor/components/PropertiesPanel";
import MapSizePanel from "../features/map-editor/components/MapSizePanel";
import FloorSelector from "../features/map-editor/components/FloorSelector";

import useMapEditor from "../features/map-editor/hooks/useMapEditor";
import useFloors from "../features/map-editor/hooks/useFloors";

import "../styles/map-editor.css";

// Editor riêng cho từng tầng
function FloorMapEditor({ floorId }) {
  const {
    objects,
    roadCells,
    mapSize,
    updateMapSize,
    trimMapEdge,

    selectedId,
    setSelectedId,
    selectedObject,

    tool,
    setTool,
    roadWidth,
    setRoadWidth,
    message,

    addObject,
    updateObject,
    deleteObject,
    paintRoad,
    saveDraft,
  } = useMapEditor(floorId);

  useEffect(() => {
    saveDraft(false);
  }, [objects, roadCells, mapSize]);

  return (
    <>
      <MapToolbar
        tool={tool}
        onToolChange={setTool}
        roadWidth={roadWidth}
        onRoadWidthChange={setRoadWidth}
        onAdd={addObject}
        onSave={saveDraft}
        onDelete={deleteObject}
        selectedId={selectedId}
      />

      <MapSizePanel
        mapSize={mapSize}
        onChange={updateMapSize}
        onTrimEdge={trimMapEdge}
      />

      {message && (
        <div className="map-editor-message">
          {message}
        </div>
      )}

      <div className="map-editor-workspace">
        <MapCanvas
          objects={objects}
          roadCells={roadCells}
          mapSize={mapSize}
          selectedId={selectedId}
          onSelect={setSelectedId}
          onChange={updateObject}
          tool={tool}
          onPaintRoad={paintRoad}
        />

        <PropertiesPanel
          selectedObject={selectedObject}
          onChange={updateObject}
        />
      </div>
    </>
  );
}

export default function MapEditor() {
  const {
    floors,
    currentFloorId,
    setCurrentFloorId,
    addFloor,
    renameFloor,
  } = useFloors();

  return (
    <div className="map-editor-page">
      <div className="map-editor-header">
        <div>
          <h2>Thiết kế sơ đồ bãi xe</h2>
          <p>
            Quản lý nhiều tầng, vẽ đường và
            tùy chỉnh kích thước bản đồ.
          </p>
        </div>

        <span className="map-editor-badge">
          Bản nháp
        </span>
      </div>

      <FloorSelector
        floors={floors}
        currentFloorId={currentFloorId}
        onSelect={setCurrentFloorId}
        onAdd={addFloor}
        onRename={renameFloor}
      />

      <FloorMapEditor
        key={currentFloorId}
        floorId={currentFloorId}
      />
    </div>
  );
}
