import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/passage.dart';
import '../models/review_schedule.dart';
import '../models/vocabulary.dart';

/// Quản lý database SQLite cục bộ (local storage).
///
/// Chịu trách nhiệm lưu:
/// - Bài đọc (kể cả bài lấy từ API, cache lại để đọc offline)
/// - Tiến trình ôn tập SRS của từng bài (theo user)
/// - Từ điển mini (tra nghĩa khi bấm vào một từ)
///
/// Dùng Singleton: toàn app chỉ có một kết nối database duy nhất, lấy qua
/// DatabaseService.instance.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _database;

  /// Lấy kết nối database, tự khởi tạo (tạo file + tạo bảng) nếu chưa có.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chinese_srs_app.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE passages (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            segmentsJson TEXT NOT NULL,
            source TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE review_schedules (
            passageId TEXT NOT NULL,
            userId TEXT NOT NULL,
            readCountToday INTEGER NOT NULL,
            lastReadDate TEXT,
            lastEaseRating TEXT,
            intervalDays INTEGER NOT NULL,
            nextReviewDate TEXT,
            status TEXT NOT NULL,
            PRIMARY KEY (passageId, userId)
          )
        ''');

        await db.execute('''
          CREATE TABLE vocabulary (
            hanzi TEXT PRIMARY KEY,
            pinyin TEXT NOT NULL,
            meaningVi TEXT,
            meaningEn TEXT
          )
        ''');
      },
    );
  }

  // ---------------------------------------------------------------------
  // Seed dữ liệu mẫu (chỉ chạy nếu database còn trống)
  // ---------------------------------------------------------------------

  /// Nạp bài đọc mẫu (sample_passages.json) và từ điển mini
  /// (mini_dictionary.json) từ assets vào database.
  ///
  /// Chỉ chạy nếu bảng "passages" ĐANG TRỐNG - tránh nạp trùng lặp mỗi lần
  /// mở app. Gọi hàm này một lần trong main.dart, trước khi runApp().
  Future<void> seedFromAssetsIfEmpty() async {
    final existingPassages = await getAllPassages();
    if (existingPassages.isNotEmpty) return;

    final passagesJson = await rootBundle.loadString(
      'assets/data/sample_passages.json',
    );
    final passagesList = jsonDecode(passagesJson) as List<dynamic>;
    for (final item in passagesList) {
      final passage = Passage.fromJson(item as Map<String, dynamic>);
      await insertPassage(passage);
    }

    final dictionaryJson = await rootBundle.loadString(
      'assets/data/mini_dictionary.json',
    );
    final dictionaryList = jsonDecode(dictionaryJson) as List<dynamic>;
    for (final item in dictionaryList) {
      final entry = VocabularyEntry.fromJson(item as Map<String, dynamic>);
      await upsertVocabulary(entry);
    }
  }

  // ---------------------------------------------------------------------
  // Passages
  // ---------------------------------------------------------------------

  Future<void> insertPassage(Passage passage) async {
    final db = await database;
    await db.insert(
      'passages',
      _passageToRow(passage),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Passage?> getPassageById(String id) async {
    final db = await database;
    final rows = await db.query('passages', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _rowToPassage(rows.first);
  }

  Future<List<Passage>> getAllPassages() async {
    final db = await database;
    final rows = await db.query('passages', orderBy: 'createdAt DESC');
    return rows.map(_rowToPassage).toList();
  }

  Map<String, Object?> _passageToRow(Passage passage) {
    return {
      'id': passage.id,
      'title': passage.title,
      'segmentsJson': jsonEncode(
        passage.segments.map((s) => s.toJson()).toList(),
      ),
      'source': passage.source == PassageSource.api ? 'api' : 'builtin',
      'createdAt': passage.createdAt.toIso8601String(),
    };
  }

  Passage _rowToPassage(Map<String, Object?> row) {
    final segmentsList = jsonDecode(row['segmentsJson'] as String) as List;
    return Passage(
      id: row['id'] as String,
      title: row['title'] as String,
      segments: segmentsList
          .map((s) => PassageSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
      source: row['source'] == 'api'
          ? PassageSource.api
          : PassageSource.builtin,
      createdAt: DateTime.parse(row['createdAt'] as String),
    );
  }

  // ---------------------------------------------------------------------
  // Review schedules (tiến trình SRS)
  // ---------------------------------------------------------------------

  Future<void> upsertReviewSchedule(ReviewSchedule schedule) async {
    final db = await database;
    await db.insert(
      'review_schedules',
      schedule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ReviewSchedule?> getReviewSchedule(
    String passageId,
    String userId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'review_schedules',
      where: 'passageId = ? AND userId = ?',
      whereArgs: [passageId, userId],
    );
    if (rows.isEmpty) return null;
    return ReviewSchedule.fromMap(rows.first);
  }

  Future<List<ReviewSchedule>> getAllReviewSchedules(String userId) async {
    final db = await database;
    final rows = await db.query(
      'review_schedules',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return rows.map(ReviewSchedule.fromMap).toList();
  }

  // ---------------------------------------------------------------------
  // Vocabulary (từ điển mini)
  // ---------------------------------------------------------------------

  Future<void> upsertVocabulary(VocabularyEntry entry) async {
    final db = await database;
    await db.insert(
      'vocabulary',
      entry.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Tra nghĩa một chữ/từ. Trả về null nếu từ điển mini chưa có -
  /// khi đó DictionaryService sẽ rơi về phương án dự phòng (CC-CEDICT + pinyin).
  Future<VocabularyEntry?> lookupVocabulary(String hanzi) async {
    final db = await database;
    final rows = await db.query(
      'vocabulary',
      where: 'hanzi = ?',
      whereArgs: [hanzi],
    );
    if (rows.isEmpty) return null;
    return VocabularyEntry.fromJson(rows.first);
  }
}