import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  // ID untuk Hive (disimpan sebagai String hex)
  @HiveField(0)
  final String? idHex;

  ObjectId? get id =>
      idHex != null && idHex!.isNotEmpty ? ObjectId.fromHexString(idHex!) : null;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  // Simpan tanggal sebagai DateTime 
  @HiveField(3)
  final DateTime date;

  // Identitas penulis dan tim untuk kolaborasi
  @HiveField(4)
  final String authorId;

  @HiveField(5)
  final String teamId;

  // Kategori logbook (Pribadi/Publik, dsb.)
  @HiveField(6)
  final String category;

  // Status sinkronisasi untuk UI
  @HiveField(7)
  final bool isSynced;

  // Status visibilitas: default PRIVATE (false)
  // Jika true, catatan bisa dilihat anggota tim lain.
  @HiveField(8)
  final bool isPublic;

  LogModel({
    ObjectId? id,
    required this.title,
    required this.description,
    required this.date,
    this.category = 'Pribadi',
    this.authorId = 'unknown_user',
    this.teamId = 'no_team',
    this.isSynced = false,
    this.isPublic = false,
  }) : idHex = id?.toHexString();

  // [CONVERT] Untuk MongoDB: memasukkan data ke "kardus" (BSON/Map)
  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(),
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'category': category,
      'authorId': authorId,
      'teamId': teamId,
      'isPublic': isPublic,
      // isSynced tidak perlu disimpan di MongoDB
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    final dynamic rawDate = map['date'];
    DateTime parsedDate;
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final objId = map['_id'] as ObjectId?;

    return LogModel(
      id: objId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: parsedDate,
      category: map['category'] ?? 'Pribadi',
      authorId: map['authorId'] ?? 'unknown_user',
      teamId: map['teamId'] ?? 'no_team',
      isPublic: (map['isPublic'] as bool?) ?? false,
      isSynced: true, // Data dari cloud selalu dianggap sudah sinkron
    );
  }

  // Salin objek dengan beberapa perubahan
  LogModel copyWith({
    ObjectId? id,
    String? title,
    String? description,
    DateTime? date,
    String? category,
    String? authorId,
    String? teamId,
    bool? isSynced,
    bool? isPublic,
  }) {
    return LogModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      category: category ?? this.category,
      authorId: authorId ?? this.authorId,
      teamId: teamId ?? this.teamId,
      isSynced: isSynced ?? this.isSynced,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  // =========================
  // Mapping untuk penyimpanan lokal (SharedPreferences / JSON)
  // =========================

  Map<String, dynamic> toLocalMap() {
    return {
      'id': idHex,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'category': category,
      'authorId': authorId,
      'teamId': teamId,
      'isSynced': isSynced,
      'isPublic': isPublic,
    };
  }

  factory LogModel.fromLocalMap(Map<String, dynamic> map) {
    final String? idString = map['id'] as String?;
    final dynamic rawDate = map['date'];
    DateTime parsedDate;
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return LogModel(
      id: (idString != null && idString.isNotEmpty)
          ? ObjectId.fromHexString(idString)
          : null,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: parsedDate,
      category: map['category'] ?? 'Pribadi',
      authorId: map['authorId'] ?? 'unknown_user',
      teamId: map['teamId'] ?? 'no_team',
      isPublic: (map['isPublic'] as bool?) ?? false,
      isSynced: map['isSynced'] ?? false,
    );
  }
}
