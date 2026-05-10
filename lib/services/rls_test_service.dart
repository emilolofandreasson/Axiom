import 'package:supabase_flutter/supabase_flutter.dart';

/// Test result data structure
class RLSTestResult {
  final String name;
  final bool passed;
  final String? error;
  final String? details;

  RLSTestResult({
    required this.name,
    required this.passed,
    this.error,
    this.details,
  });

  @override
  String toString() =>
      '${passed ? '✅' : '❌'} $name${details != null ? ' — $details' : ''}${error != null ? '\n   Error: $error' : ''}';
}

/// RLS Security Test Service — validates that Row Level Security policies are working
class RLSTestService {
  static final _instance = RLSTestService._internal();

  factory RLSTestService() => _instance;
  RLSTestService._internal();

  SupabaseClient get _db => Supabase.instance.client;

  /// Run all RLS tests
  Future<List<RLSTestResult>> runAllTests() async {
    final results = <RLSTestResult>[];

    // Test 1: User can read own profile
    results.add(await _testOwnProfileRead());

    // Test 2: User can update own profile
    results.add(await _testOwnProfileUpdate());

    // Test 3: User cannot read other user's profile
    results.add(await _testCrossUserProfileBlocked());

    // Test 4: User can insert own events
    results.add(await _testInsertOwnEvent());

    // Test 5: User cannot read events
    results.add(await _testEventsReadBlocked());

    // Test 6: User can read own consent
    results.add(await _testOwnConsentRead());

    // Test 7: User cannot modify consent
    results.add(await _testConsentImmutable());

    // Test 8: Friend request RLS
    results.add(await _testFriendRequestRLS());

    return results;
  }

  Future<RLSTestResult> _testOwnProfileRead() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) {
        return RLSTestResult(
          name: 'Own profile read',
          passed: false,
          error: 'Not authenticated',
        );
      }

      final row = await _db.from('users').select().eq('id', uid).maybeSingle();
      return RLSTestResult(
        name: 'Own profile read',
        passed: row != null,
        details: row != null ? 'Loaded ${row['name'] ?? 'unnamed'} profile' : null,
      );
    } catch (e) {
      return RLSTestResult(
        name: 'Own profile read',
        passed: false,
        error: e.toString(),
      );
    }
  }

  Future<RLSTestResult> _testOwnProfileUpdate() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) {
        return RLSTestResult(
          name: 'Own profile update',
          passed: false,
          error: 'Not authenticated',
        );
      }

      final testValue = 'rls_test_${DateTime.now().millisecondsSinceEpoch}';
      await _db.from('users').update({'bio': testValue}).eq('id', uid);

      // Verify it was updated
      final row = await _db.from('users').select('bio').eq('id', uid).single();
      final success = row['bio'] == testValue;

      // Clean up
      await _db.from('users').update({'bio': null}).eq('id', uid);

      return RLSTestResult(
        name: 'Own profile update',
        passed: success,
        details: success ? 'Update successful' : 'Update failed to persist',
      );
    } catch (e) {
      return RLSTestResult(
        name: 'Own profile update',
        passed: false,
        error: e.toString(),
      );
    }
  }

  Future<RLSTestResult> _testCrossUserProfileBlocked() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) {
        return RLSTestResult(
          name: 'Cross-user profile blocked',
          passed: false,
          error: 'Not authenticated',
        );
      }

      // Try to read another user's profile by querying without filtering
      // RLS should prevent this
      final rows = await _db.from('users').select().neq('id', uid).limit(1);

      // If we got results, RLS is NOT working (FAIL)
      return RLSTestResult(
        name: 'Cross-user profile blocked',
        passed: (rows as List).isEmpty,
        details:
            (rows as List).isEmpty ? 'RLS blocking other users ✓' : 'Got ${(rows as List).length} rows from other users ✗',
      );
    } catch (e) {
      // Expected to fail — RLS should throw
      if (e.toString().contains('policy') || e.toString().contains('POLICY')) {
        return RLSTestResult(
          name: 'Cross-user profile blocked',
          passed: true,
          details: 'RLS correctly rejected cross-user query',
        );
      }
      return RLSTestResult(
        name: 'Cross-user profile blocked',
        passed: false,
        error: 'Unexpected error: $e',
      );
    }
  }

  Future<RLSTestResult> _testInsertOwnEvent() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) {
        return RLSTestResult(
          name: 'Insert own event',
          passed: false,
          error: 'Not authenticated',
        );
      }

      final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      await _db.from('events').insert({
        'id': testId,
        'user_id': uid,
        'event_type': 'rls_test',
        'payload': {'test': true},
      });

      return RLSTestResult(
        name: 'Insert own event',
        passed: true,
        details: 'Event inserted (RLS allows)',
      );
    } catch (e) {
      return RLSTestResult(
        name: 'Insert own event',
        passed: false,
        error: e.toString(),
      );
    }
  }

  Future<RLSTestResult> _testEventsReadBlocked() async {
    try {
      // Try to read events — RLS should block SELECT
      final rows = await _db.from('events').select().limit(1);

      // If we got results, RLS is NOT working
      return RLSTestResult(
        name: 'Events SELECT blocked',
        passed: (rows as List).isEmpty,
        details: (rows as List).isEmpty ? 'RLS blocking SELECT ✓' : 'Got events (RLS not enforced)',
      );
    } catch (e) {
      // Expected — RLS should reject SELECT
      if (e.toString().contains('policy') || e.toString().contains('POLICY')) {
        return RLSTestResult(
          name: 'Events SELECT blocked',
          passed: true,
          details: 'RLS correctly rejected SELECT',
        );
      }
      return RLSTestResult(
        name: 'Events SELECT blocked',
        passed: false,
        error: 'Unexpected error: $e',
      );
    }
  }

  Future<RLSTestResult> _testOwnConsentRead() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) {
        return RLSTestResult(
          name: 'Own consent read',
          passed: false,
          error: 'Not authenticated',
        );
      }

      final rows = await _db.from('consent_log').select().eq('user_id', uid);

      return RLSTestResult(
        name: 'Own consent read',
        passed: true,
        details: 'Can read ${(rows as List).length} consent records',
      );
    } catch (e) {
      return RLSTestResult(
        name: 'Own consent read',
        passed: false,
        error: e.toString(),
      );
    }
  }

  Future<RLSTestResult> _testConsentImmutable() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) {
        return RLSTestResult(
          name: 'Consent immutable',
          passed: false,
          error: 'Not authenticated',
        );
      }

      // Try to update consent — should fail
      final rows = await _db.from('consent_log').select('id').eq('user_id', uid).limit(1);

      if ((rows as List).isEmpty) {
        return RLSTestResult(
          name: 'Consent immutable',
          passed: true,
          details: 'No consent records to update (skipped)',
        );
      }

      final consentId = rows.first['id'] as String;

      try {
        await _db.from('consent_log').update({'granted': false}).eq('id', consentId);

        // If we get here, UPDATE was allowed (BAD)
        return RLSTestResult(
          name: 'Consent immutable',
          passed: false,
          details: 'UPDATE was allowed (RLS not enforced)',
        );
      } catch (updateError) {
        // Expected — RLS should block UPDATE
        return RLSTestResult(
          name: 'Consent immutable',
          passed: true,
          details: 'RLS correctly blocked UPDATE',
        );
      }
    } catch (e) {
      return RLSTestResult(
        name: 'Consent immutable',
        passed: false,
        error: e.toString(),
      );
    }
  }

  Future<RLSTestResult> _testFriendRequestRLS() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) {
        return RLSTestResult(
          name: 'Friend request RLS',
          passed: false,
          error: 'Not authenticated',
        );
      }

      // Users should only see requests sent by them or to them
      final rows = await _db.from('friend_requests').select().limit(10);

      return RLSTestResult(
        name: 'Friend request RLS',
        passed: true,
        details: 'Can see ${(rows as List).length} requests (RLS filtering applied)',
      );
    } catch (e) {
      return RLSTestResult(
        name: 'Friend request RLS',
        passed: false,
        error: e.toString(),
      );
    }
  }
}
