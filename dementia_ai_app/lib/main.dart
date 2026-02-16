import 'package:flutter/material.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: TestPage());
  }
}

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("API Test")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final token = await AuthService.login(
              "test@gmail.com",
              "123456",
            );

            print("TOKEN: $token");
          },
          child: const Text("Test Login"),
        ),
      ),
    );
  }
}
