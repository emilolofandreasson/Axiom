import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flick_sdk/flick_sdk.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'config/env.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/firebase_sync_service.dart';

final authService = AuthService(hmacSalt: Env.hmacSalt);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await authService.initialize();

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
      title:                   'Axiom',
      debugShowCheckedModeBanner: false,
      theme:                   buildAppTheme(),
      home:                    const HomeScreen(),
    );
  }
}
