import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flick_sdk/flick_sdk.dart';
import 'core/theme/app_theme.dart';
import 'screens/daily_lesson_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — single-column lesson layout.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar over our warm background.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:           Colors.transparent,
    statusBarIconBrightness:  Brightness.dark,
  ));

  await EventSensor.instance.initialize(
    config: const SensorConfig(
      appId:      'axiom',
      appVersion: '1.0.0',
      platform:   'web',
    ),
  );

  runApp(const ProviderScope(child: AxiomApp()));
}

class AxiomApp extends StatelessWidget {
  const AxiomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:        'Axiom',
      debugShowCheckedModeBanner: false,
      theme:        buildAppTheme(),
      home:         const DailyLessonScreen(),
    );
  }
}
