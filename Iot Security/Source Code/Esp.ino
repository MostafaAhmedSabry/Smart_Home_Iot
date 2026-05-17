#include <WiFi.h>
#include <PubSubClient.h>
#include <HardwareSerial.h>
#include <ESP32Servo.h>

// ================= WIFI =================
const char* ssid = "MOSTAFA";
const char* password = "Mostafa712001#";

// ================= MQTT =================
const char* mqtt_server = "broker.hivemq.com";

WiFiClient espClient;
PubSubClient client(espClient);

HardwareSerial ArduinoSerial(2);

// ================= PINS =================
#define LAMP          26
#define BUZZER        25
#define PUMP          27
#define FAN           14

#define DOOR_SERVO    18
#define WINDOW_SERVO  12

Servo doorServo;
Servo windowServo;

// ================= SENSOR DATA =================
float temp = 0;
float hum = 0;

int gas = 0;
int soil = 0;
int rain = 0;
int pir = 0;
int distance = 0;

// ================= PASSWORD =================
String doorPassword = "123258";

bool doorOpened = false;
unsigned long doorTimer = 0;

// ================= FLAGS =================
bool autoMode = true;   // النظام يبدأ في وضع AUTO

// ================= SETUP =================
void setup() {
  Serial.begin(115200);
  ArduinoSerial.begin(9600, SERIAL_8N1, 16, 17);

  pinMode(LAMP, OUTPUT);
  pinMode(BUZZER, OUTPUT);
  pinMode(PUMP, OUTPUT);
  pinMode(FAN, OUTPUT);

  // Relay OFF
  digitalWrite(LAMP, HIGH);
  digitalWrite(BUZZER, LOW);
  digitalWrite(PUMP, HIGH);
  digitalWrite(FAN, HIGH);

  // Door Servo
  doorServo.setPeriodHertz(50);
  doorServo.attach(DOOR_SERVO, 500, 2400);
  doorServo.write(0);

  // Window Servo
  windowServo.setPeriodHertz(50);
  windowServo.attach(WINDOW_SERVO, 500, 2400);
  windowServo.write(0);

  // WIFI
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected");

  // MQTT
  client.setServer(mqtt_server, 1883);
  client.setCallback(callback);
}

// ================= LOOP =================
void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  if (ArduinoSerial.available()) {
    String data = ArduinoSerial.readStringUntil('\n');

    sscanf(
      data.c_str(),
      "%f,%f,%d,%d,%d,%d,%d",
      &temp,
      &hum,
      &gas,
      &soil,
      &rain,
      &pir,
      &distance
    );

    sendSensorData();
    smartLogic();
  }

  // AUTO CLOSE DOOR
  if (doorOpened && millis() - doorTimer > 3000) {
    doorServo.write(0);
    doorOpened = false;
    client.publish("home/alert", "Door Closed");
  }
}

// ================= SEND SENSOR DATA =================
void sendSensorData() {
  String json = "{";
  json += "\"temp\":" + String(temp) + ",";
  json += "\"hum\":" + String(hum) + ",";
  json += "\"gas\":" + String(gas) + ",";
  json += "\"soil\":" + String(soil) + ",";
  json += "\"rain\":" + String(rain) + ",";
  json += "\"pir\":" + String(pir) + ",";
  json += "\"distance\":" + String(distance);
  json += "}";

  client.publish("home/sensors/data", json.c_str());
}
void smartLogic() {

  if (!autoMode) return;

  // ================= STATES =================

  bool doorOpen = false;
  bool windowOpen = false;

  bool pumpOn = false;
  bool fanOn = false;
  bool lampOn = false;
  bool buzzerOn = false;

  // ==================================================
  // RAIN (أعلى أولوية للشباك)
  // ==================================================

  if (rain == 1) {

    windowOpen = false;

    client.publish("home/alert", "☔ Rain detected");
  }
  else {

    windowOpen = true;
  }

  // ==================================================
  // GAS
  // ==================================================

  if (gas >= 200) {

    doorOpen = true;

    windowOpen = true;

    fanOn = true;

    buzzerOn = true;

    client.publish("home/alert", "💨 GAS DETECTED");
  }

  // ==================================================
  // TEMPERATURE
  // ==================================================

  if (temp >= 35) {

    doorOpen = true;

    // لو مفيش مطر افتح الشباك
    if (rain == 0) {

      windowOpen = true;
    }

    pumpOn = true;

    buzzerOn = true;

    client.publish("home/alert", "🌡️ HIGH TEMPERATURE");
  }

  // ==================================================
  // SOIL
  // ==================================================

  if (soil < 30) {

    pumpOn = true;

    client.publish("home/alert", "🌱 SOIL DRY");
  }

  // ==================================================
  // PIR
  // ==================================================

  if (pir == 1) {

    lampOn = true;

    client.publish("home/alert", "👀 MOTION DETECTED");
  }

  // ==================================================
  // DISTANCE
  // ==================================================

  if (distance <= 20) {

    buzzerOn = true;

    client.publish("home/alert", "📏 OBJECT DETECTED");
  }

  // ==================================================
  // APPLY STATES
  // ==================================================

  // ===== DOOR =====

  if (doorOpen) {

    doorServo.write(90);
  }
  else {

    doorServo.write(0);
  }

  // ===== WINDOW =====

  if (windowOpen) {

    windowServo.write(90);
  }
  else {

    windowServo.write(0);
  }

  // ===== PUMP =====

  digitalWrite(PUMP, pumpOn ? LOW : HIGH);

  // ===== FAN =====

  digitalWrite(FAN, fanOn ? LOW : HIGH);

  // ===== LAMP =====

  digitalWrite(LAMP, lampOn ? LOW : HIGH);

  // ===== BUZZER =====

  digitalWrite(BUZZER, buzzerOn ? HIGH : LOW);
}

// ================= MQTT CALLBACK =================
void callback(char* topic, byte* payload, unsigned int length) {
  String msg = "";
  for (int i = 0; i < length; i++) {
    msg += (char)payload[i];
  }
  String t = String(topic);

  if (t == "home/control/mode") {
    autoMode = (msg == "AUTO");
    client.publish("home/alert", autoMode ? "System in AUTO mode" : "System in MANUAL mode");
  }

  if (t == "home/control/pump" && !autoMode) {
    digitalWrite(PUMP, msg == "ON" ? LOW : HIGH);
  }

  if (t == "home/control/window" && !autoMode) {
    windowServo.write(msg == "OPEN" ? 90 : 0);
  }

  if (t == "home/control/door" && !autoMode) {
    if (msg == doorPassword) {
      doorServo.write(90);
      doorOpened = true;
      doorTimer = millis();
      client.publish("home/alert", "✅ DOOR OPENED (Manual)");
    } else {
      digitalWrite(BUZZER, HIGH);
      delay(1000);
      digitalWrite(BUZZER, LOW);
      client.publish("home/alert", "❌ WRONG PASSWORD");
    }
  }

  if (t == "home/control/lamp" && !autoMode) {
    digitalWrite(LAMP, msg == "ON" ? LOW : HIGH);
  }
}

// ================= MQTT RECONNECT =================
void reconnect() {
  while (!client.connected()) {
    if (client.connect("ESP32_SMART_HOME")) {
      client.subscribe("home/control/lamp");
      client.subscribe("home/control/pump");
      client.subscribe("home/control/window");
      client.subscribe("home/control/door");
      client.subscribe("home/control/mode");
      client.publish("home/alert", "ESP32 CONNECTED");
    } else {
      delay(2000);
    }
  }
}
