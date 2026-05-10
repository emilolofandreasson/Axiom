import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flick_sdk/flick_sdk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_theme.dart';
import '../services/supabase_sync_service.dart';
import '../services/rls_test_service.dart';

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

    // Test 3: Supabase sync
    try {
      await SupabaseSyncService().sync();
      _add('Supabase event sync triggered', true);
    } catch (e) {
      _add('Supabase sync failed: $e', false);
    }

    // Test 4: Supabase read (events table)
    try {
      final rows = await Supabase.instance.client
          .from('events')
          .select('event_type')
          .order('created_at', ascending: false)
          .limit(1);
      if ((rows as List).isNotEmpty) {
        final type = rows.first['event_type'] ?? 'unknown';
        _add('Supabase readable — latest event: $type', true);
      } else {
        _add('Supabase connected but no events yet', true, warning: true);
      }
    } catch (e) {
      _add('Supabase read failed: $e', false);
    }

    // Test 5: SQLite buffer count
    try {
      final count = await SqliteEventBuffer.instance.pendingCount();
      _add('SQLite buffer pending: $count events', true);
    } catch (e) {
      _add('SQLite buffer unavailable (web): ok', true, warning: true);
    }

    // Test 6: Supabase auth
    final user = Supabase.instance.client.auth.currentUser;
    _add(
      user != null
          ? 'Authenticated as ${user.email ?? user.id.substring(0, 8)}'
          : 'Not signed in',
      user != null,
      warning: user == null,
    );

    setState(() => _running = false);
  }

  Future<void> _runRLSTests() async {
    setState(() { _results.clear(); _running = true; });

    _add('🔒 Running RLS Security Tests…', true, warning: true);

    try {
      final rls = RLSTestService();
      final results = await rls.runAllTests();
      for (final result in results) {
        _add(result.name, result.passed, details: result.details, error: result.error);
      }
    } catch (e) {
      _add('RLS test suite failed: $e', false);
    }

    setState(() => _running = false);
  }

  void _add(String message, bool passed, {bool warning = false, String? details, String? error}) {
    setState(() => _results.add(_TestResult(message, passed, warning, details, error)));
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
              'EventSensor → SQLite buffer → Supabase',
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

            const SizedBox(height: FlickSpacing.md),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _running ? null : _runRLSTests,
                icon: const Icon(Icons.security_rounded),
                label: const Text('🔒 Run RLS Security Tests'),
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
                        'All tests passed — check Supabase Table Editor → '
                        'events to see your data.',
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
  const _TestResult(this.message, this.passed, this.warning, [this.details, this.error]);
  final String message;
  final bool   passed;
  final bool   warning;
  final String? details;
  final String? error;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          ),
          if (result.details != null || result.error != null)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 4),
              child: Text(
                result.details ?? result.error ?? '',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: result.error != null ? FlickColors.error : FlickColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
        ],
      ).animate(delay: (index * 150).ms).fadeIn().slideX(begin: -0.05),
    );
  }
}
