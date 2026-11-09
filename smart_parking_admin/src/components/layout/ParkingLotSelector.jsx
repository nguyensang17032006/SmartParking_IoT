
import { useEffect, useState } from "react";

import {
    getCampuses,
    getParkingLots,
} from "../../features/map-editor/service/mapService.js";

export default function ParkingLotSelector({
    campusId,
    lotId,
    onCampusChange,
    onLotChange,
}) {
    const [campuses, setCampuses] = useState([]);
    const [lots, setLots] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState("");

    useEffect(() => {
        let active = true;

        async function loadCampuses() {
            try {
                const data = await getCampuses();
                if (active) setCampuses(data);
            } catch (err) {
                console.error("Lỗi getCampuses từ Supabase:", err);
                if (active) setError(err.message);
            }
        }

        loadCampuses();

        return () => {
            active = false;
        };
    }, []);

    useEffect(() => {
        if (!campusId) return;

        let active = true;

        async function loadLots() {
            setLoading(true);
            setError("");

            try {
                const data = await getParkingLots(campusId);
                if (active) setLots(data);
            } catch (err) {
                console.error("Lỗi getCampuses từ Supabase:", err);
                if (active) setError(err.message);
            } finally {
                if (active) setLoading(false);
            }
        }

        loadLots();

        return () => {
            active = false;
        };
    }, [campusId]);

    function handleCampusChange(e) {
        const id = e.target.value;

        setLots([]);
        onCampusChange(id);
        onLotChange("");
    }

    return (
        <div className="parking-lot-selector">
            <label>
                Cơ sở
                <select
                    value={campusId}
                    onChange={handleCampusChange}
                >
                    <option value="">-- Chọn cơ sở --</option>

                    {campuses.map((campus) => (
                        <option key={campus.id} value={campus.id}>
                            {campus.code} - {campus.name}
                        </option>
                    ))}
                </select>
            </label>

            <label>
                Bãi xe
                <select
                    value={lotId}
                    disabled={!campusId || loading}
                    onChange={(e) => onLotChange(e.target.value)}
                >
                    <option value="">
                        {loading ? "Đang tải..." : "-- Chọn bãi xe --"}
                    </option>

                    {lots.map((lot) => (
                        <option key={lot.id} value={lot.id}>
                            {lot.name}
                        </option>
                    ))}
                </select>
            </label>

            {error && <p className="selector-error">{error}</p>}
        </div>
    );
}
