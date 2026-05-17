import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mqtt_provider.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';

class BigDataPage extends StatelessWidget {
  const BigDataPage({super.key});

  double mean(List<double> v) =>
      v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;

  double stdDev(List<double> v) {
    if (v.isEmpty) return 0;
    double m = mean(v);
    double sumSq = v.map((x) => pow(x - m, 2).toDouble()).fold(0.0, (a, b) => a + b);
    return sqrt(sumSq / v.length);
  }

  LineChartData buildChart(Map<String, List<double>> data, Map<String, Color> colors) {
    return LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: data.entries.map((e) {
        return LineChartBarData(
          spots: e.value.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value);
          }).toList(),
          isCurved: true,
          color: colors[e.key],
          barWidth: 3,
          belowBarData: BarAreaData(show: true, color: colors[e.key]!.withOpacity(0.15)),
          dotData: FlDotData(show: false),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttProvider>(context);
    final size = MediaQuery.of(context).size;

    Map<String, List<double>> sensors = {
      "Temperature": [mqtt.temperature, 28, 29, 31, 30],
      "Gas": [mqtt.gas.toDouble(), 80, 120, 90, 110],
      "Humidity": [mqtt.humidity.toDouble(), 40, 42, 38, 45],
      "Soil": [mqtt.soil.toDouble(), 25, 30, 28, 35],
    };

    Map<String, Color> colors = {
      "Temperature": Colors.orange,
      "Gas": Colors.redAccent,
      "Humidity": Colors.blueAccent,
      "Soil": Colors.greenAccent,
    };

    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xff0F172A),
        elevation: 0,
        title: Text("Big Data Analysis",
            style: TextStyle(color: Colors.white, fontSize: size.width * 0.05)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(size.width * 0.05),
        child: ListView(
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: Colors.cyan, size: 28),
                SizedBox(width: size.width * 0.02),
                Text("Data Flow",
                    style: TextStyle(
                        color: Colors.cyan,
                        fontSize: size.width * 0.06,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: size.height * 0.4,
                child: LineChart(buildChart(sensors, colors))),
            const SizedBox(height: 10),

            Wrap(
              spacing: size.width * 0.03,
              children: colors.entries.map((e) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 16, height: 16, color: e.value),
                    SizedBox(width: size.width * 0.01),
                    Text(e.key,
                        style: TextStyle(color: Colors.white70, fontSize: size.width * 0.04)),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 25),

            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blueAccent, size: 28),
                SizedBox(width: size.width * 0.02),
                Text("Descriptive Analysis",
                    style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: size.width * 0.06,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Card(
              color: Colors.white.withOpacity(0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: EdgeInsets.all(size.width * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sensors.entries.map((e) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${e.key} Mean: ${mean(e.value).toStringAsFixed(2)}",
                            style: TextStyle(color: Colors.white, fontSize: size.width * 0.04)),
                        Text("${e.key} StdDev: ${stdDev(e.value).toStringAsFixed(2)}",
                            style: TextStyle(color: Colors.white70, fontSize: size.width * 0.035)),
                        const SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
