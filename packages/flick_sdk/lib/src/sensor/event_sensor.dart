import 'package:flutter/foundation.dart';
import '../identity/identity_service.dart';
import 'flick_event.dart';
import 'sqlite_buffer.dart';
import 'ulid.dart';

/// Configuration injected once at app startup.
@immutable
class SensorConfig {
  const SensorConfig({
    required this.appId,
    required this.appVersion,
    required this.platform,
    this.autoFlushThreshold = 20,
  });

  final String appId;        // "axiom" | "golf_flick" | …
  final String appVersion;   // semver string
  final String platform;     // "ios" | "android" | "web"

  /// Trigger an in-memory flush to SQLite after this many events.
  final int autoFlushThreshold;
}

/// The central event bus for the entire Flick ecosystem.
///
/// Drop-in usage in any Flick app:
/// ```dart
/// // In main():
/// await EventSensor.instance.initialize(
///   config: SensorConfig(appId: 'axiom', appVersion: '1.0.0', platform: 'ios'),
///   identity: identityService,
/// );
///
/// // Anywhere in the app:
/// EventSensor.instance.emit('lesson_completed', {
///   'lesson_id': 'es-A2-04',
///   'accuracy_pct': 0.85,
/// });
/// ```
class EventSensor {
  EventSensor._();
  static final instance = EventSensor._();

  late SensorConfig _config;
  IdentityService?  _identity;
  bool _initialized = false;

  /// Stable for the lifetime of a single app session (cold start → background kill).
  final String sessionId = Ulid.generate();

  final SqliteEventBuffer _buffer = SqliteEventBuffer.instance;

  // In-memory staging list — flushed to SQLite periodically.
  final List<FlickEvent> _staging = [];

  Future<void> initialize({
    required SensorConfig config,
    IdentityService? identity,
  }) async {
    if (_initialized) return;
    _config   = config;
    _identity = identity;
    await _buffer.initialize();
    _initialized = true;

    debugPrint(
      '[EventSensor] ready  app=${config.appId}  session=$sessionId',
    );
  }

  /// Binds a signed-in [IdentityService] after initial anonymous startup.
  void setIdentity(IdentityService identity) => _identity = identity;

  /// Overrides the subject_id directly — used by Firebase Auth and other
  /// identity providers that don't use IdentityService.
  void setSubjectIdOverride(String subjectId) => _subjectIdOverride = subjectId;

  String? _subjectIdOverride;

  // ── Core emit ─────────────────────────────────────────────────────────────

  /// Records an interaction event.
  ///
  /// [eventType] — snake_case name, e.g. "answer_submitted"
  /// [payload]   — app-specific key/value pairs (see data contract)
  void emit(String eventType, [Map<String, Object?> payload = const {}]) {
    if (!_initialized) return;

    final event = FlickEvent(
      eventType:  eventType,
      appId:      _config.appId,
      appVersion: _config.appVersion,
      platform:   _config.platform,
      subjectId:  _currentSubjectId,
      sessionId:  sessionId,
      payload:    payload,
    );

    _staging.add(event);

    if (kDebugMode) _prettyPrint(event);

    if (_staging.length >= _config.autoFlushThreshold) {
      _flushToBuffer();
    }
  }

  /// Convenience wrapper — emits and awaits the SQLite write.
  Future<void> emitAwaited(
    String eventType, [
    Map<String, Object?> payload = const {},
  ]) async {
    emit(eventType, payload);
    await _flushToBuffer();
  }

  // ── Lifecycle hooks ───────────────────────────────────────────────────────

  /// Call from AppLifecycleState.paused / detached to guarantee persistence
  /// before the OS kills the process.
  Future<void> flushOnBackground() => _flushToBuffer();

  Future<void> _flushToBuffer() async {
    if (_staging.isEmpty) return;
    final batch = List<FlickEvent>.from(_staging);
    _staging.clear();

    for (final event in batch) {
      await _buffer.enqueue(event);
    }
  }

  String get _currentSubjectId {
    if (_subjectIdOverride != null) return _subjectIdOverride!;
    if (_identity?.currentIdentity != null) {
      return _identity!.currentIdentity!.subjectId;
    }
    if (_identity?.persistentAnonSubjectId != null) {
      return _identity!.persistentAnonSubjectId!;
    }
    return 'anon-${sessionId.substring(0, 8)}';
  }

  static void _prettyPrint(FlickEvent e) {
    debugPrint('\n╔══ FlickEvent ══════════════════════════════');
    debugPrint('║  type       : ${e.eventType}');
    debugPrint('║  app        : ${e.appId} v${e.appVersion}');
    debugPrint('║  subject_id : ${e.subjectId}');
    debugPrint('║  session_id : ${e.sessionId}');
    debugPrint('║  event_id   : ${e.eventId}');
    if (e.payload.isNotEmpty) {
      debugPrint('║  payload    :');
      e.payload.forEach((k, v) => debugPrint('║    $k: $v'));
    }
    debugPrint('╚════════════════════════════════════════════\n');
  }
}
