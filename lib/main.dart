import 'package:flutter/material.dart';
import 'package:freshbox_app/app/app.dart';
import 'core/di/injection.dart';
import 'features/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // agora é a primeira linha, de verdade

  await setupDependencies();

  runApp(const HortiFrutiApp());
}