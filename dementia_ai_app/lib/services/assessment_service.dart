import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';
import 'session.dart';
import 'dart:io';

class AssessmentService {
  static Future<Map<String, dynamic>?> submitFullAssessment(
      String shownWords,
      String recalledWords,
      double timeTaken,
      String audioPath,
      double logicScore) async {
    final token = await Session.getToken();

    final file = File(audioPath);
    print("uploading audio size: ${file.lengthSync()}");
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("${Api.baseUrl}/full-assessment"),
    );

    request.headers["Authorization"] = "Bearer $token";

    // text fields
    request.fields["shown_words"] = shownWords;
    request.fields["recalled_words"] = recalledWords;
    request.fields["time_taken"] = timeTaken.toString();
    request.fields["logic_score"] = logicScore.toString();

    request.files.add(
      http.MultipartFile(
        'file',
        file.readAsBytes().asStream(),
        file.lengthSync(),
        filename: audioPath.split('/').last,
      ),
    );

    var response = await request.send();
    var resBody = await response.stream.bytesToString();

    print(response.statusCode);
    print(resBody);

    if (response.statusCode == 200) {
      return jsonDecode(resBody);
    }

    return null;
  }
}
