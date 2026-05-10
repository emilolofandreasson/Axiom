# DATA_RETENTION.md — Data Lifecycle & Archival Policy

**Status:** Phase 3 | 2026-05-10 | Owner: DataSteve

---

## Overview

Axiom collects two types of data:

1. **Audit Trails** (immutable, long-term retention)
   - `events` — analytics events (lesson starts, answers, etc.)
   - `consent_log` — GDPR consent history (required 7-year retention for legal compliance)

2. **Operational Data** (mutable, regular cleanup)
   - `users` — profiles, XP, streaks
   - `friend_requests`, `user_friends` — social graph

This policy defines retention periods and archival strategy.

---

## Retention Schedule

| Table | Retention | Rationale | Archival | Cleanup |
|-------|-----------|-----------|----------|---------|
| `events` | 12 months (active) + archive | Analytics trend analysis | BigQuery nightly | Delete after export |
| `consent_log` | **7 years** | GDPR audit trail required | BigQuery monthly | Never delete |
| `users` | Until deletion | Active profile data | N/A | Via CASCADE on auth.users delete |
| `friend_requests` | Until declined/accepted | Social state | N/A | Via CASCADE on user delete |
| `user_friends` | Until removed | Social state | N/A | Via CASCADE on user delete |
| `data_sharing_log` | **7 years** | Legal compliance | BigQuery monthly | Never delete |

---

## Archival to BigQuery

**Purpose:** Long-term storage for analytics trends, legal audit, and ML training (anonymized).

### BigQuery Schema

```sql
-- Raw events archive
CREATE TABLE axiom_analytics.events (
  id STRING NOT NULL,
  user_id STRING NOT NULL,
  event_type STRING NOT NULL,
  payload JSON,
  created_at TIMESTAMP,
  archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Consent audit trail (immutable, for GDPR compliance)
CREATE TABLE axiom_analytics.consent_audit (
  id STRING NOT NULL,
  user_id STRING NOT NULL,
  purpose STRING,
  granted BOOL,
  granted_at TIMESTAMP,
  version STRING,
  archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Data sharing log (immutable, for legal compliance)
CREATE TABLE axiom_analytics.data_sharing_audit (
  id STRING NOT NULL,
  partner_name STRING,
  data_type STRING,
  record_count INT64,
  exported_at TIMESTAMP,
  legal_basis STRING,
  archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Anonymized event aggregations (for ML & partner reports)
CREATE TABLE axiom_analytics.event_aggregates (
  date DATE,
  event_type STRING,
  language_code STRING,
  count INT64,
  avg_duration_seconds FLOAT64,
  aggregated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);
```

### Archive Schedule (Not Yet Implemented)

**Trigger:** Nightly at 02:00 UTC via Supabase scheduled function (cron job)

**Process:**
1. Query Supabase `events` where `created_at < NOW() - 12 months`
2. Export to BigQuery `axiom_analytics.events`
3. Delete from `events` (via SQL cascade)
4. Repeat for `consent_log`, `data_sharing_log`

**Cost Optimization:**
- Only archive events older than 12 months
- Use BigQuery partitioning by `created_at` for query speed
- Anonymize PII before exporting (remove user_id from event payloads, hash email)

---

## Right to Deletion (GDPR Article 17)

When user requests deletion (via future Settings UI):

1. **Immediate:** Delete from `auth.users` → CASCADE deletes:
   - `users` row
   - `events` rows (audit trail lost, but logs app usage)
   - `consent_log` rows (audit trail lost, but logs consent decisions)
   - `friend_requests` (both directions)
   - `user_friends` (both directions)

2. **BigQuery (if archived):**
   - Consent & data sharing logs: **KEEP** (7-year legal hold)
   - Event rows: **DELETE** (analytics no longer needed)
   - Use job with time travel to backfill gap

3. **Audit:** Log deletion in `data_sharing_log` with reason 'user_deletion'

---

## Right to Rectification (GDPR Article 16)

Users can update their own profile via app:

1. `users` table — edit name, bio, native_language
2. Changes are **not** versioned (no history kept)
3. Previous profile data lost (no GDPR requirement to preserve)

---

## Right to Portability (GDPR Article 20)

**Implemented:** `DataExportService` + `data-export` edge function

**Flow:**
1. User taps "Export my data" in Settings → Privacy
2. Edge function queries all user tables
3. Returns JSON blob with timestamp
4. Downloaded to device as `axiom-export-{uid}-{timestamp}.json`
5. Includes: profile, events, consent_log, social connections

**Data in Export:**
```json
{
  "exportedAt": "2026-05-10T14:32:00Z",
  "policyVersion": "1.0",
  "user": { "id", "name", "native_language", "xp_by_language", ... },
  "events": [ { "id", "event_type", "payload", "created_at" }, ... ],
  "consentLog": [ { "id", "purpose", "granted", "granted_at", "version" }, ... ],
  "friendRequests": [ { "id", "from_uid", "to_uid", "status" }, ... ],
  "userFriends": [ { "user_id", "friend_id" }, ... ]
}
```

---

## Data Anonymization Rules

Before sharing data with **partners** (via `data_sharing_log` exports):

1. **Never include:**
   - user.id (raw UUID)
   - user.email
   - user.name
   - Exact location (GPS coords)
   - Device ID / IDFA / fingerprints

2. **Include (anonymized):**
   - Language code (es, fr, de, etc.)
   - CEFR level (A1, B2, etc.)
   - Lesson topics (food, travel, family)
   - Engagement tier (casual, regular, dedicated)
   - Streak count ranges (0-2, 3-9, 10+)
   - Time of day (hour, not minute)

3. **k-Anonymity:** Minimum 10 users per cohort before exporting
   - Example: "Spanish learners in evening timezone with 10+ streak" = 1 cohort
   - If < 10 users match, merge cohorts or omit

---

## Compliance Checklist

- [ ] **Events:** Auto-archive to BigQuery after 12 months
- [ ] **Consent/Sharing logs:** Archive to BigQuery monthly, keep raw 7 years
- [ ] **Deletion:** Test CASCADE delete; confirm BigQuery purge works
- [ ] **Portability:** DataExportService tested with all table types
- [ ] **Anonymization:** Partner export script enforces k-anonymity ≥ 10
- [ ] **Privacy policy:** Updated to v1.1 with retention schedule
- [ ] **Audit logging:** All partner exports logged in `data_sharing_log`

---

## Timeline to Production

| Phase | Tasks | Timeline | Owner |
|-------|-------|----------|-------|
| **Now** | Data export UI + edge function | Done (Phase 3) | DataSteve |
| **Phase 4a** | BigQuery schema + nightly archival | 2 weeks | DataSteve + Backend |
| **Phase 4b** | Right to deletion UI (Settings) | 1 week | UI Builder |
| **Phase 4c** | Partner export aggregation script | 1 week | DataSteve |
| **Phase 5** | Privacy policy v1.1 + legal review | 1 week | Legal team |

---

## References

- **GDPR Articles:**
  - Article 17 (Right to Erasure) — cascade deletion, 7-year legal hold
  - Article 20 (Data Portability) — JSON export via edge function
  - Article 5 (Data Minimization) — anonymization rules
- **BigQuery:**
  - [Partitioning guide](https://cloud.google.com/bigquery/docs/partitioned-tables)
  - [Data anonymization patterns](https://cloud.google.com/solutions/bigquery-data-anonymization)
- **Supabase:**
  - [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
  - [Scheduled functions](https://supabase.com/docs/guides/functions/scheduling)

---

**Authored by:** DataSteve 📊  
**Last Updated:** 2026-05-10  
**Status:** APPROVED FOR IMPLEMENTATION
