import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Edge AI Bridge — abstract contract for on-device LLM inference.
//
// Concrete implementations:
//   LlamaBridge   → llama.cpp via Dart FFI  (iOS Metal / Android Vulkan)
//   TFLiteBridge  → TensorFlow Lite          (fallback for low-end devices)
//   StubBridge    → deterministic fake       (dev/test only)
//
// All Flick apps share this interface. Swap implementations at runtime
// based on device RAM and OS without changing any calling code.
// ---------------------------------------------------------------------------

enum InferenceBackend { llama, tflite, stub, api }

@immutable
class InferenceRequest {
  const InferenceRequest({
    required this.prompt,
    this.systemPrompt,
    this.maxTokens    = 256,
    this.temperature  = 0.3,
    this.stopSequences = const ['</s>', '<|user|>'],
  });

  final String       prompt;
  final String?      systemPrompt;
  final int          maxTokens;
  final double       temperature;
  final List<String> stopSequences;
}

@immutable
class InferenceResult {
  const InferenceResult({
    required this.text,
    required this.latencyMs,
    required this.backend,
    required this.tokensGenerated,
    this.error,
  });

  final String           text;
  final int              latencyMs;
  final InferenceBackend backend;
  final int              tokensGenerated;
  final String?          error;

  bool get isSuccess => error == null;
  double get tokensPerSecond =>
      latencyMs > 0 ? (tokensGenerated / latencyMs) * 1000 : 0;
}

/// Abstract interface — program against this, never against a concrete class.
abstract class EdgeAiBridge {
  InferenceBackend get backend;
  bool get isLoaded;

  Future<void> loadModel(String modelPath);
  Future<InferenceResult> complete(InferenceRequest request);
  Future<void> dispose();

  /// Convenience: grammar correction in the app's target language.
  Future<InferenceResult> checkGrammar({
    required String userInput,
    required String targetLanguage,
    required String cefrLevel,
  }) =>
      complete(InferenceRequest(
        systemPrompt:
            'You are a concise $targetLanguage grammar tutor for $cefrLevel '
            'learners. Reply with JSON only: '
            '{"corrected":"...","errors":[],"explanation":"..."}.',
        prompt:      'Check: "$userInput"',
        maxTokens:   128,
        temperature: 0.1,
      ));

  /// Convenience: conversational AI tutor reply.
  Future<InferenceResult> tutorReply({
    required String userMessage,
    required String conversationContext,
    required String cefrLevel,
  }) =>
      complete(InferenceRequest(
        systemPrompt: conversationContext,
        prompt:       userMessage,
        maxTokens:    200,
        temperature:  0.5,
      ));
}

// ---------------------------------------------------------------------------
// Stub implementation — used in Phase 1 / web builds / unit tests.
// ---------------------------------------------------------------------------

class StubEdgeAiBridge extends EdgeAiBridge {
  @override InferenceBackend get backend => InferenceBackend.stub;
  @override bool get isLoaded => true;

  @override
  Future<void> loadModel(String modelPath) async {}

  @override
  Future<InferenceResult> complete(InferenceRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    const reply = 'Nice try! Keep practising — you are almost there.';
    return InferenceResult(
      text:            reply,
      latencyMs:       800,
      backend:         InferenceBackend.stub,
      tokensGenerated: reply.split(' ').length,
    );
  }

  @override
  Future<void> dispose() async {}
}

// ---------------------------------------------------------------------------
// llama.cpp bridge skeleton — filled in when the FFI layer is ready.
// ---------------------------------------------------------------------------

/// Binds to the native llama.cpp shared library via Dart FFI.
/// Model format: GGUF Q4_K_M (~1.8GB for Llama 3.2 3B).
///
/// To activate:
///   1. Add llama.rn / flutter_llama to pubspec.yaml
///   2. Implement [loadModel] and [complete] using the native context
///   3. Register via FlickSdk.configure(edgeAi: LlamaBridge())
class LlamaBridge extends EdgeAiBridge {
  @override InferenceBackend get backend => InferenceBackend.llama;
  @override bool get isLoaded => _loaded;

  bool _loaded = false;
  // ignore: unused_field
  Object? _nativeContext;  // replace with LlamaContext from llama.rn

  @override
  Future<void> loadModel(String modelPath) async {
    // TODO: _nativeContext = await LlamaContext.create(modelPath, nCtx: 512, nGpuLayers: 99);
    _loaded = true;
    debugPrint('[LlamaBridge] model loaded: $modelPath');
  }

  @override
  Future<InferenceResult> complete(InferenceRequest request) async {
    assert(_loaded, 'Call loadModel() first.');
    // TODO: delegate to _nativeContext.completion(...)
    throw UnimplementedError('LlamaBridge.complete — wire up llama.rn FFI');
  }

  @override
  Future<void> dispose() async {
    // TODO: _nativeContext?.free();
    _loaded = false;
  }
}
