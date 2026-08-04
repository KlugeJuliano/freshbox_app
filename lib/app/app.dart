import 'package:flutter/material.dart';
import '../core/di/injection.dart';
import 'package:go_router/go_router.dart';


class HortifrutiApp extends StatelessWidget {
  const HortifrutiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hortifruti',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      routerConfig: getIt<GoRouter>(),
    );
  }
}