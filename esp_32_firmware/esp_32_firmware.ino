
#include <WiFi.h>
#include <HTTPClient.h>

// ---------- CONFIG: fill these in ----------
const char* WIFI_SSID     = "Ragini's F54";
const char* WIFI_PASSWORD = "12345678";
const char* FIREBASE_HOST = "https://smart-bump-iot-3e764-default-rtdb.asia-southeast1.firebasedatabase.app/";

// ---------- PIN CONFIG ----------
const int TRIG_PIN = 5;
const int ECHO_PIN = 18;

// ---------- GEOFENCE / TIMING CONFIG ----------
const float GEOFENCE_CM       = 25.0;  
const float HYSTERESIS_CM     = 5.0;    
const unsigned long SAMPLE_MS = 100;    

// ---------- STATE ----------
float lastDistance = -1;
unsigned long lastSampleTime = 0;
bool alertArmed = true;

void setup() {
  Serial.begin(115200);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(400);
    Serial.print(".");
  }
  Serial.println("\nConnected. IP: " + WiFi.localIP().toString());
}

float readDistanceCM() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 25000);
  if (duration == 0) return -1;
  return (duration * 0.0343) / 2.0;
}

void sendAlertToFirebase(float distance, float speedKmph) {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  String url = String(FIREBASE_HOST) + "/alerts/latest.json";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  String payload = "{";
  payload += "\"distance_cm\":" + String(distance, 1) + ",";
  payload += "\"speed_kmph\":" + String(speedKmph, 1) + ",";
  payload += "\"alert\":true,";
  payload += "\"timestamp\":" + String(millis());
  payload += "}";

  int code = http.PUT(payload);
  Serial.println("Firebase response: " + String(code));
  http.end();
}

void loop() {
  unsigned long now = millis();
  if (now - lastSampleTime < SAMPLE_MS) return;
  float dt = (now - lastSampleTime) / 1000.0;
  lastSampleTime = now;

  float distance = readDistanceCM();
  if (distance < 0) return;

  float speedKmph = 0;
  if (lastDistance > 0) {
    float deltaCm = lastDistance - distance;
    float speedCmPerSec = deltaCm / dt;
    speedKmph = speedCmPerSec * 0.036;
  }
  lastDistance = distance;

  Serial.printf("Distance: %.1f cm | Speed: %.1f km/h\n", distance, speedKmph);

  if (alertArmed && distance <= GEOFENCE_CM && speedKmph > 0) {
    Serial.println(">>> GEOFENCE TRIGGERED (25cm) - sending alert");
    sendAlertToFirebase(distance, speedKmph);
    alertArmed = false;
  }

  if (!alertArmed && distance > (GEOFENCE_CM + HYSTERESIS_CM)) {
    alertArmed = true;
    Serial.println("Zone cleared - re-armed for next pass");
  }
}
