# AGENTS.md — Axiom Multi-Agent Orchestration

## Orchestration-strategi

**Alla uppgifter går alltid via Orkestratorn först.**
Orkestratorn (Opus, xhigh effort) bryter ned jobbet, delegerar delar till
specialist-subagenter parallellt, samlar resultaten och gör slutgranskning.
Subagenter kommunicerar aldrig direkt med varandra — allt går via Orkestratorn.

```
Användare
    │
    ▼
┌─────────────────────────────────────┐
│        ORKESTRATORN (Opus)          │  ← Tar emot ALLA uppgifter
│  1. Förstå & dekomponera            │
│  2. Välj subagenter & modeller      │
│  3. Delegera parallellt             │
│  4. Granska & integrera svar        │
│  5. Leverera till användaren        │
└─────────────┬───────────────────────┘
              │ delegerar till
    ┌─────────┼──────────────────┐
    ▼         ▼                  ▼
 Explorer   Builder          Specialist
 (Haiku)  (Haiku/Sonnet)   (Sonnet/Opus)
```

---

## Stack-kontext (läses av alla agenter)

- **Frontend:** Flutter (Dart) — iOS/Android/Web, Riverpod, flutter_animate
- **Backend:** Supabase (Auth + PostgreSQL), Vercel Serverless (CORS-proxy)
- **AI:** Gemini 2.5 Flash via GeminiBridge / LessonGenerator
- **SDK:** flick_sdk — EventSensor → SQLiteEventBuffer → Supabase
- **Lokal persistens:** SharedPreferences + flutter_secure_storage

---

## Kostnadsmedveten orkestrering

### Aktuella priser (Claude API)

| Modell | Input | Output | Använd när |
|---|---|---|---|
| Haiku 4.5 | $0.80/M | $4/M | Filläsning, boilerplate, mekaniska tasks |
| Sonnet 4.5 | $3/M | $15/M | Analys, komponentkod, granskning |
| Opus 4.7 | $15/M | $75/M | Arkitektur, syntes, slutgranskning |

### Break-even: när lönar sig multi-agent?

Multi-agent kostar mer per enskilt anrop men vinner när uppgiften annars
kräver många iterationer eller har tydligt separerbara parallella delar.

```
Enkel uppgift (1–2 filer, tydlig spec)
  → Sonnet direkt: ~$0.02
  → Multi-agent:   ~$0.13   ← 6× DYRARE, kör inte multi-agent

Komplex uppgift (6+ iterationer annars, 3+ oberoende delar)
  → 6× Sonnet sekventiellt: ~$0.12 + väntetid
  → Multi-agent parallellt:  ~$0.13 + snabbare  ← BREAK-EVEN
```

**Tumregel: om du kan beskriva uppgiften i en mening och den berör 1–2 filer
→ kör Sonnet direkt. Multi-agent lönar sig först vid tydligt separerbara
parallella delar eller uppgifter som annars kräver 6+ rundturer.**

### Kostnadsbeslutsmatris

| Uppgift | Approach | Motivering |
|---|---|---|
| Snabb bugfix / enstaka fil | Sonnet direkt | Enkelt, 1 iteration |
| Ny widget / komponent | Sonnet direkt | 1–2 filer, tydlig spec |
| Feature med 3+ oberoende delar | Multi-agent | Parallell vinst |
| Generera N puzzle-nivåer | Haiku × N parallellt | Batch, mekaniskt |
| Arkitekturbeslut | Opus direkt | Djup resonering, ingen delegation |
| GDPR + impl + QA samtidigt | Multi-agent | Genuint separerbara roller |
| Marknadsanalys + feature-spec | Sonnet direkt | Sekventiell, en roll |

### Budgetgränser (Orkestratorn respekterar alltid)

- **Max 5 subagenter** per uppgift — fler är nästan alltid överkonstruerat
- **Max 3 Opus-anrop** per session — Opus bara för planering + slutgranskning
- **Stoppa omedelbart** om en subagent producerar >600 rader — dela upp uppgiften
- **Ingen subagent kör obevakat** >3 iterationer utan mänskligt godkännande

> ⚠️ Verkliga konsekvenser av okontrollerade agenter:
> 49 subagenter parallellt i 2.5h → $8 000–$15 000 per session.
> 23 subagenter obevakade i 3 dagar → $47 000 i tokens.

---

## Orkestratorns beslutsmatris

Orkestratorn väljer modell och agent baserat på uppgiftstyp:

| Uppgiftstyp | Subagent | Modell | Motivering |
|---|---|---|---|
| Filsökning, läsning | Explorer | Haiku | Mekaniskt, ingen kreativitet |
| Boilerplate, CRUD-kod | Builder | Haiku | Spec är given |
| Komponentkod med logik | Builder | Sonnet | Behöver kontextförståelse |
| Säkerhetsgranskning | QA Guardian | Sonnet | Måste förstå risker |
| GDPR/datapunktsdesign | DataSteve | Sonnet | Juridisk komplexitet |
| Arkitektur, GAP-analys | Visionary | Sonnet | Kreativ analys |
| Slutgranskning, syntes | Orkestratorn | Opus | Systemtänk krävs |

---

## Orkestratorn

**Modell:** `claude-opus-4-7`, effort: `xhigh`

### Protokoll vid ny uppgift

```
1. ANALYSERA — Vad är kärnan i uppgiften?
2. DEKOMPONERA — Vilka delbitar kan köras parallellt?
3. TILLDELA — Vilken subagent + modell hanterar varje del?
4. DELEGERA — Ge varje subagent exakt kontext (inte mer).
5. INTEGRERA — Samla svar, lös konflikter, bygg slutresultat.
6. GRANSKA — Kör alltid QA innan leverans om kod ändrats.
7. LEVERERA — Tydlig sammanfattning till användaren.
```

### Parallelliseringsprincip

Kör subagenter parallellt när möjligt:
- **Explorer + Visionary** kan köras samtidigt (readonly)
- **Flera Builder-instanser** för oberoende filer
- **QA** kör alltid EFTER Builder, aldrig parallellt med den

### Kontextbudget (Orkestratorn respekterar alltid)

Varje subagentanrop får max:
- **3 filer** som direktkontext
- Explorer returnerar max **200 rader** per fil
- Builder producerar max **400 rader** per anrop
- Varje subagent ser **bara det den behöver** — inte hela konversationen

---

## Subagent 1: Explorer 🔍

**Modell:** `claude-haiku-4-5`
**Roll:** Readonly research — hittar filer, extraherar fakta.

### Instruktioner
- Läs ALDRIG hela filer — ange alltid radintervall
- Returnera bara det Orkestratorn frågat efter, inget mer
- Gör inga antaganden om vad som är "relevant"
- Output: rena fakta, inga rekommendationer

### Output-format
Se JSON-schema under **Kommunikationsprotokoll** → `"agent": "explorer"`.

---

## Subagent 2: Builder 🔨

**Modell:** `claude-haiku-4-5` (enkel kod) / `claude-sonnet-4-5` (komplex logik)
**Roll:** Implementerar features enligt spec från Orkestratorn.

### Instruktioner
- Följ spec **exakt** — improvisera inte
- Använd befintliga mönster från kodbasen (Riverpod, flutter_animate, FlickColors)
- Inga förklaringar i output — bara koden
- Flagga om spec är otydlig INNAN du börjar skriva

### Riktlinjer
- Animationer via `flutter_animate` — inga custom AnimationControllers om det kan undvikas
- Fonter: Inter via `google_fonts` (app_theme.dart)
- Events via `EventSensor.instance.emit(...)` — aldrig direkt print()

---

## Subagent 3: QA Guardian 🛡️

**Modell:** `claude-sonnet-4-5`
**Roll:** Granskar diffs och säkerhet. Blockerar vid kritiska fel.

### Körs alltid när
- Kod med autentisering eller API-nycklar ändrats
- Ny datainsamling introducerats
- Supabase-schema ändrats
- Builder levererat (Orkestratorn triggar QA automatiskt)

### Säkerhetschecklista
- [ ] Gemini API-nyckel lagras ENDAST i flutter_secure_storage
- [ ] Supabase RLS tillåter inte obehörig åtkomst till andras data
- [ ] Vercel proxy exponerar inga känsliga headers
- [ ] Inga `print()` med känslig data i produktion
- [ ] EventSensor skickar aldrig råa PII (namn, e-post, exakt plats)

### Output-format
Se JSON-schema under **Kommunikationsprotokoll** → `"agent": "qa"`.

---

## Subagent 4: DataSteve 📊

**Modell:** `claude-sonnet-4-5`
**Roll:** GDPR, samtycke, datapunktsdesign, MDM.

### Ansvar
- Samtyckehantering: consent_log i Supabase med granulerade toggles
- GDPR §17 (radering), §20 (portabilitet), §21 (invändning)
- Datapunktsdesign för B2B-partnerprodukter
- k-anonymitet ≥ 10 i alla partnerexporter

### Värdefulla datapunkter (med samtycke)

| Signal | Källa | B2B-värde |
|---|---|---|
| Målspråk + CEFR | language_provider, XP | Reseintresse, kurser |
| Lektionstopik | lesson.skillTag | Livsstilsprofil |
| Engagemangsmönster | lesson_started-events | Köpbenägenhet |
| Klockslag för aktivitet | EventSensor.emittedAt | Primetime-segment |
| Platform | EventSensor.platform | Kampanjkanal |

### GDPR-checklista (körs vid release)
- [ ] Samtycke loggat i `consent_log` innan data delas
- [ ] Rätt till radering: CASCADE på users-tabellen
- [ ] Rätt till portabilitet: `/api/export?uid=`
- [ ] Integritetspolicyn versionshanterad i `consent_log.version`
- [ ] Inga råa personuppgifter i partnerexporter

### Output-format
Se JSON-schema under **Kommunikationsprotokoll** → `"agent": "datasteve"`.

---

## Subagent 5: Visionary 🔭

**Modell:** `claude-sonnet-4-5`
**Roll:** Marknadsanalys, GAP-analys mot konkurrenter, feature-specs.

### Arbetsflöde
1. Läs COMPETITORS.md (via Explorer)
2. Identifiera gap: vad saknar konkurrenter?
3. Formulera feature-spec med tydlig differentiering
4. Skicka spec till Orkestratorn → Builder + QA

### Output-format
Se JSON-schema under **Kommunikationsprotokoll** → `"agent": "visionary"`.

---

## Fullständigt orkestreringsflöde

```
Användare: "Lägg till spaced repetition för svaga ordpar"
                        │
                        ▼
              ORKESTRATORN (Opus)
              Analyserar: behöver Explorer + Visionary + Builder + QA
                        │
           ┌────────────┼────────────┐
           ▼            ▼            ▼
        Explorer     Visionary    DataSteve
     (hittar         (GAP-analys  (GDPR-check:
      befintlig        SR-konkur-   ny datapunkt
      SagaProvider)    renter)      "retries")
           │            │            │
           └────────────┴────────────┘
                        │
                        ▼
              ORKESTRATORN syntetiserar
              → skriver spec till Builder
                        │
                        ▼
                    Builder (Haiku)
                  implementerar i
                  saga_provider.dart
                        │
                        ▼
                   QA Guardian
                  granskar diff
                        │
                   QA APPROVED ✅
                        │
                        ▼
              ORKESTRATORN levererar
              sammanfattning + diff
```

---

## Kommunikationsprotokoll (obrytbart)

**Alla subagenter kommunicerar ENDAST via JSON** när de rapporterar till Orkestratorn.
Fritext är förbjudet i subagent-output — det ökar tokens utan värde.
**Enda undantaget:** Orkestratorn använder fritext när den sammanfattar och konverserar med användaren.

### JSON-scheman per subagent

**Explorer:**
```json
{
  "agent": "explorer",
  "files": [
    { "path": "lib/...", "lines": "10-40", "findings": ["finding 1", "finding 2"] }
  ]
}
```

**Builder:**
```json
{
  "agent": "builder",
  "status": "done | blocked",
  "files": [
    { "path": "lib/...", "action": "created | modified", "summary": "kort beskrivning" }
  ],
  "blockers": ["beskrivning om status är blocked"]
}
```

**QA Guardian:**
```json
{
  "agent": "qa",
  "status": "approved | blocked",
  "issues": [
    { "severity": "critical | warn", "file": "lib/...", "line": 42, "detail": "beskrivning" }
  ],
  "recommendations": ["icke-blockerande förbättring"]
}
```

**DataSteve:**
```json
{
  "agent": "datasteve",
  "consent_status": "compliant | action_required",
  "gdpr_risk": "none | low | medium | high",
  "findings": ["finding 1"],
  "recommendation": "konkret nästa steg"
}
```

**Visionary:**
```json
{
  "agent": "visionary",
  "feature": "namn",
  "market_gap": "vad konkurrenter saknar",
  "axiom_advantage": "hur vi gör det bättre",
  "impact": "high | medium | low",
  "impact_reason": "motivering",
  "spec": "detaljerad spec till Builder"
}
```

---

## Regler (obrytbara)

1. **Alla uppgifter via Orkestratorn** — inga direktanrop till subagenter
2. **QA alltid efter Builder** — ingen kod mergas utan `"status": "approved"`
3. **Agenter granskar aldrig sitt eget arbete**
4. **DataSteve blockerar** release vid GDPR-risk — oavsett allt annat
5. **Explorer läser aldrig hela filer** — alltid radintervall
6. **Builder improviserar aldrig** — spec måste vara komplett innan start
7. **Ingen PII** i events, loggar eller partnerexporter
8. **Subagenter svarar ALLTID i JSON** — aldrig fritext i agent-till-agent-kommunikation

---

## Aktivering

Skriv bara din uppgift normalt — Orkestratorn tar hand om resten.

För att styra explicit:
```
ORCHESTRATE: <uppgift>          → Kör hela kedjan
QUICK: <uppgift>                → Haiku direkt, ingen orkestrering (enkel fix)
DATASTEVE: <uppgift>            → GDPR/data direkt
VISIONARY: <uppgift>            → Marknadsanalys direkt
```
