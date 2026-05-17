# Axiom — Tech Stack & Data Architecture
*Version 1.0 | 2026-05-17*

---

## Översikt

Axiom är en AI-driven språkinlärningsapp (Flutter) med en modern cloud-native arkitektur. Systemet består av fem lager som kommunicerar med varandra i ett tydligt dataflöde: från användarinteraktion i appen → realtidslagring i Supabase → analytikexport till BigQuery → framtida business intelligence.

```
┌─────────────────────────────────────────────────────────────┐
│                      AXIOM ECOSYSTEM                        │
│                                                             │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐              │
│  │  Flutter  │───▶│ Supabase │───▶│ BigQuery │              │
│  │   App     │    │ (DB+Auth)│    │  (GCP)   │              │
│  └──────────┘    └──────────┘    └──────────┘              │
│       │                │               ▲                    │
│       │          ┌─────┘               │                    │
│       ▼          ▼                     │                    │
│  ┌──────────┐  ┌──────────┐    ┌──────────────┐           │
│  │  Gemini  │  │ Vercel   │    │ GitHub       │           │
│  │ 2.5 Flash│  │  Proxy   │    │ Actions (CI) │           │
│  └──────────┘  └──────────┘    └──────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

---

## 1. Frontend — Flutter (Dart)

### Plattform
- **Framework:** Flutter 3.22+ (Dart SDK ≥3.3.0)
- **Targets:** Web (Chrome/Edge), Windows Desktop — iOS/Android planerat
- **App-ID:** `axiom`

### Arkitektur
Axiom använder **Riverpod** för state management med ett provider-baserat mönster. Varje feature-area har en dedikerad `Notifier` som äger sin state och synkroniserar med Supabase.

```
UI Widgets
   └── ConsumerWidget / ConsumerStatefulWidget
         └── ref.watch(provider)
               └── Notifier<State>
                     ├── SharedPreferences (lokal cache)
                     └── Supabase (remote sync)
```

### Nyckelbibliotek

| Bibliotek | Version | Syfte |
|-----------|---------|-------|
| `flutter_riverpod` | ^2.5.1 | State management |
| `supabase_flutter` | ^2.12.4 | Backend-integration |
| `flick_sdk` | (lokal path) | Event tracking, AI-bridge, SQLite-buffer |
| `flutter_animate` | ^4.5.0 | Animationer |
| `flutter_secure_storage` | ^9.2.2 | Krypterad lokal lagring (API-nycklar) |
| `shared_preferences` | ^2.2.3 | Lokal cache (XP, streak, inställningar) |
| `speech_to_text` | ^6.6.0 | Taligenkänning (Speaking-frågor) |
| `url_launcher` | ^6.3.0 | Djuplänkar (Google AI Studio) |
| `image_picker` | ^1.1.2 | Profilbild |

### Primära skärmar och flöde

```
AuthGateScreen
   ├── [Ej inloggad] → OnboardingScreen (6 steg)
   │     ├── Steg 1: Välkommen
   │     ├── Steg 2: Hur det fungerar
   │     ├── Steg 3: Välj språk
   │     ├── Steg 4: Dagligt mål (10/20/50 XP)
   │     ├── Steg 5: Gemini API-nyckel (valfri)
   │     └── Steg 6: Samtycke (GDPR) → MainScreen
   └── [Inloggad] → MainScreen (5 tabs)
         ├── Home — daglig XP, Word of Day, AI Practice
         ├── Learn — DailyLessonScreen (AI-genererade lektioner)
         ├── Review — Spaced repetition (fel från lektioner)
         ├── Path — SagaMapScreen (Candy Crush-inspirerad)
         └── Profile — XP-stats, vänner, privacy settings
```

---

## 2. Backend — Supabase

### Tjänster
- **PostgreSQL** (version 17.6) — primär databas, region: EU Central (Frankfurt)
- **Supabase Auth** — användarhantering (anonymt + e-post)
- **Supabase Storage** — avatar-bilder (`axiom`-bucket)
- **Row Level Security (RLS)** — all data är row-isolerad per user

### Databastabeller

| Tabell | Syfte | RLS |
|--------|-------|-----|
| `users` | Användarprofil, XP, streak, engagemangstier | ✅ Egna rader |
| `events` | Immutable analytics-log (append-only) | ✅ Insert-only |
| `consent_log` | GDPR-samtycke, versionshanterat | ✅ Egna rader, ej raderbart |
| `global_questions` | Delad frågebank (AI-genererade) | ✅ Insert = auth.uid() |
| `user_progress` | Svar per fråga (spaced repetition-kalibrering) | ✅ Egna rader |
| `friend_requests` | Väntande/accepterade vänförfrågningar | ✅ From/to-uid |
| `user_friends` | Bidirektionala vänskapsrelationer | ✅ Egna rader |
| `data_sharing_log` | Audit-logg för B2B-dataexporter | 🔒 Service role only |

### Supabase RPC-funktioner (säkra profil-lookups)

```sql
-- Returnerar ENBART icke-känsliga fält (id, name, photo_url, total_xp)
get_user_profiles(ids uuid[])   -- Används av FriendService
search_users(search_query text) -- Används av friend-sökning
```

---

## 3. AI-lager — Gemini + Vercel Proxy

### Gemini 2.5 Flash
Axiom använder Google Gemini 2.5 Flash för tre ändamål:
1. **Lektionsgenerering** — AI-genererade frågor anpassade till CEFR-nivå och språk
2. **Puzzle-generering** — ordpar för matchningspussel på nya språk
3. **AI-tutor** — multi-turn konversation i Speaking-övningar

### API-nyckelstrategi (3-nivåers)

```
Prioritet 1: Compile-time nyckel (GEMINI_API_KEY env var)
Prioritet 2: Användarens egna nyckel (flutter_secure_storage + Supabase users.gemini_key)
Prioritet 3: Server-side nyckel via Vercel-proxy (standard)
```

### Vercel CORS-proxy
Gemini API blockeras av CORS på webb. En Vercel serverless-funktion fungerar som proxy:

```
Flutter app
   └── GeminiBridge(proxyUrl: 'https://proxy-taupe-eight-41.vercel.app')
         └── POST /api/gemini
               └── Vercel Edge Function
                     └── Gemini 2.5 Flash API
```

### Crowdsourcing-flöde (frågebibliotek)

Användare som lägger till sin egna Gemini-nyckel bidrar automatiskt till den delade frågebanken efter varje avslutad lektion:

```
Lektion klar
   └── QuestionContributorService.contributeAfterLesson()
         └── GeminiBridge med användarens nyckel
               └── Genererar 8 frågor (60% MC, 40% ordordning)
                     └── QuestionLibraryService.saveQuestions()
                           └── Supabase: global_questions
```

---

## 4. Eventspårning — flick_sdk + EventSensor

### Arkitektur
`flick_sdk` (lokalt paket) hanterar event-insamling med en offline-first-strategi:

```
EventSensor.instance.emit('lesson_completed', payload)
   └── SQLiteEventBuffer (lokal kö på enheten)
         └── SupabaseSyncService.sync() [vid app-start + bakgrund]
               └── [Kontrollerar GDPR-samtycke]
                     └── Batch INSERT → Supabase events-tabell (max 250/batch)
```

### Spårade event-typer

| Event | Trigger | Nyckel-payload |
|-------|---------|----------------|
| `app_opened` | App-start | `platform, hour_of_day, day_of_week` |
| `session_ended` | App till bakgrund | `duration_seconds, hour_of_day` |
| `onboarding_completed` | Onboarding klar | `consent_anonymous_stats, consent_partner_profile` |
| `language_selected` | Språkbyte | `language_code, is_first_time` |
| `lesson_started` | Lektionsstart | `lesson_id, language_code, cefr_level` |
| `answer_submitted` | Svar | `is_correct, question_type` |
| `lesson_completed` | Lektion klar | `xp_earned, accuracy_pct, duration_seconds` |
| `ai_practice_completed` | AI Practice klar | `xp_earned, accuracy_pct, question_count` |
| `puzzle_completed` | Pussel klart | `level_id, xp_awarded, time_seconds` |
| `tab_viewed` | Tab-navigation | `tab, hour_of_day` |
| `chat_message_sent` | AI-tutor meddelande | `message_len, turn_number` |
| `heart_lost` | Fel svar | `context (lesson/puzzle/practice)` |

---

## 5. Datapipeline — Python → BigQuery

### Syfte
Exporterar all Supabase-data till Google BigQuery för analytics, business intelligence och (framtida) B2B-dataprodukt.

### Teknisk stack
- **Python 3.11**
- **SQLAlchemy** + **psycopg2-binary** — PostgreSQL-anslutning
- **pandas** — datahantering
- **pandas-gbq** — BigQuery-export
- **python-dotenv** — hemlig konfiguration

### Dataflöde

```
Supabase PostgreSQL (EU Central)
   └── sync_to_bq.py (Python)
         ├── Ansluter via pooler: pooler.supabase.com:5432
         ├── Auto-detekterar alla tabeller (information_schema)
         ├── Läser varje tabell med pandas.read_sql()
         └── Skriver till BigQuery: supabase_raw.{table_name}
               └── Google BigQuery (projekt: axiom-324e3)
                     └── Dataset: supabase_raw
```

### Destinationstabell-format i BigQuery

```
axiom-324e3
└── supabase_raw
      ├── users
      ├── events
      ├── consent_log
      ├── global_questions
      ├── user_progress
      ├── friend_requests
      ├── user_friends
      └── data_sharing_log
```

---

## 6. CI/CD — GitHub Actions

### Repository
`github.com/emilolofandreasson/Axiom`

### Workflows

#### Sync Supabase → BigQuery (`.github/workflows/sync_to_bigquery.yml`)
- **Trigger:** Manuell (workflow_dispatch) via GitHub Actions-tab
- **Runtime:** Ubuntu Latest, Python 3.11
- **Hemligheter:** Lagrade som GitHub Repository Secrets

```yaml
Steg:
  1. Checkout repository
  2. Setup Python 3.11
  3. pip install -r requirements.txt
  4. Skapa secrets.env från GitHub Secrets
  5. Skapa google_creds.json från GCP_CREDENTIALS_JSON secret
  6. python sync_to_bq.py
  7. Rensa secrets-filer (körs alltid, även vid fel)
```

### GitHub Secrets som krävs

| Secret | Innehåll |
|--------|----------|
| `SUPABASE_USER` | `postgres.{project_ref}` |
| `SUPABASE_PASSWORD` | Supabase DB-lösenord |
| `SUPABASE_HOST` | Pooler-URL |
| `BIGQUERY_PROJECT_ID` | GCP projekt-ID |
| `GCP_CREDENTIALS_JSON` | Hela JSON-innehållet från service account-nyckelfil |

---

## 7. Komplett dataflödesdiagram

```
ANVÄNDARE
   │
   ▼
┌──────────────────────────────────────────────────────────────────┐
│  FLUTTER APP (Axiom)                                             │
│                                                                  │
│  Användarinteraktion                                             │
│     └── EventSensor.emit() ──────────────────────────────────┐  │
│                                                               │  │
│  Lektion/Pussel klar                                         │  │
│     └── SagaNotifier._syncToSupabase() ──────────────────┐  │  │
│                                                           │  │  │
│  AI-anrop (lektion/pussel/tutor)                         │  │  │
│     └── GeminiBridge ──────────────────────────────┐    │  │  │
│                                                     │    │  │  │
└─────────────────────────────────────────────────────┼────┼──┼──┘
                                                      │    │  │
                    ┌─────────────────────────────────┘    │  │
                    ▼                                       │  │
         ┌──────────────────┐                              │  │
         │  VERCEL PROXY    │                              │  │
         │  (CORS-brygga)   │                              │  │
         └────────┬─────────┘                              │  │
                  │                                         │  │
                  ▼                                         │  │
         ┌──────────────────┐                              │  │
         │  GEMINI 2.5 FLASH│                              │  │
         │  (Google AI)     │                              │  │
         └──────────────────┘                              │  │
                                                            │  │
                    ┌───────────────────────────────────────┘  │
                    ▼                                           │
         ┌──────────────────────────────────────────────────┐  │
         │  SUPABASE (PostgreSQL, EU Frankfurt)             │  │
         │                                                  │  │
         │  users          ← profil, XP, streak            │  │
         │  events         ← analytics (immutable)  ◀──────┘  │
         │  consent_log    ← GDPR-samtycke                    │
         │  global_questions ← AI-genererade frågor           │
         │  user_progress  ← svarhistorik                     │
         │  friend_*       ← socialt grafer                   │
         └──────────────────────┬───────────────────────────┘
                                │
                    [Manuell trigger via GitHub Actions]
                                │
                    ┌───────────▼───────────┐
                    │  GITHUB ACTIONS (CI)  │
                    │  sync_to_bigquery.yml  │
                    │  Python 3.11          │
                    │  sync_to_bq.py        │
                    └───────────┬───────────┘
                                │
                    ┌───────────▼───────────┐
                    │  GOOGLE BIGQUERY      │
                    │  projekt: axiom-324e3 │
                    │  dataset: supabase_raw│
                    │                       │
                    │  BI / Analytik /      │
                    │  B2B-dataprodukt      │
                    └───────────────────────┘
```

---

## 8. Säkerhet & GDPR

### Säkerhetsprinciper
- **RLS på alla tabeller** — ingen tabell är öppen för cross-user access
- **Känsliga fält exponeras aldrig via API** — `gemini_key`, `birth_year`, `motivation` returneras ej i friend-lookups (se `get_user_profiles()` RPC)
- **Gemini API-nycklar** — lagras krypterat i `flutter_secure_storage` på enheten, aldrig i klartext i koden
- **Trigger-funktioner** — revokerade från `anon`-rollen, kallandebart enbart av `authenticated`
- **Secrets** — aldrig committade till Git; hanteras via GitHub Secrets och lokal `secrets.env` (i `.gitignore`)

### GDPR-efterlevnad
- **Samtycke:** Granulerat (two-purpose) vid onboarding, loggat med version i `consent_log`
- **Återkallelse:** Tillgänglig i Profile → Privacy Settings, skriver ny rad i `consent_log` (immutable audit trail)
- **Dataportabilitet (Art. 20):** JSON-export tillgänglig i Privacy Settings
- **Radering (Art. 17):** Cascade delete via `auth.users` → alla tabeller
- **Event-sync** — blockeras om `anonymous_stats`-samtycke saknas i `consent_log`
- **B2B-exporter** — k-anonymitet ≥10 krävs, inga råa personuppgifter (namn, e-post, exakt ålder)

---

## 9. Lokal utveckling

### Krav
- Flutter 3.22+
- Dart SDK 3.3+
- Supabase-konto (projekt: `oymlddjcusiyaxtfcvad`)
- Python 3.11 (för BigQuery-pipeline)

### Miljövariabler (Flutter)
Konfigureras via `lib/config/env.dart` med `String.fromEnvironment()`:

| Variabel | Syfte | Default |
|----------|-------|---------|
| `PROXY_URL` | Vercel CORS-proxy för Gemini | `https://proxy-taupe-eight-41.vercel.app` |
| `SUPABASE_ANON_KEY` | Supabase publika nyckel | (hårdkodad i env.dart) |
| `GEMINI_API_KEY` | Compile-time Gemini-nyckel | Tom (använder proxy) |
| `HMAC_SALT` | Salt för auth-signering | `dev-salt-change-in-prod` |

### Python-pipeline (lokal körning)
```bash
# 1. Installera beroenden
pip install -r requirements.txt

# 2. Kopiera och fyll i konfiguration
cp secrets.env.example secrets.env
# Redigera secrets.env med dina värden

# 3. Kör sync
python sync_to_bq.py
```

---

*Dokumentation ägd av Emil Olof Andreasson | Axiom Engineering*
