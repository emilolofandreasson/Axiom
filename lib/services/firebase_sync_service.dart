import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flick_sdk/flick_sdk.dart';

/// Reads buffered events from the flick_sdk SQLite buffer and
/// writes them to Firestore in batches.
///
/// Firestore collection: `events`
/// Each document ID = event_id (ULID) — naturally deduplicated.
///
/// Firebase → BigQuery export then feeds dbt gold-layer models.
class FirebaseSyncService {
  FirebaseSyncService({this.batchSize = 250});

  final int batchSize;
  final _buffer = SqliteEventBuffer.instance;
  final _db     = FirebaseFirestore.instance;

  bool _running = false;

  Future<void> sync() async {
    if (_running) return;
    _running = true;

    try {
      final pending = await _buffer.getPending(limit: batchSize);
      if (pending.isEmpty) return;

      final batch    = _db.batch();
      final eventIds = <String>[];

      for (final event in pending) {
        final ref = _db.collection('events').doc(event.eventId);
        batch.set(ref, event.toJson(), SetOptions(merge: false));
        eventIds.add(event.eventId);
      }

      await batch.commit();
      await _buffer.markSynced(eventIds);

      debugPrint('[FirebaseSyncService] synced ${eventIds.length} events');
    } catch (e) {
      debugPrint('[FirebaseSyncService] error: $e');
    } finally {
      _running = false;
    }
  }
}
