import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class MqttProvider extends ChangeNotifier {
  late MqttServerClient client;
  bool isConnected = false;
  bool autoMode = true;

  // Sensor values
  double temperature = 0;
  double humidity = 0;
  int gas = 0;
  int soil = 0;
  int rain = 0;
  int motion = 0;

  // Device states
  bool windowOn = false;
  bool pumpOn = false;
  bool lampOn = false;
  bool doorOn = false;

  // Alerts
  List<Map<String, dynamic>> alerts = [];
  bool hasNewAlert = false;

  Future<void> setupConnection(
      String broker, int port, String clientId) async {
    client = MqttServerClient(broker, clientId);
    client.port = port;
    client.keepAlivePeriod = 20;
    client.autoReconnect = true;
    client.logging(on: false);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    await connect();
  }

  Future<void> connect() async {
    try {
      await client.connect();
    } catch (e) {
      debugPrint("MQTT ERROR: $e");
      client.disconnect();
    }
  }

  void onConnected() {
    isConnected = true;
    notifyListeners();
    debugPrint("MQTT CONNECTED");

    client.subscribe("home/sensors/data", MqttQos.atLeastOnce);
    client.subscribe("home/alert", MqttQos.atLeastOnce);

    client.updates!
        .listen((List<MqttReceivedMessage<MqttMessage?>> events) {
      final recMess = events[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      final topic = events[0].topic;

      if (topic == "home/sensors/data") {
        final data = jsonDecode(payload);

        double newTemp = (data["temp"] ?? 0).toDouble();
        double newHum = (data["hum"] ?? 0).toDouble();
        int newGas = data["gas"] ?? 0;
        int newSoil = data["soil"] ?? 0;
        int newRain = data["rain"] ?? 0;
        int newMotion = data["pir"] ?? 0;

        if (newTemp > 30 && newTemp != temperature) {
          handleAlert("High Temperature Alert: $newTemp °C");
        }
        if (newGas > 100 && newGas != gas) {
          handleAlert("Gas Alert: $newGas ppm");
        }
        if (newSoil < 30 && newSoil != soil) {
          handleAlert("Low Soil Moisture: $newSoil%");
        }
        if (newRain == 1 && newRain != rain) {
          handleAlert("Rain detected");
        }
        if (newMotion == 1 && newMotion != motion) {
          handleAlert("Motion detected");
        }

        temperature = newTemp;
        humidity = newHum;
        gas = newGas;
        soil = newSoil;
        rain = newRain;
        motion = newMotion;

        notifyListeners();
      }

      if (topic == "home/alert") {
        handleAlert(payload);
      }
    });
  }

  void onDisconnected() {
    isConnected = false;
    notifyListeners();
  }

  void publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(
        topic, MqttQos.atLeastOnce, builder.payload!);
  }

  // ============================================================
  // 💡 LAMP - ON / OFF
  // ============================================================
  void turnLampOn() {
    lampOn = true;
    publish("home/control/lamp", "ON");
    notifyListeners();
  }

  void turnLampOff() {
    lampOn = false;
    publish("home/control/lamp", "OFF");
    notifyListeners();
  }

  // ✅ بنحتفظ بـ toggleLamp للأزرار في صفحة الكنترول
  void toggleLamp() {
    lampOn ? turnLampOff() : turnLampOn();
  }

  // ============================================================
  // 🚰 PUMP - ON / OFF
  // ============================================================
  void turnPumpOn() {
    pumpOn = true;
    publish("home/control/pump", "ON");
    notifyListeners();
  }

  void turnPumpOff() {
    pumpOn = false;
    publish("home/control/pump", "OFF");
    notifyListeners();
  }

  // ✅ بنحتفظ بـ togglePump للأزرار في صفحة الكنترول
  void togglePump() {
    pumpOn ? turnPumpOff() : turnPumpOn();
  }

  // ============================================================
  // 🪟 WINDOW - OPEN / CLOSE
  // ============================================================
  void openWindow() {
    windowOn = true;
    publish("home/control/window", "OPEN");
    notifyListeners();
  }

  void closeWindow() {
    windowOn = false;
    publish("home/control/window", "CLOSE");
    notifyListeners();
  }

  // ✅ بنحتفظ بـ toggleWindow للأزرار في صفحة الكنترول
  void toggleWindow() {
    windowOn ? closeWindow() : openWindow();
  }

  // ============================================================
  // 🚪 DOOR
  // ============================================================
  void openDoorWithPassword(String password) {
    const correctPassword = "123258";
    if (password == correctPassword) {
      doorOn = true;
      publish("home/control/door", "123258");
      notifyListeners();
      // الباب بيقفل تلقائي بعد 3 ثواني
      Future.delayed(const Duration(seconds: 3), () {
        doorOn = false;
        notifyListeners();
      });
    } else {
      doorOn = false;
      publish("home/control/door", "LOCK");
      notifyListeners();
    }
  }

  // ============================================================
  // ⚙️ MODE - AUTO / MANUAL
  // ============================================================
  void setAutoMode() {
    autoMode = true;
    publish("home/control/mode", "AUTO");
    notifyListeners();
  }

  void setManualMode() {
    autoMode = false;
    publish("home/control/mode", "MANUAL");
    notifyListeners();
  }

  // ============================================================
  // 🔔 ALERTS
  // ============================================================
  void handleAlert(String payload) {
    alerts.insert(0, {
      "message": payload,
      "time": DateFormat('HH:mm').format(DateTime.now()),
      "isAlert": true,
    });
    hasNewAlert = true;
    notifyListeners();
  }

  void clearAlerts() {
    alerts.clear();
    hasNewAlert = false;
    notifyListeners();
  }
}