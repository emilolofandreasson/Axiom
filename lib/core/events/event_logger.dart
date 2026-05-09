import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// EventLogger — the "Data Sensor" layer for Axiom.
//
// Phase 1 (now): Persists events to SharedPreferences JSON list + debugPrint.
// Phase 2 (prod): Replace _flush() to batch-POST to Event Hub when on WiFi.
// ---------------------------------------------------------------------------

const String _kStorageKey = 'lf_event_queue';
const _uuid = Uuid();

/// Immutable event envelope — maps 1:1 to the Bronze-layer JSON schema.
@immutable
class FlickEvent {
  const FlickEvent({
    required this.eventType,
    required this.subjectId,
    required this.sessionId,
    required this.properties,
    String? eventId,
    DateTime? emittedAt,
  })  : eventId = eventId ?? '',
        emittedAt = emittedAt ?? const _Now();

  final String eventId;
  final String eventType;
  final String subjectId;
  final String sessionId;
  final DateTime emittedAt;
  final Map<String, Object?> properties;

  Map<String, Object?> toJson() => {
        'event_id':       eventId,
        'event_type':     eventType,
        'app_id':         'axiom',
        'app_version':    '1.0.0',
        'subject_id':     subjectId,
        'session_id':     sessionId,
        'emitted_at_utc': emittedAt.toUtc().toIso8601String(),
        ...properties,
      };
}

// Workaround: const DateTime.now() isn't allowed, so we use a helper.
class _Now implements DateTime {
  const _Now();
  @override
  dynamic noSuchMethod(Invocation i) => DateTime.now();
}

/// Singleton logger. Call [EventLogger.instance.record()] from any widget.
class EventLogger {
  EventLogger._();
  static final instance = EventLogger._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  final String _sessionId = _uuid.v4();

  // In-memory buffer — flushed to SharedPreferences every [record()] call.
  final List<Map<String, Object?>> _buffer = [];

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    // Reload any previously unsynced events from disk.
    final stored = _prefs.getStringList(_kStorageKey) ?? [];
    _buffer.addAll(stored.map((s) => jsonDecode(s) as Map<String, Object?>));
    _initialized = true;
    debugPrint('[EventLogger] initialized. '
        'session=$_sessionId  queued=${_buffer.length}');
  }

  /// Record a single interaction event.
  ///
  /// [eventType]  — e.g. "answer_submitted", "lesson_completed"
  /// [subjectId]  — anonymized UUID from Entra ID (pass from auth state)
  /// [properties] — arbitrary key/value pairs (see schema in architecture doc)
  void record({
    required String eventType,
    required String subjectId,
    Map<String, Object?> properties = const {},
  }) {
    assert(_initialized, 'Call EventLogger.instance.initialize() first.');

    final event = FlickEvent(
      eventId:    _uuid.v4(),
      eventType:  eventType,
      subjectId:  subjectId,
      sessionId:  _sessionId,
      emittedAt:  DateTime.now(),
      properties: properties,
    );

    final json = event.toJson();
    _buffer.add(json);
    _persistBuffer();

    // Phase-1: pretty-print to debug console so devs can validate the schema.
    if (kDebugMode) {
      debugPrint('\n╔══ FlickEvent ══════════════════════════════');
      debugPrint('║  type       : ${event.eventType}');
      debugPrint('║  subject_id : ${event.subjectId}');
      debugPrint('║  session_id : ${event.sessionId}');
      debugPrint('║  event_id   : ${event.eventId}');
      if (properties.isNotEmpty) {
        debugPrint('║  properties :');
        properties.forEach(
          (k, v) => debugPrint('║    $k: $v'),
        );
      }
      debugPrint('╚════════════════════════════════════════════\n');
    }
  }

  /// Returns a copy of all queued events (for the dev inspector overlay).
  List<Map<String, Object?>> get queuedEvents =>
      List.unmodifiable(_buffer);

  /// Clears the queue after successful upstream sync.
  Future<void> clearQueue() async {
    _buffer.clear();
    await _prefs.remove(_kStorageKey);
    debugPrint('[EventLogger] queue cleared after sync.');
  }

  void _persistBuffer() {
    // Fire-and-forget — we don't need to await disk write on the hot path.
    _prefs.setStringList(
      _kStorageKey,
      _buffer.map(jsonEncode).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Convenience extension — call context.logEvent() from any BuildContext.
// ---------------------------------------------------------------------------
extension EventLoggerContext on Object {
  EventLogger get logger => EventLogger.instance;
}
