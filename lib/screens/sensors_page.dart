import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ChatPage.dart';
import 'controls_page.dart';
import 'mqtt_provider.dart';
import 'notifications.dart';
import 'big_data_page.dart';

class SensorsPage extends StatelessWidget {
  const SensorsPage({super.key});

  Widget sensorCard(String title, String value, IconData icon, Color color, bool alert, Size size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: alert
              ? [Colors.red, Colors.orange]
              : [const Color(0xff1E293B), const Color(0xff0F172A)],
        ),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 10),
        ],
      ),
      padding: EdgeInsets.all(size.width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: size.width * 0.09),
          const Spacer(),
          Text(title,
              style: TextStyle(color: Colors.white70, fontSize: size.width * 0.04)),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: size.width * 0.045,
                  fontWeight: FontWeight.bold)),
          Text(alert ? "Alert" : "Normal",
              style: TextStyle(
                  fontSize: size.width * 0.04,
                  color: alert ? Colors.redAccent : Colors.greenAccent)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xff0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text("Smart Home", style: TextStyle(color: Colors.white)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  );
                  mqtt.hasNewAlert = false;
                  mqtt.notifyListeners();
                },
              ),
              if (mqtt.hasNewAlert)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: mqtt.isConnected
          ? Padding(
        padding: EdgeInsets.all(size.width * 0.04),
        child: GridView.count(
          crossAxisCount: size.width > 600 ? 3 : 2,
          crossAxisSpacing: size.width * 0.04,
          mainAxisSpacing: size.width * 0.04,
          children: [
            sensorCard("Temperature", "${mqtt.temperature.toStringAsFixed(1)} °C",
                Icons.thermostat, Colors.orange, mqtt.temperature > 28, size),
            sensorCard("Gas", "${mqtt.gas} ppm", Icons.local_fire_department,
                Colors.red, mqtt.gas > 200, size),
            sensorCard("Rain", mqtt.rain == 1 ? "No Rain" : "Raining",
                Icons.cloud, Colors.blue, mqtt.rain == 0, size),
            sensorCard("Soil", "${mqtt.soil}%", Icons.grass, Colors.green,
                mqtt.soil > 30, size),
            sensorCard("Motion", mqtt.motion == 1 ? "Detected" : "No Motion",
                Icons.directions_walk, Colors.purple, mqtt.motion == 1, size),
          ],
        ),
      )
          : const Center(
        child: Text("Not connected to MQTT broker",
            style: TextStyle(color: Colors.white70)),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "chat",
            backgroundColor: Colors.purple,
            child: const Icon(Icons.chat_bubble),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "controls",
            backgroundColor: Colors.blue,
            child: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ControlsPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "bigdata",
            backgroundColor: Colors.green,
            child: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BigDataPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
