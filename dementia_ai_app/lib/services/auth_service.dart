import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

class AuthService {
  static Future<String?> login(String email, String password) async {
    final res = await http.post(
      Uri.parse("${Api.baseUrl}/auth/login"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
      encoding: Encoding.getByName("utf-8"),
    );

    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data["token"];
    }
    return null;
  }

  static Future<bool> register(
      String name, String email, String password) async {
    final res = await http.post(
      Uri.parse("${Api.baseUrl}/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    return res.statusCode == 200;
  }
}
