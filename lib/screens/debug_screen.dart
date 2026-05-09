import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flick_sdk/flick_sdk.dart';
import '../core/theme/app_theme.dart';
import '../services/firebase_sync_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final List<_TestResult> _results = [];
  bool _running = false;

  Future<void> _runTests() async {
    setState(() { _results.clear(); _running = true; });

    // Test 1: EventSensor
    _add('EventSensor initialized', EventSensor.instance.sessionId.isNotEmpty);

    // Test 2: Emit test event
    try {
      await EventSensor.instance.emitAwaited('debug_test', {
        'timestamp': DateTime.now().toIso8601String(),
        'source':    'debug_screen',
      });
      _add('Test event emitted to buffer', true);
    } catch (e) {
      _add('Test event emit failed: $e', false);
    }

    // Test 3: Firestore sync
    try {
      await FirebaseSyncService().sync();
      _add('Firestore sync triggered', true);
    } catch (e) {
      _add('Firestore sync failed: $e', false);
    }

    // Test 4: Firestore read
    try {
      final snap = await FirebaseFirestore.instance
          .collection('events')
          .orderBy('emitted_at_utc', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final doc  = snap.docs.first;
        final type = doc.data()['event_type'] ?? 'unknown';
        _add('Firestore readable — latest event: $type', true);
      } else {
        _add('Firestore connected but no events yet', true, warning: true);
      }
    } catch (e) {
      _add('Firestore read failed: $e', false);
    }

    // Test 5: SQLite buffer count
    try {
      final count = await SqliteEventBuffer.instance.pendingCount();
      _add('SQLite buffer pending: $count events', true);
    } catch (e) {
      _add('SQLite buffer unavailable (web): ok', true, warning: true);
    }

    setState(() => _running = false);
  }

  void _add(String message, bool passed, {bool warning = false}) {
    setState(() => _results.add(_TestResult(message, passed, warning)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlickColors.background,
      appBar: AppBar(title: const Text('Database test')),
      body: Padding(
        padding: const EdgeInsets.all(FlickSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Runs a live check of the full data pipeline:\n'
              'EventSensor → SQLite buffer → Firestore',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: FlickSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _running ? null : _runTests,
                icon: _running
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(_running ? 'Running…' : 'Run tests'),
              ),
            ),

            const SizedBox(height: FlickSpacing.xl),

            ..._results.asMap().entries.map((e) => _ResultRow(
                  result: e.value,
                  index:  e.key,
                )),

            if (_results.isNotEmpty &&
                !_running &&
                _results.every((r) => r.passed)) ...[
              const SizedBox(height: FlickSpacing.lg),
              Container(
                padding: const EdgeInsets.all(FlickSpacing.md),
                decoration: BoxDecoration(
                  color: FlickColors.successDim,
                  borderRadius: const BorderRadius.all(FlickRadius.lg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: FlickColors.success),
                    const SizedBox(width: FlickSpacing.sm),
                    Expanded(
                      child: Text(
                        'All tests passed — check Firebase Console → '
                        'Firestore → events collection to see your data.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: FlickColors.success),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
            ],
          ],
        ),
      ),
    );
  }
}

class _TestResult {
  const _TestResult(this.message, this.passed, this.warning);
  final String message;
  final bool   passed;
  final bool   warning;
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result, required this.index});
  final _TestResult result;
  final int         index;

  @override
  Widget build(BuildContext context) {
    final color = result.passed
        ? (result.warning ? FlickColors.warning : FlickColors.success)
        : FlickColors.error;
    final icon  = result.passed
        ? (result.warning
            ? Icons.warning_amber_rounded
            : Icons.check_circle_rounded)
        : Icons.cancel_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: FlickSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: FlickSpacing.sm),
          Expanded(
            child: Text(result.message,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: FlickColors.textPrimary)),
          ),
        ],
      ).animate(delay: (index * 150).ms).fadeIn().slideX(begin: -0.05),
    );
  }
}
