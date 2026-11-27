import { supabase } from "../../../lib/supabaseClient";
import { OBJECT_TYPES } from "../constants/mapConfig";

const ACCESS_SIDES = ["north", "south", "east", "west"];

/**
 * 1. Lấy phiên bản bản đồ mới nhất (published hoặc draft) của bãi xe
 */
export async function getLatestMapVersion(lotId) {
  const { data, error } = await supabase
    .from("map_versions")
    .select("*")
    .eq("lot_id", lotId)
    .order("version_number", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) throw error;
  return data;
}

/**
 * 2. Tải toàn bộ dữ liệu bản đồ từ Supabase (tầng, zones, slots, elements, ramp_connections)
 */
export async function loadMapFromDatabase(lotId) {
  // 2.1. Lấy danh sách tầng của bãi xe
  const { data: floors, error: floorErr } = await supabase
    .from("parking_floors")
    .select("*")
    .eq("lot_id", lotId)
    .order("level_number", { ascending: true });

  if (floorErr) throw floorErr;

  if (!floors || floors.length === 0) {
    return {
      hasData: false,
      floors: [],
      mapVersion: null,
      floorsData: {},
      rampConnections: [],
    };
  }

  const floorIds = floors.map((f) => f.id);

  // 2.2. Lấy version mới nhất (ưu tiên published hoặc draft)
  const mapVersion = await getLatestMapVersion(lotId);

  // 2.3. Lấy tất cả phân khu (parking_zones) thuộc các tầng này
  const { data: dbZones, error: zoneErr } = await supabase
    .from("parking_zones")
    .select("*")
    .in("floor_id", floorIds);

  if (zoneErr) throw zoneErr;

  if (!mapVersion) {
    // Chưa có version bản đồ nào được tạo
    const floorsData = {};
    for (const floor of floors) {
      const floorZones = (dbZones || []).filter((z) => z.floor_id === floor.id);
      floorsData[floor.id] = {
        objects: [],
        roadCells: [],
        mapSize: {
          columns: floor.grid_columns || 30,
          rows: floor.grid_rows || 20,
        },
        zones:
          floorZones.length > 0
            ? floorZones
            : [
                {
                  id: crypto.randomUUID(),
                  code: "A",
                  name: "Khu A",
                  color: "#10b981",
                },
              ],
      };
    }

    return {
      hasData: false,
      floors,
      mapVersion: null,
      floorsData,
      rampConnections: [],
    };
  }

  // 2.4. Lấy tất cả map_elements thuộc map_version này
  const { data: elements, error: elemErr } = await supabase
    .from("map_elements")
    .select("*, parking_slots(id, code, vehicle_type, status, zone_id)")
    .eq("map_version_id", mapVersion.id);

  if (elemErr) throw elemErr;

  // 2.5. Lấy ramp_connections liên quan đến các elements này
  const elementIds = (elements || []).map((e) => e.id);
  let rampConnections = [];

  if (elementIds.length > 0) {
    const { data: conns, error: connErr } = await supabase
      .from("ramp_connections")
      .select("*")
      .in("from_element_id", elementIds);

    if (!connErr && conns) {
      rampConnections = conns;
    }
  }

  // 2.6. Tái cấu trúc floorsData theo từng floorId
  const floorsData = {};
  for (const floor of floors) {
    const floorZones = (dbZones || []).filter((z) => z.floor_id === floor.id);
    const activeZones =
      floorZones.length > 0
        ? floorZones
        : [
            {
              id: crypto.randomUUID(),
              code: "A",
              name: "Khu A",
              color: "#10b981",
            },
          ];

    const floorElements = (elements || []).filter(
      (e) => e.floor_id === floor.id
    );

    const objects = [];
    const roadCells = [];

    for (const el of floorElements) {
      if (el.element_type === "road") {
        roadCells.push({ x: el.grid_x, y: el.grid_y });
      } else {
        const zone =
          activeZones.find((z) => z.id === el.zone_id) || activeZones[0];

        objects.push({
          id: el.id,
          type: el.element_type === "gate" ? "gate_in" : el.element_type,
          label: el.label || "",
          x: el.grid_x,
          y: el.grid_y,
          width: el.grid_width,
          height: el.grid_height,
          rotation: el.rotation || 0,
          direction: el.direction || "two_way",
          access_side: ACCESS_SIDES.includes(el.access_side)
            ? el.access_side
            : OBJECT_TYPES[el.element_type]?.accessSide || null,
          slot_id: el.slot_id,
          zone_id: el.zone_id || zone?.id,
          zone_code: zone?.code || "A",
          vehicle_type: el.parking_slots?.vehicle_type || "motorbike",
          status: el.parking_slots?.status || "available",
        });
      }
    }

    floorsData[floor.id] = {
      objects,
      roadCells,
      mapSize: {
        columns: floor.grid_columns || 30,
        rows: floor.grid_rows || 20,
      },
      zones: activeZones,
    };
  }

  return {
    hasData: true,
    mapVersion,
    floors,
    floorsData,
    rampConnections,
  };
}

/**
 * 3. Lưu toàn bộ bản đồ vào Supabase:
 *    - parking_floors
 *    - map_versions
 *    - parking_zones (đúng phân khu cho từng tầng: Khu A, Khu B...)
 *    - parking_slots (thuộc zone tương ứng: A01, A02, B01...)
 *    - map_elements (lưu định vị mọi element, xóa sạch element bị xóa trên map)
 *    - ramp_connections (kết nối dốc giữa các tầng)
 */
export async function saveMapToDatabase(
  lotId,
  { floors, floorsData, rampConnections = [], status = "published" }
) {
  if (!lotId) throw new Error("Chưa chọn bãi xe (lotId) để lưu!");
  if (!floors || floors.length === 0) {
    throw new Error("Bãi xe cần có ít nhất một tầng!");
  }

  // ==========================================
  // BƯỚC 1: ĐỒNG BỘ PARKING_FLOORS
  // ==========================================
  const floorRows = floors.map((f, idx) => {
    const fData = floorsData[f.id];
    return {
      id: f.id,
      lot_id: lotId,
      code: f.code || `T${idx + 1}`,
      name: f.name || `Tầng ${idx + 1}`,
      level_number: f.level_number ?? idx + 1,
      grid_columns: fData?.mapSize?.columns || f.grid_columns || 30,
      grid_rows: fData?.mapSize?.rows || f.grid_rows || 20,
    };
  });

  const { error: floorErr } = await supabase
    .from("parking_floors")
    .upsert(floorRows, { onConflict: "id" });

  if (floorErr) throw new Error("Lỗi lưu tầng: " + floorErr.message);

  const floorIds = floorRows.map((f) => f.id);

  // ==========================================
  // BƯỚC 2: TẠO HOẶC CẬP NHẬT MAP_VERSIONS
  // Xử lý ràng buộc unique "map_one_published_per_lot"
  // ==========================================
  const latestVer = await getLatestMapVersion(lotId);
  const nextVerNumber = (latestVer?.version_number || 0) + 1;

  let mapVersionId = null;

  if (status === "draft" && latestVer && latestVer.status === "draft") {
    mapVersionId = latestVer.id;
  } else {
    // Nếu chuẩn bị xuất bản (status === 'published'):
    // Trước tiên chuyển tất cả phiên bản 'published' hiện tại của bãi này thành 'archived'
    if (status === "published") {
      const { error: archiveErr } = await supabase
        .from("map_versions")
        .update({ status: "archived" })
        .eq("lot_id", lotId)
        .eq("status", "published");

      if (archiveErr) {
        throw new Error(
          "Lỗi chuyển phiên bản cũ sang archived: " + archiveErr.message
        );
      }
    }

    // Tạo phiên bản mới
    const { data: newVer, error: verErr } = await supabase
      .from("map_versions")
      .insert({
        lot_id: lotId,
        version_number: nextVerNumber,
        status: status,
        published_at: status === "published" ? new Date().toISOString() : null,
      })
      .select()
      .single();

    if (verErr) throw new Error("Lỗi tạo phiên bản bản đồ: " + verErr.message);
    mapVersionId = newVer.id;
  }

  // ==========================================
  // BƯỚC 3: ĐỒNG BỘ PARKING_ZONES CHO MỖI TẦNG
  // ==========================================
  const activeZoneRows = [];
  const activeZoneIds = new Set();
  const zoneMapByFloor = {}; // { [floorId]: Zone[] }

  for (const f of floorRows) {
    const fData = floorsData[f.id] || {};
    let fZones = fData.zones || [];

    if (!Array.isArray(fZones) || fZones.length === 0) {
      fZones = [
        {
          id: crypto.randomUUID(),
          code: "A",
          name: "Khu A",
          color: "#10b981",
        },
      ];
    }

    zoneMapByFloor[f.id] = fZones;

    for (const z of fZones) {
      activeZoneRows.push({
        id: z.id,
        floor_id: f.id,
        code: (z.code || "A").toUpperCase(),
        name: z.name || `Khu ${(z.code || "A").toUpperCase()}`,
        color: z.color || "#10b981",
      });
      activeZoneIds.add(z.id);
    }
  }

  if (activeZoneRows.length > 0) {
    const { error: zoneUpsertErr } = await supabase
      .from("parking_zones")
      .upsert(activeZoneRows, { onConflict: "id" });

    if (zoneUpsertErr) {
      throw new Error("Lỗi lưu phân khu (parking_zones): " + zoneUpsertErr.message);
    }
  }

  // ==========================================
  // BƯỚC 4: ĐỒNG BỘ PARKING_SLOTS CHO CÁC Ô ĐỖ
  // ==========================================
  const activeSlotRows = [];
  const activeSlotIds = new Set();

  for (const f of floorRows) {
    const fData = floorsData[f.id] || { objects: [] };
    const defaultZone = zoneMapByFloor[f.id]?.[0];

    for (const obj of fData.objects || []) {
      if (obj.type === "slot") {
        const slotId = obj.slot_id || crypto.randomUUID();
        obj.slot_id = slotId;

        // Đảm bảo slot có zone_id hợp lệ
        const slotZoneId =
          obj.zone_id && activeZoneIds.has(obj.zone_id)
            ? obj.zone_id
            : defaultZone?.id;

        obj.zone_id = slotZoneId;

        activeSlotRows.push({
          id: slotId,
          zone_id: slotZoneId,
          code: obj.label || "A01",
          vehicle_type: ["motorbike", "car", "other"].includes(obj.vehicle_type)
            ? obj.vehicle_type
            : "motorbike",
          status: ["available", "occupied", "maintenance"].includes(obj.status)
            ? obj.status
            : "available",
          is_active: true,
          updated_at: new Date().toISOString(),
        });

        activeSlotIds.add(slotId);
      }
    }
  }

  if (activeSlotRows.length > 0) {
    const { error: slotErr } = await supabase
      .from("parking_slots")
      .upsert(activeSlotRows, { onConflict: "id" });

    if (slotErr) {
      throw new Error("Lỗi lưu ô đỗ (parking_slots): " + slotErr.message);
    }
  }

  // ==========================================
  // BƯỚC 5: XÓA SẠCH MAP_ELEMENTS VÀ RAMP_CONNECTIONS CŨ
  // Đảm bảo khi người dùng xóa element trên map thì bên Supabase cũng bị xóa sạch hoàn toàn!
  // ==========================================
  const { data: lotVersions } = await supabase
    .from("map_versions")
    .select("id")
    .eq("lot_id", lotId);

  const lotVersionIds = (lotVersions || []).map((v) => v.id);

  if (lotVersionIds.length > 0) {
    // 5.1. Lấy tất cả elements cũ của bãi xe để xóa ramp_connections
    const { data: lotOldElems } = await supabase
      .from("map_elements")
      .select("id")
      .in("map_version_id", lotVersionIds);

    const lotOldElemIds = (lotOldElems || []).map((e) => e.id);

    if (lotOldElemIds.length > 0) {
      // Xóa tất cả ramp_connections liên quan đến các elements cũ này
      await supabase
        .from("ramp_connections")
        .delete()
        .or(
          `from_element_id.in.(${lotOldElemIds.join(",")}),to_element_id.in.(${lotOldElemIds.join(",")})`
        );
    }

    // 5.2. Xóa toàn bộ map_elements của các phiên bản cũ để giải phóng khóa ngoại slot_id
    await supabase
      .from("map_elements")
      .delete()
      .in("map_version_id", lotVersionIds);

    // 5.3. Xóa các phiên bản cũ đã bị thay thế (chỉ giữ phiên bản hiện tại)
    const prevVersionIds = lotVersionIds.filter((vid) => vid !== mapVersionId);
    if (prevVersionIds.length > 0) {
      await supabase
        .from("map_versions")
        .delete()
        .in("id", prevVersionIds);
    }
  }

  // ==========================================
  // BƯỚC 6: XÓA CÁC Ô ĐỖ (SLOTS) VÀ PHÂN KHU (ZONES) ĐÃ BỊ XÓA TRÊN BẢN ĐỒ
  // ==========================================
  // 6.1. Xóa ô đỗ xe không còn tồn tại trên bản đồ
  const { data: existingDbZones } = await supabase
    .from("parking_zones")
    .select("id")
    .in("floor_id", floorIds);

  const allFloorZoneIds = (existingDbZones || []).map((z) => z.id);

  if (allFloorZoneIds.length > 0) {
    const { data: existingSlots } = await supabase
      .from("parking_slots")
      .select("id")
      .in("zone_id", allFloorZoneIds);

    const slotsToDelete = (existingSlots || [])
      .map((s) => s.id)
      .filter((id) => !activeSlotIds.has(id));

    if (slotsToDelete.length > 0) {
      const { error: delSlotErr } = await supabase
        .from("parking_slots")
        .delete()
        .in("id", slotsToDelete);

      if (delSlotErr) {
        console.warn("Cảnh báo xóa ô đỗ cũ:", delSlotErr.message);
      }
    }
  }

  // 6.2. Xóa các phân khu (zones) không còn dùng
  const zonesToDelete = allFloorZoneIds.filter((zid) => !activeZoneIds.has(zid));
  if (zonesToDelete.length > 0) {
    const { error: delZoneErr } = await supabase
      .from("parking_zones")
      .delete()
      .in("id", zonesToDelete);

    if (delZoneErr) {
      console.warn("Cảnh báo xóa phân khu cũ:", delZoneErr.message);
    }
  }

  // ==========================================
  // BƯỚC 7: TẠO VÀ INSERT MAP_ELEMENTS MỚI
  // ==========================================
  const validElementTypes = [
    "zone",
    "slot",
    "road",
    "gate_in",
    "gate_out",
    "ramp",
    "obstacle",
  ];

  // Map giữ nguyên hoặc cấp mới ID cho từng đối tượng
  const elementIdMap = {};
  for (const f of floorRows) {
    const fData = floorsData[f.id] || { objects: [], roadCells: [] };
    for (const obj of fData.objects || []) {
      const newElemId = crypto.randomUUID();
      elementIdMap[obj.id] = newElemId;
    }
  }

  const elementRows = [];

  for (const f of floorRows) {
    const fData = floorsData[f.id] || { objects: [], roadCells: [] };
    const defaultZone = zoneMapByFloor[f.id]?.[0];

    // Thêm các đối tượng (slot, gate, ramp, obstacle)
    for (const obj of fData.objects || []) {
      let elementType = obj.type;
      if (elementType === "gate") elementType = "gate_in";
      if (!validElementTypes.includes(elementType)) {
        elementType = "obstacle";
      }

      const newId = elementIdMap[obj.id] || crypto.randomUUID();
      const isSlot = elementType === "slot";

      elementRows.push({
        id: newId,
        map_version_id: mapVersionId,
        floor_id: f.id,
        zone_id: isSlot ? obj.zone_id || defaultZone?.id : null,
        slot_id: isSlot ? obj.slot_id : null,
        element_type: elementType,
        label: obj.label || "",
        grid_x: Math.max(0, Math.round(obj.x)),
        grid_y: Math.max(0, Math.round(obj.y)),
        grid_width: Math.max(1, Math.round(obj.width || 1)),
        grid_height: Math.max(1, Math.round(obj.height || 1)),
        rotation: [0, 90, 180, 270].includes(obj.rotation) ? obj.rotation : 0,
        direction: ["two_way", "one_way", "none"].includes(obj.direction)
          ? obj.direction
          : "two_way",
        access_side: ACCESS_SIDES.includes(obj.access_side)
          ? obj.access_side
          : OBJECT_TYPES[obj.type]?.accessSide || null,
      });

      // Cập nhật lại ID cho đối tượng trong bộ nhớ
      obj.id = newId;
    }

    // Thêm các ô đường đi (road)
    for (const cell of fData.roadCells || []) {
      elementRows.push({
        id: crypto.randomUUID(),
        map_version_id: mapVersionId,
        floor_id: f.id,
        zone_id: null,
        slot_id: null,
        element_type: "road",
        label: null,
        grid_x: Math.max(0, Math.round(cell.x)),
        grid_y: Math.max(0, Math.round(cell.y)),
        grid_width: 1,
        grid_height: 1,
        rotation: 0,
        direction: "two_way",
        access_side: null,
      });
    }
  }

  // Insert theo từng batch 500 bản ghi để tối ưu hiệu năng
  const BATCH_SIZE = 500;
  for (let i = 0; i < elementRows.length; i += BATCH_SIZE) {
    const batch = elementRows.slice(i, i + BATCH_SIZE);
    const { error: elemErr } = await supabase
      .from("map_elements")
      .insert(batch);

    if (elemErr) {
      throw new Error(
        "Lỗi lưu phần tử bản đồ (map_elements): " + elemErr.message
      );
    }
  }

  // ==========================================
  // BƯỚC 8: LƯU RAMP_CONNECTIONS (KẾT NỐI DỐC GIỮA CÁC TẦNG)
  // ==========================================
  let savedRampCount = 0;
  if (rampConnections.length > 0) {
    const validElementIds = new Set(elementRows.map((e) => e.id));

    const validConnections = rampConnections
      .map((c) => {
        const fromId = elementIdMap[c.from_element_id] || c.from_element_id;
        const toId = elementIdMap[c.to_element_id] || c.to_element_id;

        c.from_element_id = fromId;
        c.to_element_id = toId;

        return {
          id: crypto.randomUUID(),
          from_element_id: fromId,
          to_element_id: toId,
          direction: ["two_way", "one_way"].includes(c.direction)
            ? c.direction
            : "two_way",
        };
      })
      .filter(
        (c) =>
          validElementIds.has(c.from_element_id) &&
          validElementIds.has(c.to_element_id)
      );

    if (validConnections.length > 0) {
      const { error: rampErr } = await supabase
        .from("ramp_connections")
        .insert(validConnections);

      if (rampErr) {
        throw new Error(
          "Lỗi lưu kết nối dốc (ramp_connections): " + rampErr.message
        );
      }
      savedRampCount = validConnections.length;
    }
  }

  return {
    success: true,
    versionNumber: nextVerNumber,
    mapVersionId,
    elementsCount: elementRows.length,
    slotsCount: activeSlotRows.length,
    zonesCount: activeZoneRows.length,
    rampsCount: savedRampCount,
  };
}
