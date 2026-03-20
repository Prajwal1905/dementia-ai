import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

import '../services/api.dart';
import '../services/session.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {

  List data = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    final token = await Session.getToken();

    final res = await http.get(
      Uri.parse("${Api.baseUrl}/history"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      setState(() {
        data = jsonDecode(res.body);
        loading = false;
      });
    }
  }

  List<FlSpot> getSpots() {
    return List.generate(data.length, (i) {
      return FlSpot(i.toDouble(), data[i]["memory_score"].toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cognitive History")),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
              ? const Center(child: Text("No history yet"))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [

                      const Text(
                        "Memory Score Trend",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        height: 250,
                        child: LineChart(
                          LineChartData(
                            titlesData: FlTitlesData(show: true),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: getSpots(),
                                isCurved: true,
                                barWidth: 4,
                                dotData: FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (_, i) {
                            final item = data[i];

                            return Card(
                              child: ListTile(
                                title: Text("Score: ${item["memory_score"]}"),
                                subtitle: Text(
                                    "Risk: ${item["risk_level"]}\nDecline: ${item["decline_rate"]}"),
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
    );
  }
}