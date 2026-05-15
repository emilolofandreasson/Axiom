import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flick_sdk/flick_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth_gate_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/api_key_service.dart';
import 'services/auth_service.dart';
import 'services/supabase_sync_service.dart';
import 'services/lesson_generator.dart';
import 'services/puzzle_generator_service.dart';
import 'services/question_contributor_service.dart';
import 'services/question_library_service.dart';

final authService          = AuthService(hmacSalt: Env.hmacSalt);
final apiKeyService        = ApiKeyService();
final questionLibrary      = QuestionLibraryService();
final questionContributor  = QuestionContributorService(library: questionLibrary);
bool onboardingDone        = false;
DateTime _sessionStartedAt = DateTime.now();

// Non-final — updated by ApiKeyService when user saves/removes their key.
late LessonGenerator        lessonGenerator;
late PuzzleGeneratorService puzzleGenerator;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:     Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  authService.initialize();

  final proxy = Env.proxyUrl.isNotEmpty ? Env.proxyUrl : null;

  // Default: use GeminiBridge via proxy (proxy supplies server-side key).
  // Falls back to StubEdgeAiBridge only when no proxy is configured.
  if (proxy != null) {
    final bridge = GeminiBridge(apiKey: '', proxyUrl: proxy);
    await bridge.loadModel('');
    lessonGenerator  = LessonGenerator(bridge: bridge, library: questionLibrary);
    puzzleGenerator  = PuzzleGeneratorService(bridge: bridge);
  } else {
    final stub       = StubEdgeAiBridge();
    lessonGenerator  = LessonGenerator(bridge: stub, library: questionLibrary);
    puzzleGenerator  = PuzzleGeneratorService(bridge: stub);
  }

  // 1. Override with user's saved key from device storage (higher priority).
  await apiKeyService.initFromStorage();

  // 2. If signed in, try to load key from Supabase (cross-device).
  if (authService.currentUser != null) {
    await apiKeyService.syncFromSupabase();
  }

  // 3. Override with compile-time key if explicitly provided.
  if (Env.geminiApiKey.isNotEmpty) {
    final bridge     = GeminiBridge(apiKey: Env.geminiApiKey, proxyUrl: proxy);
    await bridge.loadModel('');
    lessonGenerator  = LessonGenerator(bridge: bridge, library: questionLibrary);
    puzzleGenerator  = PuzzleGeneratorService(bridge: bridge);
  }

  final prefs = await SharedPreferences.getInstance();
  onboardingDone = prefs.getBool('onboarding_complete') ?? false;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:          Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final platform = defaultTargetPlatform == TargetPlatform.android
      ? 'android'
      : defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'web';

  await EventSensor.instance.initialize(
    config: SensorConfig(
      appId:      'axiom',
      appVersion: '1.0.0',
      platform:   platform,
    ),
  );

  _sessionStartedAt = DateTime.now();
  EventSensor.instance.emit('app_opened', {
    'app_version': '1.0.0',
    'platform':    platform,
    'hour_of_day': _sessionStartedAt.hour,
    'day_of_week': _sessionStartedAt.weekday, // 1=Mon … 7=Sun
  });

  SupabaseSyncService().sync();

  WidgetsBinding.instance.addObserver(_LifecycleObserver());

  runApp(const ProviderScope(child: AxiomApp()));
}

class _LifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final sessionSeconds =
          DateTime.now().difference(_sessionStartedAt).inSeconds;
      EventSensor.instance.emit('session_ended', {
        'duration_seconds': sessionSeconds,
        'hour_of_day':      _sessionStartedAt.hour,
        'day_of_week':      _sessionStartedAt.weekday,
      });
      EventSensor.instance.flushOnBackground();
    }
    if (state == AppLifecycleState.resumed) {
      _sessionStartedAt = DateTime.now();
    }
  }
}

Widget _resolveHome() {
  if (authService.currentUser == null) return const AuthGateScreen();
  if (!onboardingDone) return OnboardingScreen();
  return const MainScreen();
}

class AxiomApp extends StatelessWidget {
  const AxiomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                      'Axiom',
      debugShowCheckedModeBanner: false,
      theme:                      buildAppTheme(),
      home: _resolveHome(),
    );
  }
}
