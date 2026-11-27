
#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <WebSocketsClient.h>
#include <vector>

// ================= WIFI =================
// Thay bằng thông tin WiFi mới của bạn
const char *WIFI_SSID = "AnNhien";
const char *WIFI_PASSWORD = "hoilamgi";

// ================= SUPABASE =================
const char *SUPABASE_HOST = "qnbexgnwzqunxgnfikfm.supabase.co";
const char *SUPABASE_ANON_KEY = "sb_publishable_2j-Bfpr8r2AOKatuleRaJA_rzZvk6SM";

// ================= IR =================
#define IR_ENTRY 18
#define IR_EXIT 19
#define SENSOR_ACTIVE LOW

int previousEntryState = HIGH;
int previousExitState = HIGH;

// ================= SLOT CACHE =================
struct ParkingSlot
{
    String id;
    String code;
    String status;
    bool isActive;
};

std::vector<ParkingSlot> parkingSlots;

WebSocketsClient webSocket;

bool realtimeJoined = false;
bool needRefresh = false;

unsigned long lastHeartbeat = 0;
unsigned long lastWiFiCheck = 0;

uint32_t messageRef = 1;

// Phải dùng ref riêng để phân biệt phản hồi JOIN và HEARTBEAT
const char *REALTIME_JOIN_REF = "join-1";

// ================= WIFI =================
void connectWiFi()
{
    if (WiFi.status() == WL_CONNECTED)
        return;

    Serial.print("Connecting WiFi");

    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    while (WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(".");
    }

    Serial.println("\nWiFi connected!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());

    Serial.print("RSSI: ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
}

// ================= SLOT CACHE HELPERS =================
int findSlotIndex(const String &id)
{
    for (int i = 0; i < (int)parkingSlots.size(); i++)
    {
        if (parkingSlots[i].id == id)
            return i;
    }

    return -1;
}

void upsertSlot(JsonObject record)
{
    String id = record["id"] | "";

    if (id.isEmpty())
        return;

    String status = record["status"] | "";
    String code = record["code"] | "";
    bool active = record["is_active"] | false;

    int index = findSlotIndex(id);

    if (!active ||
        (status != "available" && status != "occupied"))
    {
        if (index >= 0)
            parkingSlots.erase(parkingSlots.begin() + index);

        return;
    }

    ParkingSlot slot;
    slot.id = id;
    slot.code = code;
    slot.status = status;
    slot.isActive = active;

    if (index >= 0)
        parkingSlots[index] = slot;
    else
        parkingSlots.push_back(slot);
}

void removeSlot(JsonObject record)
{
    String id = record["id"] | "";

    if (id.isEmpty())
        return;

    int index = findSlotIndex(id);

    if (index >= 0)
        parkingSlots.erase(parkingSlots.begin() + index);
}

// ================= INITIAL FETCH =================
bool fetchInitialSlots()
{
    if (WiFi.status() != WL_CONNECTED)
    {
        Serial.println("WiFi disconnected!");
        return false;
    }

    WiFiClientSecure client;
    client.setInsecure(); // Chỉ dùng trong quá trình thử nghiệm
    client.setTimeout(15000);

    HTTPClient http;

    String url =
        String("https://") + SUPABASE_HOST +
        "/rest/v1/parking_slots" +
        "?select=id,code,status,is_active" +
        "&is_active=eq.true" +
        "&status=in.(available,occupied)";

    Serial.println("\nFetching initial parking slots...");

    if (!http.begin(client, url))
    {
        Serial.println("HTTP begin failed!");
        return false;
    }

    http.setConnectTimeout(15000);
    http.setTimeout(15000);
    http.setReuse(false);

    http.addHeader("apikey", SUPABASE_ANON_KEY);

    int httpCode = http.GET();

    if (httpCode != HTTP_CODE_OK)
    {
        Serial.printf("Fetch error: %d\n", httpCode);
        Serial.println(http.getString());

        http.end();
        return false;
    }

    String response = http.getString();
    http.end();

    DynamicJsonDocument doc(32768);

    DeserializationError error = deserializeJson(doc, response);

    if (error)
    {
        Serial.print("JSON error: ");
        Serial.println(error.c_str());
        return false;
    }

    if (!doc.is<JsonArray>())
    {
        Serial.println("Invalid slots response!");
        return false;
    }

    std::vector<ParkingSlot> newSlots;

    for (JsonObject item : doc.as<JsonArray>())
    {
        String id = item["id"] | "";
        String status = item["status"] | "";
        String code = item["code"] | "";
        bool active = item["is_active"] | false;

        if (id.isEmpty() || !active)
            continue;

        if (status != "available" && status != "occupied")
            continue;

        ParkingSlot slot;
        slot.id = id;
        slot.code = code;
        slot.status = status;
        slot.isActive = active;

        newSlots.push_back(slot);
    }

    parkingSlots = newSlots;

    Serial.printf(
        "Initial slots loaded: %d\n",
        (int)parkingSlots.size());

    return true;
}

// ================= REALTIME JOIN =================
void sendRealtimeJoin()
{
    DynamicJsonDocument doc(1024);

    doc["topic"] = "realtime:parking_slots";
    doc["event"] = "phx_join";
    doc["ref"] = REALTIME_JOIN_REF;
    doc["join_ref"] = REALTIME_JOIN_REF;

    JsonObject payload = doc.createNestedObject("payload");
    JsonObject config = payload.createNestedObject("config");

    config["private"] = false;

    JsonObject broadcast = config.createNestedObject("broadcast");
    broadcast["ack"] = false;
    broadcast["self"] = false;

    JsonObject presence = config.createNestedObject("presence");
    presence["enabled"] = false;
    presence["key"] = "";

    JsonArray changes = config.createNestedArray("postgres_changes");

    JsonObject change = changes.createNestedObject();
    change["event"] = "*";
    change["schema"] = "public";
    change["table"] = "parking_slots";
    change["filter"] = "";

    String message;
    serializeJson(doc, message);

    webSocket.sendTXT(message);

    Serial.println("Realtime join request sent!");
}

// ================= REALTIME EVENT HANDLER =================
void onWebSocketEvent(
    WStype_t type,
    uint8_t *payload,
    size_t length)
{
    switch (type)
    {
    case WStype_CONNECTED:
        Serial.println("\nRealtime WebSocket connected!");

        realtimeJoined = false;
        sendRealtimeJoin();
        break;

    case WStype_DISCONNECTED:
        Serial.println("Realtime disconnected!");

        realtimeJoined = false;
        break;

    case WStype_ERROR:
        Serial.println("Realtime WebSocket error!");
        break;

    case WStype_TEXT:
    {
        DynamicJsonDocument doc(8192);

        DeserializationError error =
            deserializeJson(doc, payload, length);

        if (error)
        {
            Serial.println("Realtime JSON parse error!");
            return;
        }

        String event = doc["event"] | "";

        // Chỉ xác nhận đúng phản hồi của JOIN
        if (event == "phx_reply")
        {
            String ref = doc["ref"] | "";
            String status = doc["payload"]["status"] | "";

            if (ref == REALTIME_JOIN_REF)
            {
                if (status == "ok")
                {
                    if (!realtimeJoined)
                    {
                        realtimeJoined = true;
                        needRefresh = true;

                        Serial.println(
                            "Realtime subscription successful!");
                    }
                }
                else
                {
                    realtimeJoined = false;

                    Serial.println("Realtime join rejected!");

                    serializeJson(
                        doc["payload"]["response"],
                        Serial);

                    Serial.println();
                }
            }

            // Phản hồi heartbeat không xử lý như JOIN
            return;
        }

        // Có thay đổi trong parking_slots
        if (event == "postgres_changes")
        {
            JsonObject data =
                doc["payload"]["data"].as<JsonObject>();

            String changeType = data["type"] | "";

            JsonObject record =
                data["record"].as<JsonObject>();

            JsonObject oldRecord =
                data["old_record"].as<JsonObject>();

            if (changeType == "DELETE")
            {
                removeSlot(oldRecord);
                Serial.println("Realtime: slot deleted");
            }
            else
            {
                upsertSlot(record);
                Serial.println("Realtime: slot synchronized");
            }

            Serial.printf(
                "Cached slots: %d\n",
                (int)parkingSlots.size());
        }

        if (event == "system")
        {
            Serial.print("Realtime system: ");
            serializeJson(doc["payload"], Serial);
            Serial.println();
        }

        if (event == "phx_error" || event == "phx_close")
        {
            realtimeJoined = false;
            Serial.println("Realtime channel closed/error!");
        }

        break;
    }

    default:
        break;
    }
}

// ================= START REALTIME =================
void startRealtime()
{
    String path =
        String("/realtime/v1/websocket?apikey=") +
        SUPABASE_ANON_KEY +
        "&vsn=1.0.0";

    webSocket.onEvent(onWebSocketEvent);
    webSocket.setReconnectInterval(5000);

    webSocket.beginSSL(
        SUPABASE_HOST,
        443,
        path.c_str());

    Serial.println("Starting Supabase Realtime...");
}

// ================= PHOENIX HEARTBEAT =================
void sendRealtimeHeartbeat()
{
    if (!webSocket.isConnected())
        return;

    if (millis() - lastHeartbeat < 20000)
        return;

    lastHeartbeat = millis();

    DynamicJsonDocument doc(256);

    doc["topic"] = "phoenix";
    doc["event"] = "heartbeat";
    doc["ref"] = String("hb-") + String(messageRef++);

    doc.createNestedObject("payload");

    String message;
    serializeJson(doc, message);

    webSocket.sendTXT(message);
}

// ================= RANDOM SLOT FROM RAM =================
String getRandomSlot(const String &eventType)
{
    String targetStatus =
        (eventType == "entry") ? "available" : "occupied";

    std::vector<int> candidates;

    for (int i = 0; i < (int)parkingSlots.size(); i++)
    {
        if (parkingSlots[i].isActive &&
            parkingSlots[i].status == targetStatus)
        {
            candidates.push_back(i);
        }
    }

    if (candidates.empty())
    {
        Serial.println("No suitable slot in RAM cache!");
        return "";
    }

    int randomIndex = random(0, (long)candidates.size());
    int selectedIndex = candidates[randomIndex];

    ParkingSlot selected = parkingSlots[selectedIndex];

    Serial.println("-----------------------------");
    Serial.println("Random slot selected from RAM!");

    Serial.print("Slot code: ");
    Serial.println(selected.code);

    Serial.print("Slot ID: ");
    Serial.println(selected.id);

    Serial.println("-----------------------------");

    return selected.id;
}

// ================= SEND RPC =================
void sendGateEvent(const String &eventType)
{
    Serial.println("\n===== NEW GATE EVENT =====");

    Serial.print("Event: ");
    Serial.println(eventType);

    String slotId = getRandomSlot(eventType);

    if (slotId.isEmpty())
    {
        Serial.println("Event skipped: no suitable slot.");
        return;
    }

    if (WiFi.status() != WL_CONNECTED)
    {
        Serial.println("WiFi disconnected, event skipped!");
        return;
    }

    // Tạo eventKey MỘT LẦN.
    // Nếu retry phải sử dụng lại chính eventKey này.
    String eventKey =
        String((uint32_t)ESP.getEfuseMac(), HEX) +
        "-" + String(millis()) +
        "-" + String(random(100000, 999999));

    DynamicJsonDocument requestDoc(512);

    requestDoc["p_event_key"] = eventKey;
    requestDoc["p_event_type"] = eventType;
    requestDoc["p_slot_id"] = slotId;

    String requestBody;
    serializeJson(requestDoc, requestBody);

    // Thử gửi tối đa 2 lần
    const int MAX_ATTEMPTS = 2;

    for (int attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)
    {
        Serial.printf(
            "\nSending RPC - Attempt %d/%d\n",
            attempt,
            MAX_ATTEMPTS);

        Serial.printf(
            "Free heap: %u bytes\n",
            ESP.getFreeHeap());

        Serial.printf(
            "WiFi RSSI: %d dBm\n",
            WiFi.RSSI());

        WiFiClientSecure client;
        client.setInsecure(); // Chỉ dùng thử nghiệm
        client.setTimeout(15000);

        HTTPClient http;

        String url =
            String("https://") + SUPABASE_HOST +
            "/rest/v1/rpc/process_gate_event";

        if (!http.begin(client, url))
        {
            Serial.println("Cannot initialize RPC connection!");

            if (attempt < MAX_ATTEMPTS)
            {
                delay(1000);
                continue;
            }

            return;
        }

        http.setConnectTimeout(15000);
        http.setTimeout(15000);
        http.setReuse(false);

        http.addHeader("Content-Type", "application/json");
        http.addHeader("apikey", SUPABASE_ANON_KEY);

        int httpCode = http.POST(requestBody);
        String response = "";

        if (httpCode > 0)
            response = http.getString();

        Serial.printf("RPC HTTP code: %d\n", httpCode);

        if (response.length() > 0)
            Serial.println(response);

        http.end();

        if (httpCode == HTTP_CODE_OK)
        {
            DynamicJsonDocument resultDoc(2048);

            DeserializationError error =
                deserializeJson(resultDoc, response);

            if (error)
            {
                Serial.println("Cannot parse RPC response!");
                return;
            }

            String status =
                resultDoc["processing_status"] | "";

            bool duplicate =
                resultDoc["duplicate"] | false;

            if (status == "processed")
            {
                Serial.println("UPDATE SUCCESS!");

                if (duplicate)
                    Serial.println("Duplicate event detected by server.");

                Serial.print("Slot: ");
                Serial.println(resultDoc["slot_code"] | "");

                Serial.print("Old status: ");
                Serial.println(resultDoc["old_status"] | "");

                Serial.print("New status: ");
                Serial.println(resultDoc["new_status"] | "");
            }
            else
            {
                Serial.println("EVENT REJECTED!");

                Serial.print("Processing status: ");
                Serial.println(status);

                Serial.println(
                    "Waiting for Realtime to synchronize cache.");
            }

            return;
        }

        Serial.println("Supabase RPC request failed!");

        // Chỉ retry với cùng eventKey, slotId và eventType
        if (attempt < MAX_ATTEMPTS)
        {
            Serial.println("Retrying after 1 second...");
            delay(1000);
        }
    }

    Serial.println("RPC failed after all attempts.");
}

// ================= SETUP =================
void setup()
{
    Serial.begin(115200);
    delay(1000);

    pinMode(IR_ENTRY, INPUT);
    pinMode(IR_EXIT, INPUT);

    randomSeed(
        micros() ^ (uint32_t)ESP.getEfuseMac());

    Serial.println("\nSMART PARKING SIMULATOR");
    Serial.println("IR ENTRY: GPIO 18");
    Serial.println("IR EXIT : GPIO 19");

    connectWiFi();

    // Tải snapshot ban đầu
    fetchInitialSlots();

    // Duy trì kết nối Realtime
    startRealtime();
}

// ================= LOOP =================
void loop()
{
    webSocket.loop();

    sendRealtimeHeartbeat();

    // Chỉ tải lại snapshot khi JOIN thành công
    if (realtimeJoined && needRefresh)
    {
        needRefresh = false;

        if (!fetchInitialSlots())
        {
            needRefresh = true;
        }
    }

    // Kiểm tra WiFi định kỳ
    if (millis() - lastWiFiCheck > 5000)
    {
        lastWiFiCheck = millis();

        if (WiFi.status() != WL_CONNECTED)
        {
            Serial.println("WiFi lost!");
            realtimeJoined = false;
            connectWiFi();
        }
    }

    int entryState = digitalRead(IR_ENTRY);
    int exitState = digitalRead(IR_EXIT);

    // ENTRY
    if (entryState == SENSOR_ACTIVE &&
        previousEntryState != SENSOR_ACTIVE)
    {
        delay(50);

        if (digitalRead(IR_ENTRY) == SENSOR_ACTIVE)
        {
            sendGateEvent("entry");
        }
    }

    // EXIT
    if (exitState == SENSOR_ACTIVE &&
        previousExitState != SENSOR_ACTIVE)
    {
        delay(50);

        if (digitalRead(IR_EXIT) == SENSOR_ACTIVE)
        {
            sendGateEvent("exit");
        }
    }

    previousEntryState = digitalRead(IR_ENTRY);
    previousExitState = digitalRead(IR_EXIT);

    delay(20);
}
