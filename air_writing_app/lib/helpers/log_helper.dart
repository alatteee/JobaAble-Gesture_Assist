import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart'; 

class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = "Unknown", 
    int level = 2,
  }) async {
    // 1. Filter Konfigurasi (ENV)
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    final String muteList = dotenv.env['LOG_MUTE'] ?? '';

    if (level > configLevel) return;
    if (_isMuted(source, muteList)) return;

    try {
      final now = DateTime.now();
      final label = _getLabel(level);

      // 2. Audit Trail ke File (selalu dicatat sesuai LOG_LEVEL)
      await _appendToDailyFile(
        now: now,
        label: label,
        source: source,
        message: message,
      );

      // 3. Output ke Console HANYA saat LOG_LEVEL=3 
      if (configLevel == 3) {
        final timestamp = DateFormat('HH:mm:ss').format(now);
        final color = _getColor(level);

        // VS Code Debug Console
        dev.log(message, name: source, time: now, level: level * 100);

        // Terminal
        // Format: [14:30:05] [INFO] [log_view.dart] -> Database Terhubung
        print('$color[$timestamp][$label][$source] -> $message\x1B[0m');
      }
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  static bool _isMuted(String source, String muteList) {
    if (muteList.trim().isEmpty) return false;
    final mutedSources = muteList
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    return mutedSources.contains(source.trim());
  }

  static Future<void> _appendToDailyFile({
    required DateTime now,
    required String label,
    required String source,
    required String message,
  }) async {
    final datePart = DateFormat('dd-MM-yyyy').format(now);
    final timePart = DateFormat('HH:mm:ss').format(now);
    final fileName = '$datePart.log';
    final dir = Directory('logs');

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    final line = '[$datePart $timePart][$label][$source] -> $message\n';
    await file.writeAsString(line, mode: FileMode.append, flush: true);
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; // Merah
      case 2:
        return '\x1B[32m'; // Hijau
      case 3:
        return '\x1B[34m'; // Biru
      default:
        return '\x1B[0m';
    }
  }
}
