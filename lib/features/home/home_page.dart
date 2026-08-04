import 'package:flutter/material.dart';

class HortiFrutiApp extends StatelessWidget {
  const HortiFrutiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Horti Fruti',
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horti Fruti'),
      ),
      body: const Center(
        child: Text('Welcome to Horti Fruti!'),
      ),
    );
  }
}
