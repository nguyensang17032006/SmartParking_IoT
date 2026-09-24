#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>

#define IR_PIN 27
#define LED_PIN 25

const char* WIFI_SSID = "AnNhien";
const char* WIFI_PASSWORD = "hoilamgi";

// Nếu FastAPI đang chạy trên laptop:
// đổi thành IPv4 của laptop, KHÔNG dùng localhost
const char* SERVER_URL =
    "http://192.168.2.236:8000/api/v1/parking-slots/A01/sensor";

// Phải giống DEVICE_API_KEY trong .env backend
const char* DEVICE_API_KEY =
    "esp32-secret-123";

int previousState = HIGH;

void connectWiFi() {
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    Serial.print("Connecting WiFi");

    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }

    Serial.println();
    Serial.println("WiFi connected");

    Serial.print("ESP32 IP: ");
    Serial.println(WiFi.localIP());
}

bool sendStatus(bool occupied) {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi disconnected");
        return false;
    }

    HTTPClient http;

    http.begin(SERVER_URL);

    http.addHeader(
        "Content-Type",
        "application/json"
    );

    http.addHeader(
        "X-Device-Key",
        DEVICE_API_KEY
    );

    String body = occupied
        ? "{\"occupied\":true}"
        : "{\"occupied\":false}";

    Serial.print("POST: ");
    Serial.println(body);

    int httpCode = http.POST(body);

    Serial.print("HTTP code: ");
    Serial.println(httpCode);

    if (httpCode > 0) {
        Serial.print("Response: ");
        Serial.println(http.getString());
    }

    http.end();

    return httpCode >= 200 && httpCode < 300;
}

void setup() {
    Serial.begin(115200);

    pinMode(IR_PIN, INPUT);
    pinMode(LED_PIN, OUTPUT);

    digitalWrite(LED_PIN, LOW);

    connectWiFi();

    // Đọc trạng thái hiện tại khi ESP32 vừa bật
    previousState = digitalRead(IR_PIN);

    bool occupied = previousState == LOW;

    digitalWrite(
        LED_PIN,
        occupied ? HIGH : LOW
    );

    // Gửi trạng thái ban đầu
    sendStatus(occupied);
}

void loop() {
    // Nếu mất WiFi thì kết nối lại
    if (WiFi.status() != WL_CONNECTED) {
        connectWiFi();
    }

    int currentState = digitalRead(IR_PIN);

    // Chỉ xử lý khi cảm biến thay đổi
    if (currentState != previousState) {

        // debounce/chống nhiễu
        delay(200);

        currentState = digitalRead(IR_PIN);

        if (currentState != previousState) {

            bool occupied =
                currentState == LOW;

            digitalWrite(
                LED_PIN,
                occupied ? HIGH : LOW
            );

            if (occupied) {
                Serial.println("A01: OCCUPIED");
            } else {
                Serial.println("A01: AVAILABLE");
            }

            // Chỉ cập nhật state cũ nếu gửi backend thành công
            if (sendStatus(occupied)) {
                previousState = currentState;
            }
        }
    }

    delay(50);
}