import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api.dart';

class MemoryTestScreen extends StatefulWidget {
  const MemoryTestScreen({super.key});

  @override
  State<MemoryTestScreen> createState() => _MemoryTestScreenState();
}

class _MemoryTestScreenState extends State<MemoryTestScreen> {

  List<String> words = [];
  bool showingWords = true;
  String result = "";
  final recallController = TextEditingController();
  late DateTime startTime;

  @override
  void initState() {
    super.initState();
    fetchWords();
  }

  // STEP 1 — Get random words
  Future<void> fetchWords() async {
    final res = await http.get(Uri.parse("${Api.baseUrl}/memory-words"));
    final data = jsonDecode(res.body);

    setState(() {
      words = List<String>.from(data["words"]);
      showingWords = true;
    });

    startTime = DateTime.now();

    // hide words after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        showingWords = false;
      });
    });
  }

  // STEP 2 — Submit recall
  Future<void> submitTest() async {

    final recalled = recallController.text.split(" ");

    final seconds = DateTime.now().difference(startTime).inSeconds;

    final res = await http.post(
      Uri.parse("${Api.baseUrl}/memory-test"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "shown_words": words,
        "recalled_words": recalled,
        "time_taken": seconds
      }),
    );

    final data = jsonDecode(res.body);

    setState(() {
      result = "Score: ${data["memory_score"]} / 100";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Memory Test")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            if (showingWords)
              Column(
                children: [
                  const Text("Memorize these words:", style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 20),
                  Text(words.join("   "),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text("They will disappear in 5 seconds...")
                ],
              )
            else
              Column(
                children: [
                  const Text("Type the words you remember:",
                      style: TextStyle(fontSize: 20)),
                  TextField(
                    controller: recallController,
                    decoration: const InputDecoration(
                        hintText: "example: apple chair blue"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: submitTest,
                      child: const Text("Submit")),
                  const SizedBox(height: 20),
                  Text(result, style: const TextStyle(fontSize: 22))
                ],
              )
          ],
        ),
      ),
    );
  }
}
