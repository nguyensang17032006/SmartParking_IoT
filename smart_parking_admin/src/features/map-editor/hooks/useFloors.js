
import { useState } from "react";

const STORAGE_KEY = "smartparking_floors_v1";

const DEFAULT_FLOORS = [
    { id: "T1", name: "Tầng 1" },
];

function loadFloors() {
    try {
        const saved = JSON.parse(
            localStorage.getItem(STORAGE_KEY)
        );

        if (Array.isArray(saved) && saved.length > 0) {
            return saved;
        }
    } catch (error) {
        console.error("Lỗi tải danh sách tầng:", error);
    }

    return DEFAULT_FLOORS;
}

export default function useFloors() {
    const [floors, setFloors] = useState(loadFloors);
    const [currentFloorId, setCurrentFloorId] = useState(
        () => loadFloors()[0].id
    );

    function addFloor() {
        const numbers = floors
            .map((f) => Number(f.id.replace("T", "")))
            .filter(Number.isFinite);

        const nextNumber = Math.max(0, ...numbers) + 1;

        const newFloor = {
            id: `T${nextNumber}`,
            name: `Tầng ${nextNumber}`,
        };

        const nextFloors = [...floors, newFloor];

        setFloors(nextFloors);
        setCurrentFloorId(newFloor.id);

        localStorage.setItem(
            STORAGE_KEY,
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
            STORAGE_KEY,
            JSON.stringify(nextFloors)
        );
    }

    return {
        floors,
        currentFloorId,
        setCurrentFloorId,
        addFloor,
        renameFloor,
    };
}
