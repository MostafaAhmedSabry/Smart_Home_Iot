import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mqtt_provider.dart';
import 'sensors_page.dart';

class ConnectionSetupPage extends StatefulWidget {
  const ConnectionSetupPage({super.key});

  @override
  State<ConnectionSetupPage> createState() => _ConnectionSetupPageState();
}

class _ConnectionSetupPageState extends State<ConnectionSetupPage> {
  final TextEditingController brokerController =
  TextEditingController(text: "broker.hivemq.com");
  final TextEditingController portController =
  TextEditingController(text: "1883");
  final TextEditingController clientIdController =
  TextEditingController(text: "flutter_client_1");
  bool isConnecting = false;

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        title: const Text("Add Connection",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,
          vertical: size.height * 0.02,
        ),
        child: Column(
          children: [
            buildField("Broker address", brokerController, size),
            buildField("Port", portController, size),
            buildField("Client ID", clientIdController, size),
            SizedBox(height: size.height * 0.04),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(size.width * 0.8, size.height * 0.06),
              ),
              onPressed: () async {
                setState(() => isConnecting = true);

                await mqtt.setupConnection(
                  brokerController.text,
                  int.parse(portController.text),
                  clientIdController.text,
                );

                setState(() => isConnecting = false);

                if (!mounted) return;

                if (mqtt.isConnected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Connected successfully!")),
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SensorsPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Connection failed!")),
                  );
                }
              },
              child: isConnecting
                  ? SizedBox(
                height: size.height * 0.03,
                width: size.height * 0.03,
                child: const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : Text(
                "CREATE",
                style: TextStyle(fontSize: size.width * 0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(String label, TextEditingController controller, Size size) {
    return Padding(
      padding: EdgeInsets.only(bottom: size.height * 0.02),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white, fontSize: size.width * 0.045),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70, fontSize: size.width * 0.04),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
      ),
    );
  }
}
