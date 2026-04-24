import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshbox_app/core/network/dio_client.dart';
import 'package:freshbox_app/features/home/home_page.dart';
import 'package:freshbox_app/features/store/data/store_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/storage/local_storage.dart';

Future<void> main() async {
  final dioClient = DioClient(Dio());
final storeRepository = StoreRepository(dioClient);

try {
  final store = await storeRepository.getStore();
  print(store);
} catch (e) {
  print(e);
}
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa SharedPreferences antes do runApp para uso síncrono no Riverpod
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const HortiFrutiApp(),
    ),
  );
}
