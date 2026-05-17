// integration_test/app_test.dart
//
// Axiom QA Integration Tests
// Run with: flutter test integration_test/app_test.dart -d chrome
//
// Provider overrides inject mock data — no live Supabase connection needed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:axiom/core/theme/app_theme.dart';
import 'package:axiom/models/language.dart';
import 'package:axiom/models/question.dart';
import 'package:axiom/providers/daily_goal_provider.dart';
import 'package:axiom/providers/hearts_provider.dart';
import 'package:axiom/providers/language_provider.dart';
import 'package:axiom/providers/lesson_provider.dart';
import 'package:axiom/providers/review_provider.dart';
import 'package:axiom/models/lesson.dart';
import 'package:axiom/providers/saga_provider.dart';
import 'package:axiom/screens/main_screen.dart';
import 'package:axiom/screens/review_screen.dart';
import 'package:axiom/screens/saga_map_screen.dart';

// ---------------------------------------------------------------------------
// Mock Notifiers — extend real classes, override build() with mock data
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

class _MockHeartsNotifier extends HeartsNotifier {
  @override
  HeartsState build() => const HeartsState(hearts: kMaxHearts);
}

class _MockHeartsEmpty extends HeartsNotifier {
  @override
  HeartsState build() => HeartsState(
        hearts:   0,
        refillAt: DateTime.now().add(const Duration(hours: 1)),
      );
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
}

// ---------------------------------------------------------------------------
// Test helper
// ---------------------------------------------------------------------------

/// Standard provider overrides for all tests.
List<Override> get _mockOverrides => [
      sagaProvider.overrideWith(_MockSagaNotifier.new),
      heartsProvider.overrideWith(_MockHeartsNotifier.new),
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Supabase with placeholder credentials.
    // Real API calls are blocked by provider overrides — only the client
    // object needs to exist for screens that reference authService.
    try {
      await Supabase.initialize(
        url:     'https://placeholder.supabase.co',
        anonKey: 'placeholder-anon-key',
      );
    } catch (_) {
      // Already initialized (test runner reuse) — safe to ignore.
    }
  });

  // ── 1. Navigation ─────────────────────────────────────────────────────────

  group('Navigation — 5 tabs', () {
    testWidgets('Alla 5 tab-labels visas i NavigationBar', (tester) async {
      await tester.pumpWidget(testApp(const MainScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Home'),    findsOneWidget);
      expect(find.text('Learn'),   findsOneWidget);
      expect(find.text('Review'),  findsOneWidget);
      expect(find.text('Path'),    findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('NavigationBar renderas korrekt', (tester) async {
      await tester.pumpWidget(testApp(const MainScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('Tap på Review-tab navigerar till ReviewScreen', (tester) async {
      await tester.pumpWidget(testApp(const MainScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();

      expect(find.text('No items to review!'), findsOneWidget);
    });

    testWidgets('Tap på Path-tab visar Journey-appbar', (tester) async {
      await tester.pumpWidget(testApp(const MainScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Path'));
      await tester.pumpAndSettle();

      expect(find.text('Journey'), findsOneWidget);
    });

    testWidgets('Tap på Home efter Path återgår till Home', (tester) async {
      await tester.pumpWidget(testApp(const MainScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Path'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.text('Learn'),  findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });
  });

  // ── 2. Review-skärmen ─────────────────────────────────────────────────────

  group('ReviewScreen', () {
    testWidgets('Tom kö: visar fira-emoji och rätt text', (tester) async {
      await tester.pumpWidget(testApp(const ReviewScreen()));
      await tester.pumpAndSettle();

      expect(find.text('🎉'),                    findsOneWidget);
      expect(find.text('No items to review!'),   findsOneWidget);
      expect(find.textContaining('Complete more'), findsOneWidget);
    });

    testWidgets('Med items: visar fråga och review-header', (tester) async {
      await tester.pumpWidget(testApp(
        const ReviewScreen(),
        extra: [reviewProvider.overrideWith(_MockReviewWithItems.new)],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Review ('), findsOneWidget);
      expect(find.text('🔁 Spaced review'),   findsOneWidget);
    });

    testWidgets('Med items: visar fråge-prompt', (tester) async {
      await tester.pumpWidget(testApp(
        const ReviewScreen(),
        extra: [reviewProvider.overrideWith(_MockReviewWithItems.new)],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('hello'), findsOneWidget);
    });

    testWidgets('Med items: visar 4 svarsalternativ', (tester) async {
      await tester.pumpWidget(testApp(
        const ReviewScreen(),
        extra: [reviewProvider.overrideWith(_MockReviewWithItems.new)],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hola'),      findsOneWidget);
      expect(find.text('Adiós'),     findsOneWidget);
      expect(find.text('Gracias'),   findsOneWidget);
      expect(find.text('Por favor'), findsOneWidget);
    });

    testWidgets('Rätt svar visar grön feedback och tar bort item', (tester) async {
      await tester.pumpWidget(testApp(
        const ReviewScreen(),
        extra: [reviewProvider.overrideWith(_MockReviewWithItems.new)],
      ));
      await tester.pumpAndSettle();

      // Tap på rätt svar (Hola)
      await tester.tap(find.text('Hola'));
      await tester.pumpAndSettle();

      // Feedback-animation spelar
      await tester.pump(const Duration(milliseconds: 500));

      // Efter 1.2s ska item tas bort
      await tester.pumpAndSettle(const Duration(milliseconds: 1500));

      expect(find.text('No items to review!'), findsOneWidget);
    });
  });

  // ── 3. SagaMapScreen (Path) ───────────────────────────────────────────────

  group('SagaMapScreen — Path', () {
    testWidgets('Renderar appbar med Journey-titel', (tester) async {
      await tester.pumpWidget(testApp(const SagaMapScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Journey'), findsOneWidget);
    });

    testWidgets('Visar XP-värde i appbar', (tester) async {
      await tester.pumpWidget(testApp(const SagaMapScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.textContaining('XP'), findsWidgets);
    });

    testWidgets('Visar Spanska-flaggan i header', (tester) async {
      await tester.pumpWidget(testApp(const SagaMapScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('🇪🇸'), findsOneWidget);
    });

    testWidgets('Renderar utan crash med tom saga-state', (tester) async {
      await tester.pumpWidget(testApp(
        const SagaMapScreen(),
        extra: [sagaProvider.overrideWith(_MockSagaEmpty.new)],
      ));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  // ── 4. Hearts ─────────────────────────────────────────────────────────────

  group('Hearts', () {
    testWidgets('Fulla hjärtan: app startar korrekt', (tester) async {
      await tester.pumpWidget(testApp(const MainScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('Tomma hjärtan: app kraschar ej', (tester) async {
      await tester.pumpWidget(testApp(
        const MainScreen(),
        extra: [heartsProvider.overrideWith(_MockHeartsEmpty.new)],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  // ── 5. Review badge ───────────────────────────────────────────────────────

  group('Review badge', () {
    testWidgets('Ingen badge när review-kö är tom', (tester) async {
      await tester.pumpWidget(testApp(const MainScreen()));
      await tester.pumpAndSettle();

      // NavigationBar finns
      expect(find.byType(NavigationBar), findsOneWidget);
      // Badge visas ej som text
      expect(find.text('1'), findsNothing);
    });

    testWidgets('Badge "1" visas när review-kö har ett item', (tester) async {
      await tester.pumpWidget(testApp(
        const MainScreen(),
        extra: [reviewProvider.overrideWith(_MockReviewWithItems.new)],
      ));
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('Tablet 768px: NavigationBar visas', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testApp(const MainScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  // ── 7. Smoke test — ingen crash ───────────────────────────────────────────

  group('Smoke tests', () {
    testWidgets('App renderar utan uncaught exceptions', (tester) async {
      final List<String> errors = [];
      FlutterError.onError = (details) {
        errors.add(details.exception.toString());
      };

      await tester.pumpWidget(testApp(const MainScreen()));
      await tester.pumpAndSettle();

      expect(errors.where((e) => !e.contains('setState')), isEmpty);
    });

    testWidgets('Alla 5 tabs renderar utan crash', (tester) async {
      await tester.pumpWidget(testApp(const MainScreen()));
      await tester.pumpAndSettle();

      for (final tab in ['Home', 'Learn', 'Review', 'Path', 'Profile']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(find.byType(Scaffold), findsWidgets,
            reason: 'Tab $tab ska rendera en Scaffold');
      }
    });
  });
}
