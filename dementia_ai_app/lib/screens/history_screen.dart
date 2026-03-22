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
  String filter = "all";

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

      // Sort latest first
      temp.sort((a, b) =>
          DateTime.parse(b["date"]).compareTo(DateTime.parse(a["date"])));

      setState(() {
        data = temp;
        loading = false;
      });
    }
  }

  // ✅ FILTER LOGIC
  List getFilteredData() {
    if (filter == "all") return data;

    DateTime now = DateTime.now();

    return data.where((item) {
      DateTime date = DateTime.parse(item["date"]).toLocal();

      if (filter == "week") {
        return now.isBefore(date.add(const Duration(days: 7)));
      } else if (filter == "month") {
        return now.isBefore(date.add(const Duration(days: 30)));
      }

      return true;
    }).toList();
  }

  // ✅ GRAPH POINTS
  List<FlSpot> getSpots(List filtered) {
    return List.generate(filtered.length, (i) {
      return FlSpot(
        i.toDouble(),
        (filtered[i]["cognitive_score"] ?? 0).toDouble(),
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

  Widget filterButton(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              filter == value.toLowerCase() ? Colors.blue : Colors.grey,
        ),
        onPressed: () {
          setState(() {
            filter = value.toLowerCase();
          });
        },
        child: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = getFilteredData();

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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          filterButton("All"),
                          filterButton("Week"),
                          filterButton("Month"),
                        ],
                      ),

                      const SizedBox(height: 10),

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
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 1 != 0) return const SizedBox();

                                    int index = value.toInt();
                                    if (index >= filtered.length) {
                                      return const SizedBox();
                                    }

                                    final date =
                                        DateTime.parse(filtered[index]["date"])
                                            .toLocal();

                                    return Text(
                                      "${date.day}/${date.month}",
                                      style: const TextStyle(fontSize: 10),
                                    );
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
                                spots: getSpots(filtered),
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

                      const SizedBox(height: 15),

                      //  Latest Analysis
                      if (filtered.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                " Latest Analysis",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Score + Risk
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Score: ${filtered.first["cognitive_score"]}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: getRiskColor(
                                              filtered.first["risk_level"])
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      filtered.first["risk_level"],
                                      style: TextStyle(
                                        color: getRiskColor(
                                            filtered.first["risk_level"]),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Decline
                              Text(
                                "Decline: ${filtered.first["decline_rate"]}",
                                style: const TextStyle(fontSize: 14),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                getTrend(
                                  (filtered.first["decline_rate"] ?? 0)
                                      .toDouble(),
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      (filtered.first["decline_rate"] ?? 0) > 10
                                          ? Colors.red
                                          : Colors.green,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Trend highlight
                              if (filtered.first["trend"] != null)
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    filtered.first["trend"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),

                              if (filtered.first["change"] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    "Change: ${filtered.first["change"]}",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                            ],
                          ),
                        ),

                      // 🔮 Future Prediction
                      if (filtered.isNotEmpty &&
                          filtered.first["predicted_score"] != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "🔮 Future Prediction",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Expected Score: ${filtered.first["predicted_score"]}",
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                filtered.first["prediction_message"] ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                      const SizedBox(height: 15),

                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final item = filtered[i];

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
                                  "Score: ${score.toStringAsFixed(1)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                      ),
                    ],
                  ),
                ),
    );
  }
}
