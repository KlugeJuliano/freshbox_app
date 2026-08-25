import 'package:flutter/material.dart';
import 'package:freshbox_app/app/app.dart';
import 'core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupDependencies();

  runApp(const HortifrutiApp());
}
