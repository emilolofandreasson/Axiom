# Axiom — Samlad plan efter tre-agent-granskning
*QA · UI/UX · Produkt — 2026-05-10*

---

## Nulägesbedömning

Axiom är en välstrukturerad pre-alpha med fungerande kärnloop: onboarding → AI-genererade lektioner → per-språk XP (10 nivåer) → streak → puzzle-karta. Supabase (Auth + PostgreSQL), Vercel-proxyn och Gemini 2.5 Flash-pipeline är på plats. Största problemen: hearts-mekaniken är byggd men inte påtvingad i spelet, AI-chatten är en hårdkodad stub, XP delas inte ut i AI Practice, och en rad kritiska buggar gör upplevelsen opålitlig vid kant-fall.

---

## FAS 1 — Kritiska buggar (kör direkt, inga nya features)

### 1.1 Kompileringsrisker
| # | Bug | Fil | Fix |
|---|-----|-----|-----|
| B1 | `flutter_secure_storage` saknas i pubspec.yaml | `pubspec.yaml` | Lägg till under `dependencies:` |
| B2 | `value:` deprecated på TextFormField | `edit_profile_screen.dart:194` | Byt till `initialValue:` |
| B3 | Hardcoded `platform: 'web'` i analytics | `main.dart:83–90` | Använd `defaultTargetPlatform` |

### 1.2 Crash-buggar
| # | Bug | Fil | Beskrivning |
|---|-----|-----|-------------|
| B4 | Division med noll i `_accuracy` | `lesson_complete_screen.dart:23` | Guard: `totalCount == 0 ? 0.0 : correctCount / totalCount` |
| B5 | `nextLesson()` anropar `startLesson()` ovillkorligt | `lesson_provider.dart:168` | Ta bort `startLesson()` från `nextLesson()` — låt intro-skärmen driva det |
| B6 | `_ConfettiBurst` läcker AnimationController | `lesson_complete_screen.dart:259` | Konvertera till StatefulWidget med dispose |
| B7 | `signInAnonymously` force-unwrappar `cred.user!` | `auth_service.dart:28` | Hantera null-case |

### 1.3 Logic-buggar med tydlig användareffekt
| # | Bug | Fil | Beskrivning |
|---|-----|-----|-------------|
| B8 | Hearts-refill trunkerar till hela timmar — laddar aldrig på | `hearts_provider.dart:39–48` | Räkna minuter: `inMinutes ~/ 60` med rest → rätt nästa refill-tid |
| B9 | Streak nollas vid app-öppning NYA dagar, INNAN lektion | `saga_provider.dart:184` | Nolla streak bara om INGET hände igår, inte proaktivt vid load |
| B10 | `completeLevel` kan inkrementera streak IGEN samma dag | `saga_provider.dart:245` | Lägg till `lastActiveDate == today`-guard som i `awardLessonXp` |
| B11 | AI Practice: inga hjärtan dras vid fel svar | `ai_practice_provider.dart:105` | Anropa `heartsProvider.notifier.loseHeart()` på `!isCorrect` |
| B12 | AI Practice: inget XP delas ut vid avslut | `ai_practice_provider.dart:130` | Anropa `awardLessonXp` + `dailyGoalProvider.addXp()` i `advance()` |
| B13 | AI Practice progress bar hoppar till 100% på sista frågan | `ai_practice_screen.dart:257` | Byt `(currentIndex + 1) / total` → `currentIndex / total` |
| B14 | `LessonState.progressFraction` når aldrig 1.0 | `lesson_provider.dart:57` | Byt till `(currentIndex + 1) / totalQuestions` |
| B15 | `WordOrderQuestion` validerar inte AI-index mot ordlängd | `lesson_generator.dart:135` | Filtrera index `>= words.length` innan konstruktion |
| B16 | `AuthGateScreen` navigerar till MainScreen oavsett auth-resultat | `auth_gate_screen.dart:104–136` | Kolla `authService.currentUser != null` innan push |
| B17 | `DailyGoalNotifier._todayKey` använder opadded datum | `daily_goal_provider.dart:52` | `padLeft(2,'0')` på månad och dag (matcha SagaNotifier) |
| B18 | `HomeScreen.initState` genererar ny lektion vid varje navigation | `home_screen.dart:48` | Guard: generera bara om `!isGenerating && !lesson.isAiGenerated` |

---

## FAS 2 — Halvfärdiga features (slutför befintliga mekaniker)

### 2.1 Hearts-enforcement (byggt men inte påtvingat)
- Visa "0 hjärtan"-blockerande skärm i `_LessonIntroScreen` med nedräkning från `heartsState.timeUntilRefill`
- I `lesson_provider.submitAnswer()`: kolla `heartsProvider.isEmpty` → ny status `LessonStatus.outOfHearts` → routing till hjärtan-skärm
- Visa hjärtan-nedräkningsuret i `_LessonAppBar` när `hearts < max`

### 2.2 AI-chat / Speaking Questions (hårdkodad stub)
- Ersätt `_sendToEdgeAI()` i `ai_chat_panel.dart` med riktig Gemini-anrop via proxy
- System prompt: `question.conversationContext` (redan korrekt format)
- Mic-knapp: implementera `speech_to_text`-paket ELLER ta bort knappen tills klar

### 2.3 Saga Map – "nuvarande nivå"-markering
- Introducera `isCurrent`-logik: första olåsta ej-avklarade nivå
- Rendera med pulserande `FlickColors.primary`-ring
- Uppdatera subtitle från hårdkodad "Beginner path · A1–A2" till `levelLabelForXp(langXp)`

### 2.4 Puzzle XP och analytics-diskrepans
- `puzzle_screen.dart`: använd en källa för XP-belöning (antingen `widget.level.xpReward` ELLER `levelForXp()`, inte båda)
- Skicka exakt awarded XP i analytics-eventet

### 2.5 17 språk med saknat puzzle-innehåll
- Alternativ A: Generera puzzle-nivåer via Gemini första gången ett språk väljs, spara i Supabase
- Alternativ B (snabb): Märk oinnehållsrika språk som "Coming soon" på puzzle-kartan men håll lektion/AI Practice aktiva (de fungerar redan via AI)

---

## FAS 3 — UX-polish (före publik lansering)

### 3.1 Kritiska UX-buggar (P0/P1)
| Screen | Problem | Fix |
|--------|---------|-----|
| Alla skärmar | 10+ `withOpacity()` deprecated | Global replace → `withValues(alpha:)` |
| Auth Gate | "Fortsätt som gäst" — kontrast 2.4:1 (WCAG fail) | Använd `textSecondary` eller lägg till underline |
| Onboarding | Ingen back-navigation på sida 3 om fel språk valdes | Aktivera swipe-back eller lägg till back-pil |
| Onboarding | Ingen målsättning (dagligt mål) | Lägg till steg 4: "Hur mycket vill du öva?" |
| Daily Lesson | `_LessonAppBar.preferredSize` = 72 men faktisk höjd ~80 | Öka till `kToolbarHeight + 28` |
| Lesson Complete | "Next lesson" kan avbryta pågående mistake-review | Flytta "Next" nedanför "Review mistakes" visuellt |
| Profile | Debug-knappen "Test database connection" synlig i prod | Gate bakom `kDebugMode` |
| Language Picker | "Coming soon"-språk är klickbara och byter aktivt språk | Inaktivera `onTap` för `!hasContent` |

### 3.2 Viktiga UX-förbättringar (P2)
- **AI Practice**: Tilldela XP (fas 1 fixar detta), lägg till resultatskärm-celebration
- **Lesson Complete**: XP-räknar-animation med `TweenAnimationBuilder<int>` 
- **Lesson Complete**: Visa "Streak förlängd till N dagar!" om streak ökade
- **Lesson Complete**: Återanvänd `ParticleBurst`-widgeten istället för emoji-confetti
- **Home**: Göm "⚡ 0 XP"-pill för nya användare, ersätt med uppmuntrande text
- **Home**: Word of Day – lägg till bottom sheet med exempelmening vid tap
- **Home**: "NEW"-badge på AI Practice försvinner efter första användning
- **Saga Map**: Dashed path-connector med riktningspil (uppåt)
- **Puzzle**: Progress bar `begin: 0` → börja från föregående frågas fraction
- **Puzzle**: Restart-knapp → flytta till kontextmeny (undvik oavsiktliga tap)
- **Puzzle**: Tidformat för `> 60s` → `mm:ss`
- **Navigation**: Bottom nav-bar bakgrund matchar inte page-background (vit vs lavender-cream)

### 3.3 Accessibility (P2)
- Ersätt `GestureDetector` → `InkWell` eller lägg till `Semantics`-wrapper på alla interaktiva kort
- Lägg till minsta tap-yta 44×44px på `_HintChip`
- Lägg till `overflow: TextOverflow.ellipsis` på texter i trånga Row-layouts

---

## FAS 4 — Tillväxtfeatures (efter stabil grund)

### 4.1 Retention (högst impact)
1. **Push-notifikationer** — "Din 5-dagars streak är i fara!" via Supabase Realtime + Edge Functions
2. **Streak Shield** — skyddsmekanik för missade dagar, köps/tjänas som reward
3. **Spaced Repetition** — fel svar från `wrongAnswers` sparas och återkommer som "Review"-läge
4. **Dagligt mål konfigurerbart** — användaren väljer 10/20/50 XP, inte hårdkodat 20

### 4.2 Social
5. **Vän-leaderboard (vecko-XP)** — `FriendsScreen` finns, lägg till ranking-widget på home
6. **Nivå-up celebration** — interstitial-skärm när `levelForXp` byter nivå (t.ex. A1.2 → A2.1)
7. **Delbart progress-kort** — generera en bild "Jag är nu B1.1 i spanska!"

### 4.3 Content och AI
8. **Riktig AI-konversationstutor** — multi-turn Gemini-session med CEFR-kontext
9. **AI-genererade puzzle-nivåer** — Gemini genererar ordpar per språk vid första val
10. **Uttal / speaking mode** — `speech_to_text` + scoring av svar

---

## Teknisk skuld att adressera

| Skuld | Prioritet | Fix |
|-------|----------|-----|
| `lessonGenerator` är global mutable — omöjlig att testa | Hög | Gör till Riverpod-provider |
| `unawaited()` är en hand-rullad no-op | Medium | Importera `dart:async show unawaited` |
| `SupabaseSyncService` syncas bara vid cold start | Medium | `Timer.periodic(5 min)` eller lifecycle-trigger |
| `SagaNotifier` anropar Supabase direkt — otestbar | Medium | Extrahera `SagaRepository`-abstraktion |
| Gemini API-nyckel lagras i klartext i Supabase | Medium | Ta bort databas-lagring, device-only via secure storage |
| Proxy saknar autentisering — vem som helst kan anropa | Hög | Lägg till HMAC-token eller Supabase JWT-check |
| `kPuzzleLevelsByLanguage` är compile-time konstant | Låg | Flytta till Supabase för OTA-uppdateringar |
| `SagaNotifier` → `AsyncNotifier<SagaState>` | Medium | Representera loading-state korrekt för UI |

---

## Föreslagen körordning

```
Fas 1 (nu)   →  Fas 2.1 (hearts) + 2.2 (AI-chat)  →  Fas 3.1 + 3.2
     ↓                      ↓                                ↓
  ~1 dag              ~2–3 dagar                        ~3–4 dagar

Fas 4 (post-stabil grund, iterativt)
```

**Fas 1 bör köras i ett svep** — alla är enbladsfixar utan designbeslut.
**Fas 2 kräver diskussion** om hearts-design (blockerar? timeout?) och AI-chat-strategi.
**Fas 3 kan parallelliseras** mellan UI-arbete och feature-arbete.

---

*Godkänn denna plan → agenterna kör Fas 1 automatiskt och presenterar Fas 2 för beslut.*
