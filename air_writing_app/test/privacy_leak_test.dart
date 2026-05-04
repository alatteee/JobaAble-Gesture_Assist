import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_069/features/logbook/models/log_model.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

/// Tugas Pengayaan Modul 5/6
/// "The Privacy Leak Test" - memastikan log private
/// tidak bocor ke anggota tim lain.
void main() {
  test(
    'RBAC Security Check: Private logs should NOT be visible to teammates',
    () {
      // 1. Setup Data
      // User A punya 2 catatan: 1 Private, 1 Public.
      const userA = 'userA';
      const userB = 'userB'; // rekan satu tim userA
      const teamId = 'MEKTRA_KLP_01';

      final privateLog = LogModel(
        id: ObjectId(),
        title: 'Catatan Rahasia',
        description: 'Ini hanya boleh dibaca oleh pemilik.',
        date: DateTime.now(),
        category: 'Pribadi',
        authorId: userA,
        teamId: teamId,
        isSynced: true,
        isPublic: false, // PRIVATE
      );

      final publicLog = LogModel(
        id: ObjectId(),
        title: 'Catatan Bersama',
        description: 'Boleh dibaca anggota tim.',
        date: DateTime.now(),
        category: 'Pekerjaan',
        authorId: userA,
        teamId: teamId,
        isSynced: true,
        isPublic: true, // PUBLIC
      );

      final allLogs = [privateLog, publicLog];

      // 2. Action
      // Simulasi fetchLogs() untuk User B (teammate):
      // aturan yang dipakai sama persis dengan di log_view.dart
      final visibleForUserB = allLogs.where((log) {
        return log.authorId == userB || log.isPublic == true;
      }).toList();

      // 3. Assert
      // User B hanya boleh melihat 1 log (yang Public).
      expect(visibleForUserB.length, 1,
          reason:
              'Teammate seharusnya hanya melihat 1 catatan (yang Public).');
      expect(visibleForUserB.single.isPublic, isTrue,
          reason: 'Log yang terlihat harus berstatus Public.');

      final containsPrivate = visibleForUserB.any((log) => !log.isPublic);
      expect(containsPrivate, isFalse,
          reason: 'Log Private tidak boleh bocor ke anggota tim.');
    },
  );
}
