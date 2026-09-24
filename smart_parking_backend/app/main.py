from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel
from supabase import create_client

from app.config import (
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY,
    DEVICE_API_KEY,
)

app = FastAPI()

supabase = create_client(
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY,
)


class SensorUpdate(BaseModel):
    occupied: bool


@app.post("/api/v1/parking-slots/{slot_code}/sensor")
def update_sensor(
    slot_code: str,
    data: SensorUpdate,
    x_device_key: str = Header(),
):
    if x_device_key != DEVICE_API_KEY:
        raise HTTPException(
            status_code=401,
            detail="Invalid device key",
        )

    try:
        result = (
            supabase
            .table("parking_slots")
            .update({
                "sensor_occupied": data.occupied
            })
            .eq("code", slot_code)
            .select(
                "id, code, sensor_occupied"
            )
            .execute()
        )

        print("SUPABASE RESULT:")
        print(result.data)

        if not result.data:
            raise HTTPException(
                status_code=404,
                detail=f"Không tìm thấy slot {slot_code}",
            )

        return {
            "success": True,
            "data": result.data[0],
        }

    except HTTPException:
        raise

    except Exception as e:
        print("SUPABASE ERROR:")
        print(repr(e))

        raise HTTPException(
            status_code=500,
            detail=str(e),
        )

@app.get("/api/v1/parking-slots")
def get_all_parking_slots(x_device_key: str = Header()):
    if x_device_key != DEVICE_API_KEY:
        raise HTTPException(
            status_code=401,
            detail="Invalid device key",
        )

    try:
        result = (
            supabase
            .table("parking_slots")
            .select(
                "id, code, sensor_occupied"
            )
            .execute()
        )

        print("SUPABASE RESULT:")
        print(result.data)

        return {
            "success": True,
            "data": result.data,
        }

    except HTTPException:
        raise

    except Exception as e:
        print("SUPABASE ERROR:")
        print(repr(e))

        raise HTTPException(
            status_code=500,
            detail=str(e),
        )