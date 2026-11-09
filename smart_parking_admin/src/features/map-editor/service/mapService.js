import { supabase } from "../../../lib/supabaseClient";

// ====================================
// CAMPUSES (CƠ SỞ)
// ====================================

// Lấy tất cả cơ sở
export async function getCampuses() {
    const { data, error } = await supabase
        .from("campuses")
        .select("id, code, name, address")
        .order("code");

    if (error) throw error;

    return data ?? [];
}

// Thêm cơ sở mới
export async function createCampus({ code, name, address }) {
    const { data, error } = await supabase
        .from("campuses")
        .insert([{ code, name, address }])
        .select()
        .single();

    if (error) throw error;
    return data;
}

// Cập nhật cơ sở
export async function updateCampus(id, { code, name, address }) {
    const { data, error } = await supabase
        .from("campuses")
        .update({ code, name, address })
        .eq("id", id)
        .select()
        .single();

    if (error) throw error;
    return data;
}

// Xóa cơ sở
export async function deleteCampus(id) {
    const { error } = await supabase
        .from("campuses")
        .delete()
        .eq("id", id);

    if (error) throw error;
    return true;
}

// ====================================
// PARKING LOTS (BÃI XE)
// ====================================

// Lấy danh sách bãi xe (toàn bộ hoặc theo cơ sở)
export async function getParkingLots(campusId = null) {
    let query = supabase
        .from("parking_lots")
        .select("id, campus_id, name, status")
        .order("name");

    if (campusId) {
        query = query.eq("campus_id", campusId);
    }

    const { data, error } = await query;
    if (error) throw error;

    return data ?? [];
}

// Thêm bãi xe mới
export async function createParkingLot({ campus_id, name, status = "active" }) {
    const { data, error } = await supabase
        .from("parking_lots")
        .insert([{ campus_id, name, status }])
        .select()
        .single();

    if (error) throw error;
    return data;
}

// Cập nhật bãi xe
export async function updateParkingLot(id, { campus_id, name, status }) {
    const { data, error } = await supabase
        .from("parking_lots")
        .update({ campus_id, name, status })
        .eq("id", id)
        .select()
        .single();

    if (error) throw error;
    return data;
}

// Xóa bãi xe
export async function deleteParkingLot(id) {
    const { error } = await supabase
        .from("parking_lots")
        .delete()
        .eq("id", id);

    if (error) throw error;
    return true;
}

// ====================================
// PARKING FLOORS (TẦNG)
// ====================================

// Lấy danh sách tầng của một bãi xe
export async function getParkingFloors(lotId) {
    const { data, error } = await supabase
        .from("parking_floors")
        .select("id, lot_id, code, name, level_number")
        .eq("lot_id", lotId)
        .order("level_number");

    if (error) throw error;

    return data ?? [];
}

// Thêm một tầng
export async function createParkingFloor(
    lotId,
    code,
    name,
    levelNumber
) {
    const { data, error } = await supabase
        .from("parking_floors")
        .insert({
            lot_id: lotId,
            code,
            name,
            level_number: levelNumber,
        })
        .select()
        .single();

    if (error) throw error;

    return data;
}

// Cập nhật tầng
export async function updateParkingFloor(id, { code, name, level_number }) {
    const { data, error } = await supabase
        .from("parking_floors")
        .update({ code, name, level_number })
        .eq("id", id)
        .select()
        .single();

    if (error) throw error;
    return data;
}

// Xóa tầng
export async function deleteParkingFloor(id) {
    const { error } = await supabase
        .from("parking_floors")
        .delete()
        .eq("id", id);

    if (error) throw error;
    return true;
}
