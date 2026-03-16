import 'package:flutter/material.dart';

import 'leave_request_example_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DateTime Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1677FF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F4F7),
        useMaterial3: true,
      ),
      home: const LeaveRequestExamplePage(),
    );
  }
}
