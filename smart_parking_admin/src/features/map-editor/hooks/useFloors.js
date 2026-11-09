import { useState } from "react";

function isUuid(str) {
    return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str);
}

function loadFloors(storageKey) {
    try {
        const saved = JSON.parse(
            localStorage.getItem(storageKey)
        );

        if (Array.isArray(saved) && saved.length > 0) {
            return saved.map((f, idx) => ({
                id: isUuid(f.id) ? f.id : crypto.randomUUID(),
                code: f.code || (f.id?.startsWith("T") ? f.id : `T${idx + 1}`),
                name: f.name || `Tầng ${idx + 1}`,
                level_number: f.level_number || (idx + 1),
            }));
        }
    } catch (error) {
        console.error("Lỗi tải tầng:", error);
    }

    return [{
        id: crypto.randomUUID(),
        code: "T1",
        name: "Tầng 1",
        level_number: 1,
    }];
}

export default function useFloors(lotId = "default") {
    const storageKey = `smartparking_floors_${lotId}`;

    const [floors, setFloors] = useState(() =>
        loadFloors(storageKey)
    );

    const [currentFloorId, setCurrentFloorId] = useState(() => {
        const initialFloors = loadFloors(storageKey);
        return initialFloors[0]?.id;
    });

    function setAllFloors(newFloors) {
        setFloors(newFloors);
        if (newFloors.length > 0) {
            setCurrentFloorId(newFloors[0].id);
        }
        localStorage.setItem(storageKey, JSON.stringify(newFloors));
    }

    function deleteFloor(floorId) {
        if (floors.length <= 1) {
            return {
                success: false,
                message: "Bãi xe phải có ít nhất một tầng",
            };
        }

        const floor = floors.find((item) => item.id === floorId);

        if (!floor) {
            return {
                success: false,
                message: "Không tìm thấy tầng cần xóa",
            };
        }

        const nextFloors = floors.filter(
            (item) => item.id !== floorId
        );

        const mapStorageKey =
            `smartparking_map_draft_${lotId}_${floorId}`;

        try {
            localStorage.setItem(
                storageKey,
                JSON.stringify(nextFloors)
            );
            localStorage.removeItem(mapStorageKey);
        } catch (error) {
            console.error("Không thể xóa tầng:", error);
            return {
                success: false,
                message: "Không thể cập nhật dữ liệu tầng",
            };
        }

        setFloors(nextFloors);

        if (currentFloorId === floorId) {
            setCurrentFloorId(nextFloors[0].id);
        }

        return {
            success: true,
            message: `Đã xóa ${floor.name}`,
        };
    }

    function addFloor() {
        const numbers = floors
            .map((f) => Number(f.level_number || f.code?.replace("T", "")))
            .filter(Number.isFinite);

        const nextNumber = (numbers.length > 0 ? Math.max(0, ...numbers) : 0) + 1;

        const newFloor = {
            id: crypto.randomUUID(),
            code: `T${nextNumber}`,
            name: `Tầng ${nextNumber}`,
            level_number: nextNumber,
        };

        const nextFloors = [...floors, newFloor];

        setFloors(nextFloors);
        setCurrentFloorId(newFloor.id);

        localStorage.setItem(
            storageKey,
            JSON.stringify(nextFloors)
        );
    }

    function renameFloor(id, name) {
        const nextFloors = floors.map((floor) =>
            floor.id === id
                ? { ...floor, name }
                : floor
        );

        setFloors(nextFloors);

        localStorage.setItem(
            storageKey,
            JSON.stringify(nextFloors)
        );
    }

    return {
        floors,
        setAllFloors,
        currentFloorId,
        setCurrentFloorId,
        addFloor,
        deleteFloor,
        renameFloor,
    };
}
