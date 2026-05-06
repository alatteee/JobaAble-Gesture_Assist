import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:logbook_app_069/features/logbook/models/log_model.dart';
import 'package:logbook_app_069/helpers/log_helper.dart';

class MongoService {
  static final MongoService _instance = MongoService._internal();

  // Db & collection dibuat nullable agar bisa dicek statusnya
  Db? _db;
  DbCollection? _collection;

  final String _source = "mongo_service.dart";
  final bool _debug = dotenv.env['MONGO_DEBUG'] == '1' || dotenv.env['MONGO_DEBUG'] == 'true';

  String _maskUri(String uri) {
    try {
      // Mask credentials between scheme:// and @ if present
      final schemeSplit = uri.split('://');
      if (schemeSplit.length < 2) return uri;
      final afterScheme = schemeSplit.sublist(1).join('://');
      if (!afterScheme.contains('@')) return uri;
      final parts = afterScheme.split('@');
      return '${schemeSplit.first}://***@${parts.sublist(1).join('@')}';
    } catch (_) {
      return uri;
    }
  }

  factory MongoService() => _instance;
  MongoService._internal();

  /// Fungsi internal untuk memastikan koleksi siap digunakan (anti LateInitializationError)
  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected || _collection == null) {
      await LogHelper.writeLog(
        "INFO: Koleksi belum siap, mencoba rekoneksi...",
        source: _source,
        level: 3,
      );
      await connect();
    }
    if (_collection == null) {
      await LogHelper.writeLog(
        "ERROR: Koleksi tetap null setelah koneksi",
        source: _source,
        level: 1,
      );
      throw Exception('Collection not available');
    }
    return _collection!;
  }

  /// Inisialisasi koneksi ke MongoDB Atlas
  Future<void> connect() async {
    try {
      final rawUri = dotenv.env['MONGODB_URI'];
      if (rawUri == null || rawUri.isEmpty) {
        throw Exception("MONGODB_URI tidak ditemukan di .env");
      }

  
      final dbName = dotenv.env['MONGO_DB_NAME'] ?? 'air_writing_logbook';
      final collectionName = dotenv.env['MONGO_COLLECTION'] ?? 'writing_logs';
      // Build full DB URI based on rawUri and provided DB name.
      final uriParts = rawUri.split('?');
      final base = uriParts.first;
      final query = uriParts.length > 1 ? '?${uriParts.sublist(1).join('?')}' : '';

      final cleanBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
      final dbUri = "$cleanBase/$dbName$query";

      if (_debug) {
        await LogHelper.writeLog(
          "DEBUG: rawUri (masked): ${_maskUri(rawUri)}",
          source: _source,
          level: 2,
        );
        await LogHelper.writeLog(
          "DEBUG: built dbUri: $dbUri",
          source: _source,
          level: 2,
        );
      }

      _db = await Db.create(dbUri);

      // Timeout 15 detik
      await _db!.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
            "Koneksi Timeout. Cek IP Whitelist (0.0.0.0/0) atau Sinyal HP.",
          );
        },
      );

      _collection = _db!.collection(collectionName);

      await LogHelper.writeLog(
        "DEBUG: Using DB '$dbName' and Collection '$collectionName'",
        source: _source,
        level: 2,
      );

      await LogHelper.writeLog(
        "DATABASE: Terhubung & Koleksi Siap",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Gagal Koneksi - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// READ: Mengambil data dari Cloud sesuai teamId user aktif
  Future<List<LogModel>> getLogs(String teamId) async {
    try {
      final collection = await _getSafeCollection();

      await LogHelper.writeLog(
        "INFO: Fetching data for Team: $teamId",
        source: _source,
        level: 3,
      );

      final List<Map<String, dynamic>> data = await collection
          .find(where.eq('teamId', teamId))
          .toList();
      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Fetch Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// CREATE: Menambahkan data baru
  Future<void> insertLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      final payload = log.toMap();
      await LogHelper.writeLog(
        "DEBUG: insertLog called for '${log.title}' (teamId: ${log.teamId})",
        source: _source,
        level: 2,
      );
      if (_debug) {
        await LogHelper.writeLog(
          "DEBUG: payload: $payload",
          source: _source,
          level: 2,
        );
      }

      if (log.id == null) {
        final res = await collection.insertOne(payload);
        await LogHelper.writeLog(
          "DEBUG: insertOne result: $res",
          source: _source,
          level: 2,
        );
      } else {
        final res = await collection.replaceOne(
          where.id(log.id!),
          payload,
          upsert: true,
        );
        await LogHelper.writeLog(
          "DEBUG: replaceOne result: $res",
          source: _source,
          level: 2,
        );
      }

      await LogHelper.writeLog(
        "SUCCESS: Data '${log.title}' Saved to Cloud",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Insert Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// UPDATE: Memperbarui data berdasarkan ID
  Future<void> updateLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      if (log.id == null) {
        throw Exception("ID Log tidak ditemukan untuk update");
      }

      await collection.replaceOne(
        where.id(log.id!),
        log.toMap(),
        upsert: true,
      );

      await LogHelper.writeLog(
        "DATABASE: Update '${log.title}' Berhasil",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Update Gagal - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// DELETE: Menghapus dokumen berdasarkan ObjectId
  Future<void> deleteLog(ObjectId id) async {
    try {
      final collection = await _getSafeCollection();
      await collection.remove(where.id(id));

      await LogHelper.writeLog(
        "DATABASE: Hapus ID $id Berhasil",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Hapus Gagal - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      await LogHelper.writeLog(
        "DATABASE: Koneksi ditutup",
        source: _source,
        level: 2,
      );
    }
  }
}