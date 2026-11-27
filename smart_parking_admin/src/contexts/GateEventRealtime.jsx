import { useEffect } from "react";
import { supabase } from "../lib/supabaseClient";
import toast from "react-hot-toast";

export default function GateEventRealtime() {
    useEffect(() => {
        const channel = supabase
            .channel("gate-events-realtime")
            .on(
                "postgres_changes",
                {
                    event: "INSERT",
                    schema: "public",
                    table: "gate_events",
                },
                async (payload) => {
                    const event = payload.new;

                    if (event.processing_status !== "processed") {
                        toast.error(
                            `Không thể xử lý sự kiện ${event.event_type === "entry"
                                ? "xe vào"
                                : "xe ra"
                            }`
                        );
                        return;
                    }

                    // Lấy thông tin slot vừa được cập nhật
                    const { data: slot, error } = await supabase
                        .from("parking_slots")
                        .select("code, status")
                        .eq("id", event.slot_id)
                        .single();

                    if (error || !slot) {
                        toast.success("Trạng thái bãi xe vừa được cập nhật!");
                        return;
                    }

                    const action =
                        event.event_type === "entry"
                            ? "Xe vào"
                            : "Xe ra";

                    const statusText =
                        slot.status === "occupied"
                            ? "Đã có xe"
                            : "Đang trống";

                    toast.success(
                        `${action} thành công! Slot ${slot.code} - ${statusText}`,
                        {
                            duration: 5000,
                        }
                    );
                }
            )
            .subscribe();

        return () => {
            supabase.removeChannel(channel);
        };
    }, []);

    return null;
}