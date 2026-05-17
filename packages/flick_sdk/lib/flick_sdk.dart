/// Flick App Factory SDK
///
/// Drop into any Flick app for instant identity, event sensing,
/// local buffering, batch sync, and Edge AI.
///
/// ```dart
/// import 'package:flick_sdk/flick_sdk.dart';
/// ```
library flick_sdk;

// Identity
export 'src/identity/identity_service.dart';
export 'src/identity/subject_id_hasher.dart';

// Sensor
export 'src/sensor/ulid.dart';
export 'src/sensor/flick_event.dart';
export 'src/sensor/sqlite_buffer.dart';
export 'src/sensor/event_sensor.dart';

// Sync
export 'src/sync/sync_service.dart';

// Edge AI
export 'src/edge_ai/edge_ai_bridge.dart';
export 'src/edge_ai/gemini_bridge.dart';
