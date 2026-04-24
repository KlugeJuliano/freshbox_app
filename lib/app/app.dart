import 'package:flutter/material.dart';
import 'package:freshbox_app/features/home/home_page.dart';

class HortifrutiApp extends StatelessWidget {
  const HortifrutiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hortifruti',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomePage(),
    );
  }
}
