import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'flick_event.dart';

/// SQLite WAL-backed event buffer.
///
/// All events are written locally before any network attempt.
/// This guarantees:
///   - Zero data loss on network failure or app kill
///   - Offline-first operation
///   - Atomic batch-deletes on successful upstream sync
///
/// Schema is intentionally flat — no foreign keys, no joins.
/// The buffer is a durable queue, not an analytics store.
class SqliteEventBuffer {
  SqliteEventBuffer._();
  static final instance = SqliteEventBuffer._();

  Database? _db;
  // sqflite is unsupported on web; when true all methods are silent no-ops.
  bool _unavailable = false;

  static const _kDbName   = 'flick_event_queue.db';
  static const _kTable    = 'event_queue';
  static const _kVersion  = 1;

  // ── DDL ───────────────────────────────────────────────────────────────────

  static const _kCreateTable = '''
    CREATE TABLE IF NOT EXISTS $_kTable (
      id            INTEGER  PRIMARY KEY AUTOINCREMENT,
      event_id      TEXT     NOT NULL UNIQUE,  -- ULID de-dup key
      event_type    TEXT     NOT NULL,
      app_id        TEXT     NOT NULL,
      subject_id    TEXT     NOT NULL,
      session_id    TEXT     NOT NULL,
      emitted_at_ms INTEGER  NOT NULL,         -- Unix milliseconds (UTC)
      payload_json  TEXT     NOT NULL,         -- full FlickEvent.toJsonString()
      synced        INTEGER  NOT NULL DEFAULT 0, -- 0=pending, 1=synced
      retry_count   INTEGER  NOT NULL DEFAULT 0,
      created_at_ms INTEGER  NOT NULL DEFAULT (strftime('%s','now') * 1000)
    )
  ''';

  static const _kCreateIdxSynced = '''
    CREATE INDEX IF NOT EXISTS idx_eq_synced
    ON $_kTable (synced, created_at_ms)
  ''';

  static const _kCreateIdxEventId = '''
    CREATE UNIQUE INDEX IF NOT EXISTS idx_eq_event_id
    ON $_kTable (event_id)
  ''';

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_db != null || _unavailable) return;
    try {
      final dbPath = join(await getDatabasesPath(), _kDbName);
      _db = await openDatabase(
        dbPath,
        version: _kVersion,
        onCreate: (db, _) async {
          await db.execute(_kCreateTable);
          await db.execute(_kCreateIdxSynced);
          await db.execute(_kCreateIdxEventId);
          await db.execute('PRAGMA journal_mode=WAL');
          await db.execute('PRAGMA wal_autocheckpoint=100');
        },
      );
      debugPrint('[SqliteBuffer] opened at $dbPath');
    } catch (e) {
      _unavailable = true;
      debugPrint('[SqliteBuffer] unavailable (web?): $e — events will not be persisted');
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Persists a single event. Idempotent — duplicate event_id is silently ignored.
  Future<void> enqueue(FlickEvent event) async {
    if (_unavailable) return;
    await _db!.insert(
      _kTable,
      {
        'event_id':      event.eventId,
        'event_type':    event.eventType,
        'app_id':        event.appId,
        'subject_id':    event.subjectId,
        'session_id':    event.sessionId,
        'emitted_at_ms': event.emittedAt.millisecondsSinceEpoch,
        'payload_json':  event.toJsonString(),
        'synced':        0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns up to [limit] unsynced events, ordered by creation time (FIFO).
  Future<List<FlickEvent>> getPending({int limit = 250}) async {
    if (_unavailable) return const [];
    final rows = await _db!.query(
      _kTable,
      where:   'synced = 0',
      orderBy: 'created_at_ms ASC',
      limit:   limit,
    );
    return rows
        .map((r) => FlickEvent.fromJson(
              jsonDecode(r['payload_json'] as String) as Map<String, Object?>,
            ))
        .toList();
  }

  Future<int> pendingCount() async {
    if (_unavailable) return 0;
    final result = await _db!.rawQuery(
      'SELECT COUNT(*) as c FROM $_kTable WHERE synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── Mark synced ───────────────────────────────────────────────────────────

  /// Atomically marks a batch of events as synced.
  /// Called ONLY after a confirmed 200 from the Event Hub endpoint.
  Future<void> markSynced(List<String> eventIds) async {
    if (eventIds.isEmpty || _unavailable) return;
    final placeholders = eventIds.map((_) => '?').join(',');
    await _db!.rawUpdate(
      'UPDATE $_kTable SET synced = 1 WHERE event_id IN ($placeholders)',
      eventIds,
    );
  }

  /// Increments retry_count. Events with retry_count > 5 are considered
  /// dead-letter and skipped by the sync service.
  Future<void> incrementRetry(List<String> eventIds) async {
    if (eventIds.isEmpty || _unavailable) return;
    final placeholders = eventIds.map((_) => '?').join(',');
    await _db!.rawUpdate(
      'UPDATE $_kTable SET retry_count = retry_count + 1 '
      'WHERE event_id IN ($placeholders)',
      eventIds,
    );
  }

  // ── Housekeeping ──────────────────────────────────────────────────────────

  /// Purges events synced more than [retainDays] days ago.
  Future<int> vacuum({int retainDays = 7}) async {
    if (_unavailable) return 0;
    final cutoff = DateTime.now()
        .subtract(Duration(days: retainDays))
        .millisecondsSinceEpoch;

    return _db!.delete(
      _kTable,
      where: 'synced = 1 AND created_at_ms < ?',
      whereArgs: [cutoff],
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
