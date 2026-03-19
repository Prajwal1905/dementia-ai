import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/assessment_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

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

  String resultText = "";
  Map<String, dynamic>? finalResult;
  FlutterSoundRecorder? recorder;
  bool isRecording = false;
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
      resultText = "";
      finalResult = null;
    });

    startTime = DateTime.now();

    Future.delayed(const Duration(seconds: 5), () {
      setState(() => wordsVisible = false);
    });
  }

  // ---------- SUBMIT FULL ASSESSMENT ----------
  Future<void> submitTest() async {
    if (audioPath == null) {
      setState(() {
        resultText = "Please record audio first 🎤";
      });
      return;
    }

    final endTime = DateTime.now();
    final timeTaken = endTime.difference(startTime!).inSeconds;

    final response = await AssessmentService.submitFullAssessment(
      shownWords.join(","),
      recalledController.text,
      timeTaken.toDouble(),
      audioPath!, // ✅ REAL AUDIO
    );

    if (response != null) {
      final result = response["result"];

      setState(() {
        finalResult = result;

        resultText = """
Memory Score: ${result["memory_score"]}

Risk: ${result["risk"]}

Confidence: ${result["confidence"]}%

AI Insight:
${result["explanation"]}
""";
      });
    } else {
      setState(() {
        resultText = "Assessment failed ❌";
      });
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
                    isRecording ? "Stop Recording 🎤" : "Start Recording 🎤"),
              ),
              ElevatedButton(
                onPressed: submitTest,
                child: const Text("Submit Full Assessment"),
              ),

              const SizedBox(height: 20),

              // ---------- RESULT UI ----------
              if (resultText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "🧠 Cognitive Result",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(resultText),
                      const SizedBox(height: 10),
                      if (finalResult != null)
                        Text(
                          finalResult!["risk"],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: getRiskColor(finalResult!["risk"]),
                          ),
                        ),
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
