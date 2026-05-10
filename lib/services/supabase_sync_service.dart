import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flick_sdk/flick_sdk.dart';

/// Reads buffered events from the flick_sdk SQLite queue and
/// writes them to the Supabase `events` table in batches.
///
/// GDPR: Events are only synced if user has given consent for 'anonymous_stats'.
/// Without consent, events remain in local buffer indefinitely.
class SupabaseSyncService {
  SupabaseSyncService({this.batchSize = 250});

  final int batchSize;
  final _buffer = SqliteEventBuffer.instance;

  bool _running = false;

  /// Check if user has given consent to collect analytics
  Future<bool> _hasAnalyticsConsent(String uid) async {
    try {
      final consent = await Supabase.instance.client
          .from('consent_log')
          .select('granted')
          .eq('user_id', uid)
          .eq('purpose', 'anonymous_stats')
          .maybeSingle();

      if (consent == null) {
        debugPrint('[SupabaseSyncService] No consent record found for user');
        return false;
      }

      final granted = consent['granted'] as bool? ?? false;
      if (!granted) {
        debugPrint('[SupabaseSyncService] User has not granted analytics consent');
      }
      return granted;
    } catch (e) {
      debugPrint('[SupabaseSyncService] Error checking consent: $e');
      // Conservative: don't sync if we can't verify consent
      return false;
    }
  }

  Future<void> sync() async {
    if (_running) return;
    _running = true;

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return; // not logged in — nothing to sync

      // GDPR: Check consent before syncing events
      final hasConsent = await _hasAnalyticsConsent(uid);
      if (!hasConsent) {
        debugPrint('[SupabaseSyncService] Skipping sync — user has not consented to analytics');
        return;
      }

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

      debugPrint('[SupabaseSyncService] synced ${pending.length} events (consent verified)');
    } catch (e) {
      debugPrint('[SupabaseSyncService] error: $e');
    } finally {
      _running = false;
    }
  }
}
