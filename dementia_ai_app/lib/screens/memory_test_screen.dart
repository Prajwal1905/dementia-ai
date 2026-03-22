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
  // ---------------- MEMORY ----------------
  List<String> shownWords = [];
  final recalledController = TextEditingController();
  bool wordsVisible = true;
  DateTime? startTime;

  // ---------------- SPEECH ----------------
  FlutterSoundRecorder? recorder;
  bool isRecording = false;
  String? audioPath;

  // ---------------- LOGIC ----------------
  String logicQuestion = "";
  String logicQId = "";
  String logicSessionId = "";
  int logicCount = 0;
  final logicController = TextEditingController();
  bool logicLoading = false;

  // ---------------- GLOBAL ----------------
  int stage = 0; // 0=memory, 1=logic, 2=preview, 3=result
  double logicScore = 0;
  bool isLoading = false;
  Map<String, dynamic>? finalResult;

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

  // ---------------- MEMORY ----------------
  Future<void> fetchWords() async {
    final res = await http.get(Uri.parse("${Api.baseUrl}/memory/words"));
    final data = jsonDecode(res.body);

    setState(() {
      shownWords = List<String>.from(data["words"]);
      wordsVisible = true;
    });

    startTime = DateTime.now();

    Future.delayed(const Duration(seconds: 5), () {
      setState(() => wordsVisible = false);
    });
  }

  // ---------------- SPEECH ----------------
  Future<void> startRecording() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) return;

    final dir = await getTemporaryDirectory();
    audioPath = "${dir.path}/audio.aac";

    await recorder!.startRecorder(toFile: audioPath);
    setState(() => isRecording = true);
  }

  Future<void> stopRecording() async {
    await recorder!.stopRecorder();
    setState(() => isRecording = false);
  }

  // ---------------- LOGIC ----------------
  Future<void> startLogicSession() async {
    final res = await http.post(Uri.parse("${Api.baseUrl}/logic/start"));
    final data = jsonDecode(res.body);
    logicSessionId = data["session_id"];
    fetchLogicQuestion();
  }

  Future<void> fetchLogicQuestion() async {
    setState(() => logicLoading = true);

    final res = await http.get(Uri.parse(
        "${Api.baseUrl}/logic/session/question?session_id=$logicSessionId"));

    final data = jsonDecode(res.body);

    setState(() {
      logicQuestion = data["question"];
      logicQId = data["q_id"];
      logicLoading = false;
    });
  }

  Future<void> submitLogicAnswer() async {
    await http.post(Uri.parse(
        "${Api.baseUrl}/logic/session/answer?session_id=$logicSessionId&q_id=$logicQId&user_answer=${logicController.text}"));

    logicController.clear();
    logicCount++;

    if (logicCount >= 6) {
      final res = await http.get(Uri.parse(
          "${Api.baseUrl}/logic/session/result?session_id=$logicSessionId"));

      final data = jsonDecode(res.body);
      logicScore = (data["logic_score"] ?? 0).toDouble();

      setState(() => stage = 2); // preview stage
    } else {
      fetchLogicQuestion();
    }
  }

  // ---------------- FINAL SUBMIT ----------------
  Future<void> submitTest() async {
    if (audioPath == null) return;

    final timeTaken = DateTime.now().difference(startTime!).inSeconds;

    setState(() => isLoading = true);

    final response = await AssessmentService.submitFullAssessment(
      shownWords.join(","),
      recalledController.text.replaceAll(" ", ","),
      timeTaken.toDouble(),
      audioPath!,
      logicScore,
    );

    setState(() => isLoading = false);

    if (response != null) {
      setState(() {
        finalResult = response;
        stage = 3; 
      });
    }
  }

  Color getRiskColor(String risk) {
    if (risk.contains("High")) return Colors.red;
    if (risk.contains("Mild")) return Colors.orange;
    return Colors.green;
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cognitive Test")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [

              /// PROGRESS BAR
              LinearProgressIndicator(value: stage / 3),

              const SizedBox(height: 20),

              /// ---------------- MEMORY ----------------
              if (stage == 0) ...[
                const Text("Memorize words", style: TextStyle(fontSize: 20)),
                const SizedBox(height: 20),
                wordsVisible
                    ? Text(shownWords.join(" "),
                        style: const TextStyle(fontSize: 22))
                    : const Text("Enter recalled words"),
                const SizedBox(height: 20),
                TextField(controller: recalledController),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: isRecording ? stopRecording : startRecording,
                  child: Text(
                      isRecording ? "Stop Recording" : "Start Recording"),
                ),

                ElevatedButton(
                  onPressed: () {
                    if (audioPath == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Record speech first")));
                      return;
                    }
                    setState(() => stage = 1);
                    startLogicSession();
                  },
                  child: const Text("Next: Logic Test"),
                ),
              ],

              /// ---------------- LOGIC ----------------
              if (stage == 1) ...[
                logicLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          Text(logicQuestion,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 20),
                          TextField(controller: logicController),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: submitLogicAnswer,
                            child: const Text("Submit Answer"),
                          ),
                          Text("Question ${logicCount + 1}/6"),
                        ],
                      )
              ],

              /// ---------------- PREVIEW ----------------
              if (stage == 2)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text("Ready for Final Analysis",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("Memory Test"),
                          Icon(Icons.check, color: Colors.green),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("Speech Test"),
                          Icon(Icons.check, color: Colors.green),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("Logic Test"),
                          Icon(Icons.check, color: Colors.green),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Text("Logic Score: $logicScore"),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: submitTest,
                        child: const Text("Generate Final Report"),
                      ),
                    ],
                  ),
                ),

              /// ---------------- RESULT ----------------
              if (stage == 3 && finalResult != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Cognitive Health Report",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 20),

                      Text("Score: ${finalResult!["cognitive_score"]}"),
                      Text("Risk: ${finalResult!["risk"]}"),

                      const SizedBox(height: 10),

                      LinearProgressIndicator(
                        value: finalResult!["cognitive_score"] / 100,
                        color: getRiskColor(finalResult!["risk"]),
                      ),

                      const SizedBox(height: 20),

                      Text("Logic: $logicScore"),
                      Text("Memory: ${finalResult!["memory_score"]}"),
                      Text(
                          "Speech: ${finalResult!["speech_features"]["speech_score"]}"),

                      const SizedBox(height: 15),

                      Text(finalResult!["summary"]),

                      const SizedBox(height: 10),

                      ...List.generate(
                        finalResult!["insights"].length,
                        (i) =>
                            Text("• ${finalResult!["insights"][i]}"),
                      ),

                      const SizedBox(height: 10),

                      Text(finalResult!["recommendation"]),
                    ],
                  ),
                ),

              if (isLoading) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}