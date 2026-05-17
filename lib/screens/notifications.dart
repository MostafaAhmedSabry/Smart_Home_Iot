import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mqtt_provider.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Widget item(String title, String time, bool alert, Size size) {
    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.015),
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xff1E293B),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            alert ? Icons.warning : Icons.check_circle,
            color: alert ? Colors.red : Colors.green,
            size: size.width * 0.07,
          ),
          SizedBox(width: size.width * 0.03),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: size.width * 0.045,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.white54,
              fontSize: size.width * 0.04,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<MqttProvider>(
            builder: (context, mqtt, child) {
              return mqtt.alerts.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear_all, color: Colors.white),
                onPressed: () {
                  mqtt.clearAlerts();
                },
              )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<MqttProvider>(
        builder: (context, mqtt, child) {
          if (!mqtt.isConnected) {
            return Center(
              child: Text(
                "No connection to MQTT broker",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: size.width * 0.045,
                ),
              ),
            );
          }

          if (mqtt.alerts.isEmpty) {
            return Center(
              child: Text(
                "No notifications",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: size.width * 0.045,
                ),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.all(size.width * 0.04),
            child: ListView.builder(
              itemCount: mqtt.alerts.length,
              itemBuilder: (context, index) {
                final alert = mqtt.alerts[index];
                return item(
                  alert["message"],
                  alert["time"],
                  alert["isAlert"],
                  size,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
