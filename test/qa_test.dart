// test/qa_test.dart
//
// Axiom QA Widget Tests
// Run with: flutter test test/qa_test.dart
//
// Provider overrides inject mock data — no live Supabase connection needed.
// Uses pump() instead of pumpAndSettle() to avoid timeouts from infinite
// repeat() animations in the UI (e.g. pulsing Path nodes).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/models/language.dart';
import 'package:axiom/models/question.dart';
import 'package:axiom/providers/daily_goal_provider.dart';
import 'package:axiom/providers/language_provider.dart';
import 'package:axiom/providers/lesson_provider.dart';
import 'package:axiom/providers/review_provider.dart';
import 'package:axiom/models/lesson.dart';
import 'package:axiom/providers/saga_provider.dart';
import 'package:axiom/screens/main_screen.dart';
import 'package:axiom/screens/review_screen.dart';
import 'package:axiom/screens/saga_map_screen.dart';

// ---------------------------------------------------------------------------
// Mock Notifiers
// ---------------------------------------------------------------------------

class _MockSagaNotifier extends SagaNotifier {
  @override
  SagaState build() => SagaState(
        xpByLanguage:   const {'es': 120},
        streakCount:    5,
        completedIds:   {'puzzle-es-01', 'puzzle-es-02'},
        revealPowerups: 1,
        lastActiveDate: '2026-05-17',
        isLoading:      false,
      );
}

class _MockSagaEmpty extends SagaNotifier {
  @override
  SagaState build() => const SagaState(isLoading: false);
}

class _MockLanguageNotifier extends LanguageNotifier {
  @override
  Language build() => kLanguages.firstWhere((l) => l.code == 'es');
}

class _MockDailyGoalNotifier extends DailyGoalNotifier {
  @override
  DailyGoalState build() =>
      const DailyGoalState(xpToday: 10, goalXp: 20, goalMet: false);
}

class _MockReviewEmpty extends ReviewNotifier {
  @override
  List<ReviewItem> build() => [];
}

class _MockReviewWithItems extends ReviewNotifier {
  @override
  List<ReviewItem> build() => [
        ReviewItem(
          question: const MultipleChoiceQuestion(
            id:           'q-test-01',
            lessonId:     'lesson-test',
            prompt:       '¿Cómo se dice "hello" en español?',
            options:      ['Hola', 'Adiós', 'Gracias', 'Por favor'],
            correctIndex: 0,
            cefrLevel:    'A1',
            skillTag:     'vocabulary/greetings',
          ),
          savedAt:        DateTime(2026, 5, 15),
          courseLanguage: 'es',
        ),
      ];
}

class _MockLessonNotifier extends LessonNotifier {
  @override
  LessonState build() => LessonState(
        lesson:      kLessonsByLanguage['es']!.first,
        isGenerating: false,
      );

  @override
  Future<void> generateInitialLesson() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<Override> get _mockOverrides => [
      sagaProvider.overrideWith(_MockSagaNotifier.new),
      languageProvider.overrideWith(_MockLanguageNotifier.new),
      dailyGoalProvider.overrideWith(_MockDailyGoalNotifier.new),
      reviewProvider.overrideWith(_MockReviewEmpty.new),
      lessonProvider.overrideWith(_MockLessonNotifier.new),
    ];

Widget testApp(Widget home, {List<Override> extra = const []}) =>
    ProviderScope(
      overrides: [..._mockOverrides, ...extra],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: home,
      ),
    );

// Pumps enough frames to render the widget without waiting for infinite
// repeat() animations to settle (they never would).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url:     'https://placeholder.supabase.co',
        anonKey: 'placeholder-anon-key',
      );
    } catch (_) {}
  });

  // ── 1. Navigation ─────────────────────────────────────────────────────────

  group('Navigation — 5 tabs', () {
    testWidgets('Alla 5 tab-labels visas i NavigationBar', (tester) async {
      await tester.pumpWidget(testApp(const MainScreen()));
      await settle(tester);

      expect(find.text('Home'),    findsOneWidget);
      expect(find.text('Learn'),   findsOneWidget);
      expect(find.text('Review'),  findsOneWidget);
      expect(find.text('Path'),    findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('NavigationBar renderas korrekt', (tester) async {
      await tester.pumpWidget(testApp(const MainScreen()));
      await settle(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('Tap på Review-tab navigerar till ReviewScreen', (tester) async {
      await tester.pumpWidget(testApp(const MainScreen()));
      await settle(tester);

      await tester.tap(find.text('Review'));
      await settle(tester);

      expect(find.text('No items to review!'), findsOneWidget);
    });

    testWidgets('Tap på Path-tab visar Journey-appbar', (tester) async {
      await tester.pumpWidget(testApp(const MainScreen()));
      await settle(tester);

      await tester.tap(find.text('Path'));
      await settle(tester);

      expect(find.text('Journey'), findsOneWidget);
    });

    testWidgets('Tap på Home efter Path återgår till Home', (tester) async {
      await tester.pumpWidget(testApp(const MainScreen()));
      await settle(tester);

      await tester.tap(find.text('Path'));
      await settle(tester);
      await tester.tap(find.text('Home'));
      await settle(tester);

      expect(find.text('Learn'),  findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });
  });

  // ── 2. Review-skärmen ─────────────────────────────────────────────────────

  group('ReviewScreen', () {
    testWidgets('Tom kö: visar fira-emoji och rätt text', (tester) async {
      await tester.pumpWidget(testApp(const ReviewScreen()));
      await settle(tester);

      expect(find.text('🎉'),                      findsOneWidget);
      expect(find.text('No items to review!'),     findsOneWidget);
      expect(find.textContaining('Complete more'), findsOneWidget);
    });

    testWidgets('Med items: visar fråga och review-header', (tester) async {
      await tester.pumpWidget(testApp(
        const ReviewScreen(),
        extra: [reviewProvider.overrideWith(_MockReviewWithItems.new)],
      ));
      await settle(tester);

      expect(find.textContaining('Review ('), findsOneWidget);
      expect(find.text('🔁 Spaced review'),   findsOneWidget);
    });

    testWidgets('Med items: visar fråge-prompt', (tester) async {
      await tester.pumpWidget(testApp(
        const ReviewScreen(),
        extra: [reviewProvider.overrideWith(_MockReviewWithItems.new)],
      ));
      await settle(tester);

      expect(find.textContaining('hello'), findsOneWidget);
    });

    testWidgets('Med items: visar 4 svarsalternativ', (tester) async {
      await tester.pumpWidget(testApp(
        const ReviewScreen(),
        extra: [reviewProvider.overrideWith(_MockReviewWithItems.new)],
      ));
      await settle(tester);

      expect(find.text('Hola'),      findsOneWidget);
      expect(find.text('Adiós'),     findsOneWidget);
      expect(find.text('Gracias'),   findsOneWidget);
      expect(find.text('Por favor'), findsOneWidget);
    });

    testWidgets('Rätt svar tar bort item ur kön', (tester) async {
      await tester.pumpWidget(testApp(
        const ReviewScreen(),
        extra: [reviewProvider.overrideWith(_MockReviewWithItems.new)],
      ));
      await settle(tester);

      await tester.tap(find.text('Hola'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('No items to review!'), findsOneWidget);
    });
  });

  // ── 3. SagaMapScreen (Path) ───────────────────────────────────────────────

  group('SagaMapScreen — Path', () {
    testWidgets('Renderar appbar med Journey-titel', (tester) async {
      await tester.pumpWidget(testApp(const SagaMapScreen()));
      await settle(tester);

      expect(find.text('Journey'), findsOneWidget);
    });

    testWidgets('Visar XP-värde i appbar', (tester) async {
      await tester.pumpWidget(testApp(const SagaMapScreen()));
      await settle(tester);

      expect(find.textContaining('XP'), findsWidgets);
    });

    testWidgets('Visar Spanska-flaggan i header', (tester) async {
      await tester.pumpWidget(testApp(const SagaMapScreen()));
      await settle(tester);

      expect(find.text('🇪🇸'), findsOneWidget);
    });

    testWidgets('Renderar utan crash med tom saga-state', (tester) async {
      await tester.pumpWidget(testApp(
        const SagaMapScreen(),
        extra: [sagaProvider.overrideWith(_MockSagaEmpty.new)],
      ));
      await settle(tester);

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  // ── 4. Review badge ───────────────────────────────────────────────────────

  group('Review badge', () {
    testWidgets('Ingen badge när review-kö är tom', (tester) async {
      await tester.pumpWidget(testApp(const MainScreen()));
      await settle(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('Badge "1" visas när review-kö har ett item', (tester) async {
      await tester.pumpWidget(testApp(
        const MainScreen(),
        extra: [reviewProvider.overrideWith(_MockReviewWithItems.new)],
      ));
      await settle(tester);

      expect(find.text('1'), findsOneWidget);
    });
  });

  // ── 6. Responsivitet ──────────────────────────────────────────────────────

  group('Responsivitet', () {
    testWidgets('Mobil 375px: NavigationBar visas', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const MainScreen()));
      await settle(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('Tablet 768px: NavigationBar visas', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const MainScreen()));
      await settle(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  // ── 7. Smoke test ─────────────────────────────────────────────────────────

  group('Smoke tests', () {
    testWidgets('Alla 5 tabs renderar utan crash', (tester) async {
      await tester.pumpWidget(testApp(const MainScreen()));
      await settle(tester);

      for (final tab in ['Home', 'Learn', 'Review', 'Path', 'Profile']) {
        await tester.tap(find.text(tab));
        await settle(tester);
        expect(find.byType(Scaffold), findsWidgets,
            reason: 'Tab $tab ska rendera en Scaffold');
      }
    });
  });
}
