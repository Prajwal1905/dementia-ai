import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/assessment_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MemoryTestScreen extends StatefulWidget {
  const MemoryTestScreen({super.key});

  @override
  State<MemoryTestScreen> createState() => _MemoryTestScreenState();
}

class _MemoryTestScreenState extends State<MemoryTestScreen> {
  List<String> shownWords = [];
  final recalledController = TextEditingController();

  bool wordsVisible = true;
  DateTime? startTime;

  Map<String, dynamic>? finalResult;

  FlutterSoundRecorder? recorder;
  bool isRecording = false;
  bool isLoading = false; // ✅ NEW
  String? audioPath;

  @override
  void initState() {
    super.initState();
    recorder = FlutterSoundRecorder();
    initRecorder();
    fetchWords();
  }

  Future<void> initRecorder() async {
    await recorder!.openRecorder();
  }

  Future<void> startRecording() async {
    var status = await Permission.microphone.request();

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission denied ❌")),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    audioPath = "${dir.path}/audio.aac";

    await recorder!.startRecorder(toFile: audioPath);
    setState(() => isRecording = true);
  }

  Future<void> stopRecording() async {
    await recorder!.stopRecorder();
    setState(() => isRecording = false);
  }

  // ---------- FETCH WORDS ----------
  Future<void> fetchWords() async {
    final res = await http.get(
      Uri.parse("${Api.baseUrl}/memory/words"),
    );

    final data = jsonDecode(res.body);
    setState(() {
      shownWords = List<String>.from(data["words"]);
      wordsVisible = true;
      finalResult = null;
    });

    startTime = DateTime.now();

    Future.delayed(const Duration(seconds: 5), () {
      setState(() => wordsVisible = false);
    });
  }

  // ---------- SUBMIT ----------
  Future<void> submitTest() async {
    if (audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please record audio first 🎤")),
      );
      return;
    }

    final endTime = DateTime.now();
    final timeTaken = endTime.difference(startTime!).inSeconds;

    setState(() => isLoading = true);

    final response = await AssessmentService.submitFullAssessment(
      shownWords.join(","),
      recalledController.text.replaceAll(" ", ","),
      timeTaken.toDouble(),
      audioPath!,
    );

    setState(() => isLoading = false);

    if (response != null) {
      setState(() {
        finalResult = response;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Assessment failed ❌")),
      );
    }
  }

  // ---------- RISK COLOR ----------
  Color getRiskColor(String risk) {
    if (risk.contains("High")) return Colors.red;
    if (risk.contains("Mild")) return Colors.orange;
    return Colors.green;
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cognitive Test")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Memorize these words",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),

              const SizedBox(height: 20),

              if (wordsVisible)
                Text(
                  shownWords.join("   "),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                )
              else
                const Text(
                  "Now type what you remember",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),

              const SizedBox(height: 30),

              TextField(
                controller: recalledController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Enter words",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: isRecording ? stopRecording : startRecording,
                child: Text(
                    isRecording ? "Stop Recording " : "Start Recording "),
              ),

              ElevatedButton(
                onPressed: submitTest,
                child: const Text("Submit Full Assessment"),
              ),

              const SizedBox(height: 20),

              // ---------- LOADING ----------
              if (isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text("Analyzing... Please wait ⏳"),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ---------- RESULT ----------
              if (finalResult != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        " Cognitive Health Report",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 20),

                      // SCORE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Score: ${finalResult!["cognitive_score"]}",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            finalResult!["risk"],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: getRiskColor(finalResult!["risk"]),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      LinearProgressIndicator(
                        value: finalResult!["cognitive_score"] / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        color: getRiskColor(finalResult!["risk"]),
                      ),

                      const SizedBox(height: 20),

                      const Text("📌 Summary",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(finalResult!["summary"]),

                      const SizedBox(height: 15),

                      const Text("💡 AI Insights",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...List.generate(
                        finalResult!["insights"].length,
                        (i) => Text("• ${finalResult!["insights"][i]}"),
                      ),

                      const SizedBox(height: 15),

                      const Text(" Recommendation",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(finalResult!["recommendation"]),

                      const SizedBox(height: 20),

                      Text("Memory Score: ${finalResult!["memory_score"]}"),
                      Text("Confidence: ${finalResult!["confidence"]}%"),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  recalledController.clear();
                  fetchWords();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}