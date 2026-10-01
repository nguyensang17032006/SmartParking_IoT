#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>

#if __has_include("parking_config.h")
#include "parking_config.h"
#else
#include "parking_config.example.h"
#endif

constexpr size_t SLOT_COUNT = sizeof(SLOTS) / sizeof(SLOTS[0]);
struct SlotState {
    int candidate;
    uint32_t candidateSince;
    bool ready = false;
    bool occupied = false;
    bool dirty = true;
    bool attempted = false;
    bool sent = false;
    uint32_t lastAttempt = 0;
    uint32_t lastSuccess = 0;
};
SlotState states[SLOT_COUNT];
uint32_t lastWifiAttempt = 0;
size_t nextSlot = 0;

bool sendStatus(size_t index) {
    HTTPClient http;
    const String url = String(API_BASE_URL) + "/api/v1/parking-slots/" + SLOTS[index].code + "/sensor";
    // LAN demo uses HTTP. Production requires verified HTTPS.
    if (!http.begin(url)) return false;
    http.setConnectTimeout(1000);
    http.setTimeout(1000);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("X-Device-Key", DEVICE_API_KEY);
    const int code = http.POST(states[index].occupied
        ? "{\"occupied\":true}" : "{\"occupied\":false}");
    Serial.printf("%s: %s, HTTP %d\n", SLOTS[index].code,
        states[index].occupied ? "OCCUPIED" : "FREE", code);
    http.end();
    return code >= 200 && code < 300;
}

void setup() {
    Serial.begin(115200);
    pinMode(LED_PIN, OUTPUT);
    digitalWrite(LED_PIN, LOW);
    for (size_t i = 0; i < SLOT_COUNT; ++i) {
        pinMode(SLOTS[i].pin, INPUT_PULLUP);
        states[i].candidate = digitalRead(SLOTS[i].pin);
        states[i].candidateSince = millis();
    }
    WiFi.mode(WIFI_STA);
    WiFi.setAutoReconnect(true);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    lastWifiAttempt = millis();
    Serial.println("WiFi connecting; sensor sampling continues.");
}

void loop() {
    const uint32_t now = millis();
    bool anyOccupied = false;
    for (size_t i = 0; i < SLOT_COUNT; ++i) {
        auto& state = states[i];
        const int raw = digitalRead(SLOTS[i].pin);
        if (raw != state.candidate) {
            state.candidate = raw;
            state.candidateSince = now;
        }
        if (now - state.candidateSince >= DEBOUNCE_MS) {
            const bool occupied = raw == SLOTS[i].occupiedLevel;
            if (!state.ready || occupied != state.occupied) {
                state.ready = true;
                state.occupied = occupied;
                state.dirty = true;
            }
        }
        anyOccupied |= state.ready && state.occupied;
    }
    digitalWrite(LED_PIN, anyOccupied ? HIGH : LOW);

    if (WiFi.status() != WL_CONNECTED) {
        if (now - lastWifiAttempt >= WIFI_RETRY_MS) {
            lastWifiAttempt = now;
            WiFi.disconnect();
            WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
            Serial.println("Retrying WiFi...");
        }
        delay(10);
        return;
    }

    // One bounded HTTP attempt per loop. Rotate so a failing slot cannot
    // prevent other heartbeats. Unsigned subtraction handles millis rollover.
    for (size_t checked = 0; checked < SLOT_COUNT; ++checked) {
        const size_t i = nextSlot;
        nextSlot = (nextSlot + 1) % SLOT_COUNT;
        auto& state = states[i];
        const bool due = state.dirty || !state.sent || now - state.lastSuccess >= HEARTBEAT_MS;
        const bool retryReady = !state.attempted || now - state.lastAttempt >= RETRY_MS;
        // Never send an unstable reading during an input transition.
        if (state.ready && now - state.candidateSince >= DEBOUNCE_MS && due && retryReady) {
            state.attempted = true;
            state.lastAttempt = now;
            if (sendStatus(i)) {
                state.sent = true;
                state.dirty = false;
                state.lastSuccess = millis();
            }
            break;
        }
    }
    delay(10);
}
