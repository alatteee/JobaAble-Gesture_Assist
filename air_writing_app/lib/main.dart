// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:logbook_app_069/features/logbook/models/log_model.dart';
import 'package:logbook_app_069/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_069/helpers/log_helper.dart';
import 'package:logbook_app_069/services/mongo_service.dart';
import 'package:logbook_app_069/services/preferences_service.dart';

Future<void> _bootstrapBackground() async {
  try {
    // Init ini tidak boleh menahan rendering UI awal.
    await dotenv.load(fileName: '.env');

    Intl.defaultLocale = 'id_ID';
    await initializeDateFormatting('id_ID', null);

    // Koneksi cloud dijalankan setelah app sudah tampil.
    await MongoService().connect();
    await LogHelper.writeLog(
      'Berhasil terhubung ke MongoDB',
      source: 'main.dart',
      level: 2,
    );
  } catch (e) {
    await LogHelper.writeLog(
      'Bootstrap background gagal (app tetap jalan offline): $e',
      source: 'main.dart',
      level: 1,
    );
  }
}

Future<void> main() async {
  // Wajib untuk operasi async sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Inisialisasi Hive harus selalu berhasil agar offline mode tetap jalan.
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(LogModelAdapter());
  }
  
  // Coba buka box, jika error berarti data lama tidak kompatibel → hapus dan buat baru
  try {
    if (!Hive.isBoxOpen('offline_logs')) {
      await Hive.openBox<LogModel>('offline_logs');
    }
  } catch (e) {
    // Jika error saat membaca (misal: field lama tidak match), hapus box lama
    try {
      await Hive.deleteBoxFromDisk('offline_logs');
      await Hive.openBox<LogModel>('offline_logs');
    } catch (deleteError) {
      // Fallback: lanjut tanpa Hive kalau truly stuck
      print('Hive initialization failed: $deleteError');
    }
  }

  // 2) Inisialisasi SharedPreferences untuk menyimpan user preferences
  await PreferencesService.initialize();

  runApp(const MyApp());

  // Jangan await: biarkan UI muncul dulu, lalu bootstrap cloud di belakang.
  _bootstrapBackground();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogBook App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const OnboardingView(),
    );
  }
}
