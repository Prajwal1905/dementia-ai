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
      List temp = jsonDecode(res.body);

      temp.sort((a, b) =>
          DateTime.parse(a["date"]).compareTo(DateTime.parse(b["date"])));

      setState(() {
        data = temp;
        loading = false;
      });
    }
  }

  List<FlSpot> getSpots() {
    return List.generate(data.length, (i) {
      return FlSpot(
        i.toDouble(),
        (data[i]["cognitive_score"] ?? 0).toDouble(),
      );
    });
  }

  Color getRiskColor(String risk) {
    if (risk.contains("High")) return Colors.red;
    if (risk.contains("Mild")) return Colors.orange;
    return Colors.green;
  }

  String getTrend(double decline) {
    if (decline > 10) return "↓ Declining";
    if (decline > 5) return "⚠ Slight Decline";
    return "↑ Stable";
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [

                      const Text(
                        "Cognitive Score Trend",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 10),

                      
                      Text(
                        "Latest Score: ${data.last["cognitive_score"]}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 20),

                      
                      SizedBox(
                        height: 250,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: 100,

                            gridData: FlGridData(show: true),

                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.grey),
                            ),

                            
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 20,
                                  reservedSize: 30,
                                ),
                              ),

                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 1 != 0) return const SizedBox();

                                    int index = value.toInt();
                                    if (index >= data.length) {
                                      return const SizedBox();
                                    }

                                    return Text("T${index + 1}");
                                  },
                                ),
                              ),
                            ),

                            
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (spots) {
                                  return spots.map((spot) {
                                    return LineTooltipItem(
                                      "Score: ${spot.y.toStringAsFixed(1)}",
                                      const TextStyle(color: Colors.white),
                                    );
                                  }).toList();
                                },
                              ),
                            ),

                            lineBarsData: [
                              LineChartBarData(
                                spots: getSpots(),
                                isCurved: true,
                                curveSmoothness: 0.3,
                                barWidth: 3,
                                color: Colors.blue,

                                dotData: FlDotData(show: true),

                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.blue.withOpacity(0.15),
                                ),
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

                            final score =
                                (item["cognitive_score"] ?? 0).toDouble();
                            final decline =
                                (item["decline_rate"] ?? 0).toDouble();

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(
                                  " Score: ${score.toStringAsFixed(1)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "Decline: ${decline.toStringAsFixed(2)}"),
                                    Text(
                                      getTrend(decline),
                                      style: TextStyle(
                                        color: decline > 10
                                            ? Colors.red
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  item["risk_level"],
                                  style: TextStyle(
                                    color:
                                        getRiskColor(item["risk_level"] ?? ""),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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