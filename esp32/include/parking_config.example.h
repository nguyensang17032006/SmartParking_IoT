#pragma once

// Copy to parking_config.h and edit locally. The local file is ignored by Git.
constexpr char WIFI_SSID[] = "YOUR_WIFI_SSID";
constexpr char WIFI_PASSWORD[] = "YOUR_WIFI_PASSWORD";
// IPv4 of the laptop running FastAPI, on the same Wi-Fi as ESP32.
constexpr char API_BASE_URL[] = "http://192.168.1.10:8000";
constexpr char DEVICE_API_KEY[] = "replace-with-your-random-device-key";
constexpr uint8_t LED_PIN = 25;

struct SlotConfig {
    const char* code;
    uint8_t pin;
    uint8_t occupiedLevel;
};

// Enable only sensors that are physically connected.
constexpr SlotConfig SLOTS[] = {
    {"A01", 27, LOW},
    // {"A02", 26, LOW},
    // {"A03", 33, LOW},
    // {"B01", 32, LOW},
    // {"B02", 18, LOW},
    // {"B03", 19, LOW},
};
constexpr uint32_t DEBOUNCE_MS = 250;
constexpr uint32_t HEARTBEAT_MS = 10000;
constexpr uint32_t RETRY_MS = 3000;
constexpr uint32_t WIFI_RETRY_MS = 10000;
