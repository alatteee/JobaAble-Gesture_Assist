import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_069/features/logbook/models/log_model.dart';
import 'package:logbook_app_069/helpers/log_helper.dart';
import 'package:logbook_app_069/services/mongo_service.dart';
import 'package:mongo_dart/mongo_dart.dart';

void main() {
  const String sourceFile = 'crud_audit_test.dart';

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  test('Audit trail CRUD: insert/update/delete tercatat di file logs', () async {
    final mongoService = MongoService();

    // Pakai ObjectId 
    final ObjectId id = ObjectId();
    final String title = 'AUDIT_TEST_${DateTime.now().millisecondsSinceEpoch}';

    final log = LogModel(
      id: id,
      title: title,
      description: 'created by crud_audit_test',
      date: DateTime.now(),
      category: 'Pekerjaan',
    );

    await LogHelper.writeLog('--- START CRUD AUDIT TEST ---', source: sourceFile);

    try {
      await mongoService.connect();

      await mongoService.insertLog(log);

      final updated = LogModel(
        id: id,
        title: '${title}_UPDATED',
        description: 'updated by crud_audit_test',
        date: DateTime.now(),
        category: 'Urgent',
      );
      await mongoService.updateLog(updated);

      await mongoService.deleteLog(id);

      // Kalau sampai sini tidak throw, berarti CRUD sukses.
      expect(true, isTrue);

      await LogHelper.writeLog(
        'SUCCESS: CRUD audit test selesai',
        source: sourceFile,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        'ERROR: CRUD audit test gagal - $e',
        source: sourceFile,
        level: 1,
      );
      fail('CRUD audit test gagal: $e');
    } finally {
      await mongoService.close();
      await LogHelper.writeLog('--- END CRUD AUDIT TEST ---', source: sourceFile);
    }
  });
}
