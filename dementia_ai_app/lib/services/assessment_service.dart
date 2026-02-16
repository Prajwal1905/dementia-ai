import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'session.dart';

class AssessmentService {
  static Future<String?> submitMemory(
      String shownWords, String recalledWords, double timeTaken) async {
    final token = await Session.getToken();

    final res = await http.post(
      Uri.parse("${Api.baseUrl}/memory-test"),
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "shown_words": shownWords.split(","),
        "recalled_words": recalledWords.split(RegExp(r"[ ,]+")),
        "time_taken": timeTaken
      }),
    );

    print(res.statusCode);
    print(res.body);

    if (res.statusCode == 200) {
      return res.body;
    }

    return null;
  }
}
