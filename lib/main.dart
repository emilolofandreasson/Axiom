import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flick_sdk/flick_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'config/env.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/api_key_service.dart';
import 'services/auth_service.dart';
import 'services/firebase_sync_service.dart';
import 'services/lesson_generator.dart';

final authService   = AuthService(hmacSalt: Env.hmacSalt);
final apiKeyService = ApiKeyService();
bool onboardingDone = false;

// Non-final — updated by ApiKeyService when user saves/removes their key.
late LessonGenerator lessonGenerator;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await authService.initialize();
  } catch (e) {
    debugPrint('[main] Firebase init failed: $e');
  }

  // Start with stub; upgraded to GeminiBridge if a key is found.
  lessonGenerator = LessonGenerator(bridge: StubEdgeAiBridge());

  // 1. Try saved key from device storage.
  await apiKeyService.initFromStorage();

  // 2. If signed in (non-anon), try to load key from Firestore (cross-device).
  if (!authService.isAnonymous) {
    await apiKeyService.syncFromFirestore();
  }

  // 3. Fall back to compile-time key (dev convenience).
  if (Env.geminiApiKey.isNotEmpty) {
    final bridge = GeminiBridge(apiKey: Env.geminiApiKey);
    await bridge.loadModel('');
    lessonGenerator = LessonGenerator(bridge: bridge);
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

  await EventSensor.instance.initialize(
    config: const SensorConfig(
      appId:      'axiom',
      appVersion: '1.0.0',
      platform:   'web',
    ),
  );

  EventSensor.instance.emit('app_opened', {
    'app_version': '1.0.0',
    'platform':    'web',
  });

  FirebaseSyncService().sync();

  WidgetsBinding.instance.addObserver(_LifecycleObserver());

  runApp(const ProviderScope(child: AxiomApp()));
}

class _LifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      EventSensor.instance.flushOnBackground();
    }
  }
}

class AxiomApp extends StatelessWidget {
  const AxiomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                      'Axiom',
      debugShowCheckedModeBanner: false,
      theme:                      buildAppTheme(),
      home: onboardingDone ? const HomeScreen() : OnboardingScreen(),
    );
  }
}
