import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Data Export Service — GDPR Right to Data Portability (Article 20)
///
/// Exports all user data as JSON for portability:
/// - Profile (users table)
/// - Analytics events (events table)
/// - Consent history (consent_log table)
/// - Social connections (friend_requests, user_friends tables)
class DataExportService {
  static final _instance = DataExportService._internal();

  factory DataExportService() => _instance;
  DataExportService._internal();

  SupabaseClient get _db => Supabase.instance.client;

  /// Export all user data as JSON
  /// Returns the path to the exported file
  Future<String?> exportUserData() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) {
        debugPrint('[DataExport] Not authenticated');
        return null;
      }

      debugPrint('[DataExport] Starting export for user $uid');

      // Call edge function
      final response = await _db.functions.invoke(
        'data-export',
        options: FunctionInvokeOptions(
          headers: {
            'Authorization': 'Bearer ${_db.auth.currentSession?.accessToken}',
          },
        ),
      );

      if (response == null) {
        debugPrint('[DataExport] Export returned null');
        return null;
      }

      // Convert response to JSON if it's a string
      final Map<String, dynamic> exportData = response is String ? jsonDecode(response) : response;

      // Save to file
      final filename = 'axiom-export-${uid.substring(0, 8)}-${DateTime.now().millisecondsSinceEpoch}.json';
      final file = await _saveToFile(filename, jsonEncode(exportData));

      debugPrint('[DataExport] Export saved to ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('[DataExport] Export failed: $e');
      return null;
    }
  }

  /// Save export data to file system
  Future<File> _saveToFile(String filename, String jsonData) async {
    late Directory dir;

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      dir = (await getApplicationDocumentsDirectory());
    } else {
      // Web/Desktop
      dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }

    final file = File('${dir.path}/$filename');
    await file.writeAsString(jsonData);
    return file;
  }

  /// Get formatted export summary for preview
  Future<Map<String, dynamic>?> getExportSummary() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return null;

      final response = await _db.functions.invoke(
        'data-export',
        options: FunctionInvokeOptions(
          headers: {
            'Authorization': 'Bearer ${_db.auth.currentSession?.accessToken}',
          },
        ),
      );

      if (response == null) return null;

      final Map<String, dynamic> data = response is String ? jsonDecode(response) : response;

      return {
        'exportedAt': data['exportedAt'],
        'eventCount': (data['events'] as List?)?.length ?? 0,
        'consentRecords': (data['consentLog'] as List?)?.length ?? 0,
        'friendConnections': (data['userFriends'] as List?)?.length ?? 0,
        'dataSize': jsonEncode(data).length,
      };
    } catch (e) {
      debugPrint('[DataExport] Summary failed: $e');
      return null;
    }
  }
}
