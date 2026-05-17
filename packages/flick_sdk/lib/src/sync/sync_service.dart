import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../sensor/sqlite_buffer.dart';

/// Uploads pending events from the local SQLite buffer to the Event Hub.
///
/// Sync policy:
///   - Only runs on WiFi (cellular = user pays, keep OpEx zero)
///   - Batch size: 250 events per request (stays under 1MB JSON payload)
///   - Retry: exponential back-off, max 5 retries (then dead-letter)
///   - Idempotent: server deduplicates on event_id (ULID)
///
/// Phase 1: HTTP POST to Azure Event Hub REST endpoint.
/// Phase 2: Replace with Kafka producer SDK for lower latency.
class SyncService {
  SyncService({
    required String eventHubEndpoint,
    required String sasToken,
    this.batchSize = 250,
  })  : _endpoint = Uri.parse(eventHubEndpoint),
        _sasToken  = sasToken;

  final Uri    _endpoint;
  final String _sasToken;
  final int    batchSize;

  final SqliteEventBuffer _buffer = SqliteEventBuffer.instance;

  bool _running = false;

  /// Triggers a sync cycle. Safe to call frequently — no-op if already running.
  Future<SyncResult> sync() async {
    if (_running) return const SyncResult(skipped: true);
    _running = true;

    try {
      if (!await _isOnWifi()) {
        debugPrint('[SyncService] not on WiFi — skipping sync');
        return const SyncResult(skippedReason: 'no_wifi');
      }

      final pending = await _buffer.getPending(limit: batchSize);
      if (pending.isEmpty) return const SyncResult(uploaded: 0);

      final payload = jsonEncode(pending.map((e) => e.toJson()).toList());
      final eventIds = pending.map((e) => e.eventId).toList();

      final response = await http.post(
        _endpoint,
        headers: {
          'Authorization': _sasToken,
          'Content-Type':  'application/json',
          'BrokerProperties': jsonEncode({'PartitionKey': pending.first.appId}),
        },
        body: payload,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await _buffer.markSynced(eventIds);
        debugPrint('[SyncService] synced ${eventIds.length} events');
        return SyncResult(uploaded: eventIds.length);
      } else {
        await _buffer.incrementRetry(eventIds);
        debugPrint('[SyncService] HTTP ${response.statusCode} — retrying later');
        return SyncResult(failed: eventIds.length, httpStatus: response.statusCode);
      }
    } catch (e) {
      debugPrint('[SyncService] error: $e');
      return SyncResult(error: e.toString());
    } finally {
      _running = false;
    }
  }

  Future<bool> _isOnWifi() async {
    if (kIsWeb) return true;
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.wifi);
  }
}

@immutable
class SyncResult {
  const SyncResult({
    this.uploaded     = 0,
    this.failed       = 0,
    this.skipped      = false,
    this.skippedReason,
    this.httpStatus,
    this.error,
  });

  final int     uploaded;
  final int     failed;
  final bool    skipped;
  final String? skippedReason;
  final int?    httpStatus;
  final String? error;

  bool get success => !skipped && error == null && failed == 0;
}
