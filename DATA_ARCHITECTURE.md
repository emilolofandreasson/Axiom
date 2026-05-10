# DATA_ARCHITECTURE.md — Supabase Data Flow & Inventory

**Status:** DATASTEVE Report | 2026-05-10 | Ownership: DataSteve  
**Purpose:** Complete inventory of Supabase tables, data ingestion triggers, and flows.

---

## Executive Summary

Axiom uses Supabase as the backend (PostgreSQL + Auth + Storage). Data flows in from three sources:

1. **Auth events** → `users` table (on signup via Supabase Auth)
2. **User action events** → `events` table (analytics — lexicon_completed, answer_submitted, etc.)
3. **Feature-specific writes** → `users`, `consent_log`, `friend_requests`, `user_friends` (feature logic)
4. **Manual user edits** → `users.photo_url`, `users.name`, `users.native_language` (profile service)

**Critical:** All data ingestion is **permission-gated by Supabase RLS (Row Level Security)**. No RLS = data leak risk.

---

## TABLE INVENTORY

### 1. `users` (Supabase Auth + Custom Columns)

**Owner:** ProfileService + SagaNotifier  
**Scope:** Per-user profile + engagement metrics

#### Columns
| Column | Type | Source | Trigger | Update Frequency |
|--------|------|--------|---------|------------------|
| `id` (PK) | UUID | Supabase Auth | `auth.users.id` on signup | Once at signup |
| `email` | text | Supabase Auth | User email during signup | On auth change |
| `name` | text | ProfileService | User edit in EditProfileScreen | On user save |
| `native_language` | text | SagaNotifier | LanguageProvider (first language choice) | On language selection |
| `photo_url` | text | ProfileService + Storage | User uploads avatar via ProfileService | On avatar upload |
| `xp_by_language` | JSONB | SagaNotifier | Lesson completion, AI Practice completion, Puzzle completion | ~5 min (batched on _save) |
| `completed_ids` | text[] | SagaNotifier | User completes lesson/puzzle level | ~5 min (batched on _save) |
| `streak_count` | int | SagaNotifier | User completes lesson on consecutive days | On lesson complete |
| `reveal_powerups` | int | SagaNotifier | User spends powerup or earns from rewards | On powerup event |
| `last_active_date` | text | SagaNotifier | User completes any lesson/puzzle | On lesson/puzzle complete |
| `preferred_language` | text | SagaNotifier (enrichment) | Derived: language with most XP | On _enrichUserProfile() |
| `engagement_tier` | text | SagaNotifier (enrichment) | Derived: 'casual' / 'regular' / 'dedicated' based on streak | On _enrichUserProfile() |
| `updated_at` | timestamp | SagaNotifier | Every _syncToSupabase() call | ~5 min |
| `created_at` | timestamp | Supabase (default) | Record creation | Once |

#### Data Flow Diagram
```
SIGNUP (AuthService)
  ↓
Supabase Auth creates users.id
  ↓
On app launch: ProfileService.loadProfile() reads users row
  ↓
[User plays lessons/puzzles]
  ↓
SagaNotifier._awardLessonXp() → state.xpByLanguage[langCode] += xp
  ↓
SagaNotifier._save() → SharedPreferences (local cache)
  ↓
SagaNotifier._syncToSupabase() → INSERT/UPDATE users via upsert
  ↓
_enrichUserProfile() → derived fields (preferred_language, engagement_tier)
```

#### RLS Policy (Required)
```sql
-- Users can only read/update their own row
CREATE POLICY "own_profile" ON public.users
  USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
```

---

### 2. `events` (Analytics & Audit Trail)

**Owner:** SupabaseSyncService (flick_sdk) + EventSensor  
**Scope:** Immutable log of user actions (append-only)

#### Columns
| Column | Type | Source | Trigger | Frequency |
|--------|------|--------|---------|-----------|
| `id` (PK) | text (ULID) | flick_sdk | EventSensor.emit() | Per action |
| `user_id` (FK) | UUID | EventSensor | Supabase Auth | Per action |
| `event_type` | text | Calling code | Specific user action | Per action |
| `payload` | JSONB | EventSensor | Event-specific metadata | Per action |
| `emitted_at` | timestamp | EventSensor.emit() | Auto-set | Per action |

#### Event Types Currently Emitted
| Event | Trigger | Payload Example |
|-------|---------|-----------------|
| `app_opened` | main.dart line 92 | `{app_version, platform, hour_of_day, day_of_week}` |
| `session_ended` | LifecycleObserver (app paused) | `{duration_seconds, hour_of_day, day_of_week}` |
| `onboarding_completed` | OnboardingScreen._finish() | `{consent_anonymous_stats, consent_partner_profile, policy_version}` |
| `language_selected` | LanguageProvider | `{language_code, is_first_time}` |
| `lesson_started` | LessonProvider.startLesson() | `{lesson_id, language_code}` |
| `answer_submitted` | LessonProvider.submitAnswer() | `{question_index, is_correct, question_type}` |
| `lesson_completed` | LessonProvider.completeLesson() | `{lesson_id, xp_awarded, streak_increased}` |
| `puzzle_started` | PuzzleScreen | `{level_id, language_code}` |
| `puzzle_completed` | PuzzleScreen | `{level_id, xp_awarded, time_seconds}` |
| `ai_practice_started` | AIPracticeScreen | `{language_code, difficulty}` |
| `ai_practice_advanced` | AIPracticeProvider.advance() | `{current_index, is_correct}` |
| `ai_practice_completed` | AIPracticeProvider | `{total_questions, xp_awarded}` |
| `heart_lost` | HeartsProvider.loseHeart() | `{context: 'lesson' \| 'puzzle' \| 'practice'}` |
| `friend_request_sent` | FriendService.sendRequest() | `{to_uid, from_name}` |
| `friend_request_accepted` | FriendService.acceptRequest() | `{request_id}` |

#### Data Flow Diagram
```
User action in app (e.g., answer_submitted)
  ↓
EventSensor.emit(eventType, payload) 
  ↓
flick_sdk SQLiteEventBuffer (device storage, batched)
  ↓
SupabaseSyncService.sync() triggered (app startup + lifecycle)
  ↓
Batch insert to events table (up to 250 rows/batch)
  ↓
_buffer.markSynced() removes from local queue
```

#### Critical Note
- Events are **immutable** once inserted (no deletes/updates)
- Batch size: 250 events per sync to avoid payload bloat
- Sync happens at app open + on lifecycle (resume/pause) — NOT real-time
- **GDPR Risk:** User deletion must cascade-delete from events table

#### RLS Policy (Required)
```sql
-- Users can only insert their own events; cannot read/update/delete
CREATE POLICY "insert_own_events" ON public.events
  WITH CHECK (auth.uid() = user_id);
```

---

### 3. `consent_log` (GDPR Consent Audit Trail)

**Owner:** DataSteve (OnboardingScreen writes, this table is read-only for audits)  
**Scope:** Immutable record of consent decisions per user

#### Columns
| Column | Type | Source | Trigger | Frequency |
|--------|------|--------|---------|-----------|
| `id` (PK) | UUID | Supabase (gen_random_uuid) | Record creation | Once per consent decision |
| `user_id` (FK) | UUID | OnboardingScreen | auth.uid() | At onboarding |
| `purpose` | text | OnboardingScreen | One of: 'anonymous_stats', 'partner_profile' | Two rows per user at onboarding |
| `granted` | boolean | OnboardingScreen | User's toggle state | At onboarding |
| `granted_at` | timestamp | Supabase (default NOW()) | Auto-set | At record creation |
| `version` | text | OnboardingScreen (const _kPolicyVersion = '1.0') | Policy version | At onboarding |

#### Data Flow Diagram
```
User reaches OnboardingScreen page 4 (Consent)
  ↓
_ConsentPage renders two toggles (anonymous_stats, partner_profile)
  ↓
User taps "Get started"
  ↓
OnboardingScreen._finish() calls _logConsentToSupabase()
  ↓
INSERT two rows into consent_log:
  - {user_id, purpose: 'anonymous_stats', granted: bool, version: '1.0'}
  - {user_id, purpose: 'partner_profile', granted: bool, version: '1.0'}
```

#### GDPR Compliance Notes
- **Consent revocation:** Currently NO UI to revoke. Must be added to Settings → Privacy.
- **Consent withdrawal effect:** Future data sharing stops, but historical events are NOT deleted (immutable audit trail).
- **Policy versioning:** When privacy policy bumps version, new users see new version; old users' consent stays logged with their version.

#### RLS Policy (Required)
```sql
-- Users can read their own consent; cannot modify (immutable audit log)
CREATE POLICY "own_consent_read" ON public.consent_log
  USING (auth.uid() = user_id);
```

---

### 4. `friend_requests` (Social Graph — Pending Requests)

**Owner:** FriendService  
**Scope:** Pending and historical friend requests

#### Columns
| Column | Type | Source | Trigger | Frequency |
|--------|------|--------|---------|-----------|
| `id` (PK) | UUID | Supabase (gen_random_uuid) | Record creation | Once per request |
| `from_uid` (FK) | UUID | FriendService.sendRequest() | auth.uid() of sender | When user sends request |
| `from_name` | text | FriendService.sendRequest() | UserProfile.name | When user sends request |
| `from_photo_url` | text | FriendService.sendRequest() | UserProfile.photoUrl | When user sends request |
| `to_uid` (FK) | UUID | FriendService.sendRequest() | Recipient's user_id | When user sends request |
| `status` | text | FriendService | 'pending' → 'accepted' \| 'declined' | On user action |
| `created_at` | timestamp | Supabase (default NOW()) | Auto-set | Once |

#### Data Flow Diagram
```
User A searches for User B in FriendsScreen
  ↓
User A taps "Send friend request"
  ↓
FriendService.sendRequest(toUser, fromUser)
  ↓
Check for existing request (prevent duplicates)
  ↓
INSERT friend_requests row with status='pending'
  ↓
[User B sees incoming request in FriendsScreen]
  ↓
User B taps "Accept"
  ↓
FriendService.acceptRequest(req)
  ↓
UPDATE friend_requests SET status='accepted'
  ↓
INSERT two rows into user_friends (bidirectional)
```

#### RLS Policy (Required)
```sql
-- Users can send requests; can see requests sent to them
CREATE POLICY "manage_friend_requests" ON public.friend_requests
  USING (auth.uid() = from_uid OR auth.uid() = to_uid)
  WITH CHECK (auth.uid() = from_uid);
```

---

### 5. `user_friends` (Social Graph — Accepted Friends)

**Owner:** FriendService  
**Scope:** Bidirectional friend relationships (two rows per friendship)

#### Columns
| Column | Type | Source | Trigger | Frequency |
|--------|------|--------|---------|-----------|
| `id` (PK) | UUID | Supabase (gen_random_uuid) | Record creation | Once per direction |
| `user_id` (FK) | UUID | FriendService.acceptRequest() | One side of friendship | When request accepted |
| `friend_id` (FK) | UUID | FriendService.acceptRequest() | Other side of friendship | When request accepted |
| `created_at` | timestamp | Supabase (default NOW()) | Auto-set | Once |

#### Data Flow Note
**Bidirectional storage:** When User A and User B become friends, TWO rows are inserted:
```
user_friends row 1: {user_id: A, friend_id: B}
user_friends row 2: {user_id: B, friend_id: A}
```

This allows efficient queries: `SELECT friend_id FROM user_friends WHERE user_id = $uid`

#### Data Flow Diagram
```
FriendService.acceptRequest(request)
  ↓
UPDATE friend_requests SET status='accepted'
  ↓
INSERT user_friends (bidirectional):
  - {user_id: toUid, friend_id: fromUid}
  - {user_id: fromUid, friend_id: toUid}
```

#### RLS Policy (Required)
```sql
-- Users can only see and manage their own friend list
CREATE POLICY "manage_own_friends" ON public.user_friends
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

---

## DATA STORAGE (Supabase Storage)

### `axiom` Bucket

**Purpose:** User-uploaded media (avatars)

#### Files
| Path Pattern | Source | Trigger | Access |
|--------------|--------|---------|--------|
| `{user_id}/avatar.jpg` | ProfileService.pickAndUploadAvatar() | User taps "Change avatar" in EditProfileScreen | Public URL stored in users.photo_url |

#### Data Flow
```
User selects image from gallery
  ↓
ImagePicker.pickImage() (max 512×512, 85% JPEG quality)
  ↓
ProfileService._uploadAvatar(uid, bytes)
  ↓
storage.from('axiom').uploadBinary(path, bytes, upsert: true)
  ↓
Get public URL + UPDATE users SET photo_url = url
```

---

## EVENT INGESTION SUMMARY TABLE

| Table | Write Source | Event Trigger | Batch? | RLS Required |
|-------|--------------|---------------|--------|--------------|
| `users` | SagaNotifier | XP award, lesson complete, profile edit | Yes (via _save ~5min) | **CRITICAL** |
| `events` | EventSensor → SupabaseSyncService | Every user action | Yes (250/batch) | **CRITICAL** |
| `consent_log` | OnboardingScreen | User completes onboarding | No | **CRITICAL** |
| `friend_requests` | FriendService | User sends/accepts/declines request | No | **CRITICAL** |
| `user_friends` | FriendService | Request accepted | No | **CRITICAL** |
| Storage `axiom/*` | ProfileService | User uploads avatar | No | Partial (public read) |

---

## DATA QUALITY & CONSISTENCY ISSUES

### 🔴 CRITICAL

1. **No RLS Policies Deployed**
   - **Risk:** Any authenticated user can read/write all other users' data
   - **Fix:** Deploy RLS policies listed above before any data collection
   - **Audit:** `mcp__supabase__get_advisors(project_id, 'security')` will flag this

2. **No Data Retention Policy**
   - **Risk:** 100M+ analytics events = runaway storage costs
   - **Fix:** Implement time-based deletion or archive to BigQuery (`analytics/schema.sql` exists but not connected)
   - **Timeline:** By Phase 3

3. **Profile Enrichment Races Consent**
   - **Issue:** `_enrichUserProfile()` writes `preferred_language` + `engagement_tier` to `users` table, but consent may not be logged yet if called during onboarding
   - **Current Risk:** LOW (only happens after onboarding, consent is logged first)
   - **Future Risk:** If we add cross-session tracking, ensure consent is checked before enrichment

4. **No Consent Enforcement in Events Table**
   - **Issue:** Events are written unconditionally; `anonymous_stats` consent is recorded but NOT checked before event write
   - **Fix:** Before SupabaseSyncService.sync(), check `consent_log` for `{purpose: 'anonymous_stats', granted: true}`
   - **Timeline:** Phase 2 (GDPR enforcement)

### 🟡 MEDIUM

5. **SagaNotifier Sync Delay**
   - **Issue:** XP, streak, completed_ids are cached in SharedPreferences and synced every ~5 minutes
   - **Risk:** App crash = loss of progress if user completes lesson right before crash
   - **Mitigation:** Consider immediate sync on lesson complete (trade latency for safety)

6. **Friend Request Deduplication Logic**
   - **Issue:** FriendService checks for existing request before insert, but logic is **not atomically guarded**
   - **Risk:** Race condition if user sends request twice rapidly
   - **Fix:** Add UNIQUE constraint on (from_uid, to_uid) in DB schema

7. **Avatar Upload No Size Validation**
   - **Issue:** `ImagePicker.pickImage()` limits maxWidth/maxHeight client-side only
   - **Risk:** Malicious client could send larger file
   - **Fix:** Add server-side file size limit + content-type validation in storage policies

### 🟢 LOW

8. **Event Payload Not Validated**
   - **Issue:** EventSensor.emit() accepts any JSONB; no schema enforcement
   - **Current mitigation:** Calling code is internal (not user-input)
   - **Risk grows:** When we add user-generated event streams (e.g., feedback)

---

## COMPLIANCE CHECKLIST (DataSteve Review)

- [ ] **RLS policies deployed** on all tables before production data collection
- [ ] **Consent enforcement:** Events table sync gated by `consent_log` query
- [ ] **Consent revocation:** Settings → Privacy screen allows users to withdraw consent
- [ ] **Right to deletion:** Test user deletion → cascade deletes all events, consent_log, friend data
- [ ] **Right to data portability:** `/api/export?uid=` endpoint exports all user data (events, users, consent_log)
- [ ] **Privacy policy versioning:** Stored in `consent_log.version`; update field in onboarding_screen const when policy changes
- [ ] **k-anonymity ≥ 10:** Aggregated partner exports remove rows with fewer than 10 user cohort
- [ ] **Data retention:** Events older than 12 months archived to BigQuery; not deleted (audit trail)
- [ ] **Audit logging:** All consent changes + friend request changes logged

---

## RECOMMENDATIONS (DataSteve)

1. **Phase 1 (Immediate):** Deploy RLS policies; test user deletion cascade
2. **Phase 2 (Before Data Sale):** Implement consent enforcement in event sync; add Settings → Privacy screen
3. **Phase 3 (Before Public Launch):** Implement right to data portability; set up BigQuery archive; bump privacy policy to v1.1 if needed
4. **Phase 4 (Ongoing):** Monitor `mcp__supabase__get_advisors()` quarterly for new security flags

---

**Authored by:** DataSteve 📊  
**Last Updated:** 2026-05-10  
**Status:** APPROVED FOR REVIEW
