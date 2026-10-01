import logging
from contextlib import asynccontextmanager
from hmac import compare_digest

from fastapi import Depends, FastAPI, Header, HTTPException, Path, Request
from pydantic import BaseModel, ConfigDict, StrictBool
from supabase import create_client

from app.config import Settings

logger = logging.getLogger(__name__)
SLOT_COLUMNS = "id,code,sensor_occupied,last_seen_at,reserved_until,map_x,map_y"


class SensorUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    occupied: StrictBool


def require_device_key(
    request: Request, x_device_key: str | None = Header(default=None)
):
    expected = request.app.state.settings.device_api_key
    if not x_device_key or not compare_digest(
        x_device_key.encode("utf-8"), expected.encode("utf-8")
    ):
        raise HTTPException(status_code=401, detail="Invalid device key")


def create_app(settings: Settings | None = None, database=None):
    @asynccontextmanager
    async def lifespan(application: FastAPI):
        resolved = settings or Settings.from_env()
        if not resolved.device_api_key:
            raise RuntimeError("DEVICE_API_KEY không được để trống")
        application.state.settings = resolved
        application.state.database = database if database is not None else create_client(
            resolved.supabase_url, resolved.supabase_secret_key
        )
        yield

    application = FastAPI(title="Smart Parking IoT", lifespan=lifespan)

    @application.get("/health")
    def health():
        # Liveness only; does not query Supabase.
        return {"status": "ok"}

    @application.post(
        "/api/v1/parking-slots/{slot_code}/sensor",
        dependencies=[Depends(require_device_key)],
    )
    def update_sensor(
        request: Request,
        data: SensorUpdate,
        slot_code: str = Path(pattern=r"^[A-Z][A-Z0-9_-]{0,15}$"),
    ):
        try:
            # One DB transaction updates state, heartbeat and observation history.
            result = request.app.state.database.rpc(
                "ingest_sensor",
                {"p_code": slot_code, "p_occupied": data.occupied},
            ).execute()
        except Exception:
            logger.exception("Cannot update parking sensor")
            raise HTTPException(
                status_code=503, detail="Không thể cập nhật dữ liệu cảm biến"
            ) from None
        if not result.data:
            raise HTTPException(status_code=404, detail=f"Không tìm thấy slot {slot_code}")
        return {"success": True, "data": result.data[0]}

    @application.get(
        "/api/v1/parking-slots", dependencies=[Depends(require_device_key)]
    )
    def get_all_parking_slots(request: Request):
        try:
            result = (
                request.app.state.database.table("parking_slots")
                .select(SLOT_COLUMNS).order("code").execute()
            )
        except Exception:
            logger.exception("Cannot read parking slots")
            raise HTTPException(
                status_code=503, detail="Không thể đọc danh sách chỗ đỗ"
            ) from None
        return {"success": True, "data": result.data}

    return application


app = create_app()
