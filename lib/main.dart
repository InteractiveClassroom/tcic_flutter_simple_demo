import 'package:flutter/material.dart';
import 'package:tcic_flutter_simple_demo/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TCIC Flutter Simple Demo',
      home: Home(),
    );
  }
}
