import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flick_sdk/flick_sdk.dart';

/// Reads buffered events from the flick_sdk SQLite queue and
/// writes them to the Supabase `events` table in batches.
///
/// Each event row: id (ULID), user_id, event_type, payload (JSONB).
class SupabaseSyncService {
  SupabaseSyncService({this.batchSize = 250});

  final int batchSize;
  final _buffer = SqliteEventBuffer.instance;

  bool _running = false;

  Future<void> sync() async {
    if (_running) return;
    _running = true;

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return; // not logged in — nothing to sync

      final pending = await _buffer.getPending(limit: batchSize);
      if (pending.isEmpty) return;

      final rows = pending.map((e) => {
        'id':         e.eventId,
        'user_id':    uid,
        'event_type': e.eventType,
        'payload':    e.toJson(),
      }).toList();

      await Supabase.instance.client.from('events').insert(rows);
      await _buffer.markSynced(pending.map((e) => e.eventId).toList());

      debugPrint('[SupabaseSyncService] synced ${pending.length} events');
    } catch (e) {
      debugPrint('[SupabaseSyncService] error: $e');
    } finally {
      _running = false;
    }
  }
}
