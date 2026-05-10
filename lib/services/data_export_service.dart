import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      dynamic response = await _db.functions.invoke('data-export');

      if (response == null) {
        debugPrint('[DataExport] Export returned null');
        return null;
      }

      // FunctionResponse returns the data directly as Map or String
      final Map<String, dynamic> exportData;
      if (response is Map) {
        exportData = response.cast<String, dynamic>();
      } else if (response is String) {
        exportData = jsonDecode(response) as Map<String, dynamic>;
      } else {
        debugPrint('[DataExport] Unexpected response type: ${response.runtimeType}');
        return null;
      }

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
    // Get documents directory (most portable across platforms)
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(jsonData);
    return file;
  }

  /// Get formatted export summary for preview
  Future<Map<String, dynamic>?> getExportSummary() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return null;

      dynamic response = await _db.functions.invoke('data-export');

      if (response == null) return null;

      final Map<String, dynamic> data;
      if (response is Map) {
        data = response.cast<String, dynamic>();
      } else if (response is String) {
        data = jsonDecode(response) as Map<String, dynamic>;
      } else {
        return null;
      }

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
