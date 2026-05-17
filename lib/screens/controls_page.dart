import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mqtt_provider.dart';

class ControlsPage extends StatelessWidget {
  const ControlsPage({super.key});

  Widget controlCard(
      String title,
      IconData icon,
      bool value,
      Function(bool) onChanged,
      Size size,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.02),
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xff1E293B),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: size.width * 0.08),
          SizedBox(width: size.width * 0.04),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: size.width * 0.045,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: Colors.green),
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
        title: const Text("Controls", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: mqtt.isConnected
          ? Padding(
        padding: EdgeInsets.all(size.width * 0.04),
        child: SingleChildScrollView(   // ✅ إضافة Scroll
          child: Column(
            children: [
              controlCard("System Mode", Icons.settings, mqtt.autoMode, (v) {
                mqtt.autoMode = v;
                mqtt.publish("home/control/mode", v ? "AUTO" : "MANUAL");
                mqtt.notifyListeners();
              }, size),

              controlCard("Window", Icons.window, mqtt.windowOn, (v) {
                mqtt.windowOn = v;
                mqtt.publish("home/control/window", v ? "CLOSE" : "OPEN");
                mqtt.notifyListeners();
              }, size),

              controlCard("Pump", Icons.water, mqtt.pumpOn, (v) {
                mqtt.togglePump();
              }, size),

              controlCard("Light", Icons.lightbulb, mqtt.lampOn, (v) {
                mqtt.toggleLamp();
              }, size),

              controlCard("Door", Icons.lock, mqtt.doorOn, (v) {
                showDialog(
                  context: context,
                  builder: (_) {
                    TextEditingController passController = TextEditingController();
                    return AlertDialog(
                      backgroundColor: const Color(0xff1E293B),
                      title: const Text(
                        "Door Password",
                        style: TextStyle(color: Colors.white),
                      ),
                      content: TextField(
                        controller: passController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Enter Password",
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            mqtt.openDoorWithPassword(passController.text);
                            Navigator.pop(context);
                          },
                          child: const Text("OPEN", style: TextStyle(color: Colors.blue)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("CANCEL", style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    );
                  },
                );
              }, size),
            ],
          ),
        ),
      )
          : Center(
        child: Text(
          "Please connect to MQTT broker first",
          style: TextStyle(color: Colors.white70, fontSize: size.width * 0.045),
        ),
      ),
    );
  }
}
