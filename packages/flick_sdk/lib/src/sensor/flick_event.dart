import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'ulid.dart';

/// Canonical event envelope — every interaction in every Flick app maps to this.
///
/// Field naming matches the Bronze-layer Delta Lake schema exactly so
/// `stg_flick_events` can SELECT * without transformation.
@immutable
class FlickEvent {
  FlickEvent({
    required this.eventType,
    required this.appId,
    required this.appVersion,
    required this.subjectId,
    required this.sessionId,
    required this.platform,
    required this.payload,
    String? eventId,
    DateTime? emittedAt,
  })  : eventId   = eventId  ?? Ulid.generate(),
        emittedAt = emittedAt ?? DateTime.now().toUtc();

  // ── Envelope (required in every event) ──────────────────────────────────
  final String   eventId;       // ULID — sort key + de-dup key
  final String   eventType;     // e.g. "lesson_completed", "session_started"
  final String   appId;         // "axiom" | "golf_flick" | "health_flick"
  final String   appVersion;
  final String   platform;      // "ios" | "android" | "web"
  final DateTime emittedAt;

  // ── Identity (PII-safe) ──────────────────────────────────────────────────
  final String subjectId;   // HMAC-anonymized UUID
  final String sessionId;   // ULID generated at app launch

  // ── App-specific payload ─────────────────────────────────────────────────
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
    'event_id':      eventId,
    'event_type':    eventType,
    'app_id':        appId,
    'app_version':   appVersion,
    'platform':      platform,
    'emitted_at_utc': emittedAt.toIso8601String(),
    'subject_id':    subjectId,
    'session_id':    sessionId,
    ...payload,   // payload fields are promoted to top level
  };

  String toJsonString() => jsonEncode(toJson());

  factory FlickEvent.fromJson(Map<String, Object?> json) => FlickEvent(
    eventId:     json['event_id']    as String,
    eventType:   json['event_type']  as String,
    appId:       json['app_id']      as String,
    appVersion:  json['app_version'] as String,
    platform:    json['platform']    as String,
    subjectId:   json['subject_id']  as String,
    sessionId:   json['session_id']  as String,
    emittedAt:   DateTime.parse(json['emitted_at_utc'] as String),
    payload:     (json..removeWhere((k, _) => _kEnvelopeKeys.contains(k)))
                     .cast<String, Object?>(),
  );

  static const _kEnvelopeKeys = {
    'event_id', 'event_type', 'app_id', 'app_version',
    'platform', 'emitted_at_utc', 'subject_id', 'session_id',
  };
}
