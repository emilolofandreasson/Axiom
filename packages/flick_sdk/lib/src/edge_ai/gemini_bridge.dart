import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'edge_ai_bridge.dart';

class GeminiBridge extends EdgeAiBridge {
  GeminiBridge({required String apiKey, this.proxyUrl}) : _apiKey = apiKey;

  final String  _apiKey;
  final String? proxyUrl; // If set, routes through CORS proxy (needed for web)
  bool _loaded = false;

  static const _model   = 'gemini-2.5-flash';
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  @override InferenceBackend get backend  => InferenceBackend.api;
  @override bool             get isLoaded => _loaded;

  @override
  Future<void> loadModel(String modelPath) async {
    _loaded = true;
    debugPrint('[GeminiBridge] ready — ${proxyUrl != null ? "via proxy" : "direct"} — model: $_model');
  }

  @override
  Future<InferenceResult> complete(InferenceRequest request) async {
    final stopwatch = Stopwatch()..start();
    final prompt = request.systemPrompt != null
        ? '${request.systemPrompt}\n\n${request.prompt}'
        : request.prompt;

    try {
      final http.Response response;

      if (proxyUrl != null) {
        // Route through CORS proxy — needed for Flutter web.
        response = await http.post(
          Uri.parse('$proxyUrl/api/gemini'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'prompt':      prompt,
            'apiKey':      _apiKey,
            'maxTokens':   request.maxTokens,
            'temperature': request.temperature,
          }),
        );
      } else {
        // Direct call — works on mobile/desktop, blocked by CORS on web.
        response = await http.post(
          Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {'parts': [{'text': prompt}]}
            ],
            'generationConfig': {
              'temperature':     request.temperature,
              'maxOutputTokens': request.maxTokens,
            },
          }),
        );
      }

      stopwatch.stop();

      if (response.statusCode != 200) {
        debugPrint('[GeminiBridge] HTTP ${response.statusCode}: ${response.body}');
        return InferenceResult(
          text: '', latencyMs: stopwatch.elapsedMilliseconds,
          backend: InferenceBackend.api, tokensGenerated: 0,
          error: 'HTTP ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;

      return InferenceResult(
        text:            text,
        latencyMs:       stopwatch.elapsedMilliseconds,
        backend:         InferenceBackend.api,
        tokensGenerated: text.split(' ').length,
      );
    } catch (e) {
      stopwatch.stop();
      debugPrint('[GeminiBridge] error: $e');
      return InferenceResult(
        text: '', latencyMs: stopwatch.elapsedMilliseconds,
        backend: InferenceBackend.api, tokensGenerated: 0,
        error: e.toString(),
      );
    }
  }

  @override
  Future<void> dispose() async => _loaded = false;
}
