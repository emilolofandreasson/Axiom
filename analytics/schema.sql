-- ============================================================
-- Axiom Analytics — BigQuery schema + dbt gold layer models
-- ============================================================
-- Source: Firebase Firestore → BigQuery export
-- The `events` collection is exported automatically once you
-- enable BigQuery export in Firebase Console:
--   Firestore → Integrations → BigQuery → Link
--
-- Raw table path: `axiom-324e3.firestore_export.events_raw_latest`
-- ============================================================


-- ============================================================
-- 1. RAW EVENTS TABLE (auto-created by Firebase BigQuery export)
--    Reference only — do not run manually.
-- ============================================================

/*
CREATE TABLE IF NOT EXISTS `axiom-324e3.firestore_export.events_raw_latest` (
  document_name   STRING,   -- Firestore document path
  document_id     STRING,   -- ULID (event_id)
  timestamp       TIMESTAMP,
  operation       STRING,   -- CREATE / UPDATE / DELETE

  -- Envelope (always present on every event)
  data.event_id       STRING,
  data.event_type     STRING,
  data.app_id         STRING,
  data.app_version    STRING,
  data.platform       STRING,
  data.subject_id     STRING,
  data.session_id     STRING,
  data.emitted_at_utc TIMESTAMP,

  -- Payload fields (present depending on event_type)
  data.lesson_id        STRING,
  data.question_id      STRING,
  data.question_type    STRING,
  data.skill_tag        STRING,
  data.cefr_level       STRING,
  data.course_language  STRING,
  data.is_correct       BOOL,
  data.time_taken_ms    INT64,
  data.accuracy_pct     FLOAT64,
  data.correct_count    INT64,
  data.exercise_count   INT64,
  data.xp_earned        INT64,
  data.duration_seconds INT64,
  data.question_count   INT64,
  data.pair_id          STRING,
  data.time_to_match_ms INT64,
  data.attempts         INT64,
  data.time_seconds     INT64,
  data.message_len      INT64,
  data.turn_number      INT64,
  data.powerup_type     STRING,
  data.language_code    STRING,
  data.previous_code    STRING,
  data.new_streak       INT64,
  data.previous_streak  INT64,
  data.clean_run        BOOL,
  data.app_version      STRING,
  data.level_id         STRING
);
*/


-- ============================================================
-- 2. STAGING — flatten raw Firestore export into clean rows
-- ============================================================

CREATE OR REPLACE VIEW `axiom-324e3.axiom_staging.stg_events` AS
SELECT
  data.event_id                             AS event_id,
  data.event_type                           AS event_type,
  data.app_id                               AS app_id,
  data.app_version                          AS app_version,
  data.platform                             AS platform,
  data.subject_id                           AS subject_id,
  data.session_id                           AS session_id,
  CAST(data.emitted_at_utc AS TIMESTAMP)    AS emitted_at_utc,
  DATE(CAST(data.emitted_at_utc AS TIMESTAMP)) AS event_date,

  -- Lesson fields
  data.lesson_id        AS lesson_id,
  data.question_id      AS question_id,
  data.question_type    AS question_type,
  data.skill_tag        AS skill_tag,
  data.cefr_level       AS cefr_level,
  data.course_language  AS course_language,
  data.is_correct       AS is_correct,
  data.time_taken_ms    AS time_taken_ms,
  data.accuracy_pct     AS accuracy_pct,
  data.correct_count    AS correct_count,
  data.exercise_count   AS exercise_count,
  data.xp_earned        AS xp_earned,
  data.duration_seconds AS duration_seconds,

  -- Puzzle fields
  data.pair_id          AS pair_id,
  data.time_to_match_ms AS time_to_match_ms,
  data.attempts         AS attempts,

  -- Streak / progress fields
  data.new_streak       AS new_streak,
  data.previous_streak  AS previous_streak,
  data.clean_run        AS clean_run,

  -- Language switch
  data.language_code    AS language_code,
  data.previous_code    AS previous_code

FROM `axiom-324e3.firestore_export.events_raw_latest`
WHERE operation != 'DELETE';


-- ============================================================
-- 3. GOLD LAYER — ready-to-use analytics tables
-- ============================================================

-- ── 3a. Daily active users ───────────────────────────────────
CREATE OR REPLACE TABLE `axiom-324e3.axiom_gold.dau` AS
SELECT
  event_date,
  COUNT(DISTINCT subject_id) AS daily_active_users,
  COUNT(DISTINCT session_id) AS sessions
FROM `axiom-324e3.axiom_staging.stg_events`
WHERE event_type = 'app_opened'
GROUP BY event_date
ORDER BY event_date DESC;


-- ── 3b. Lesson performance per user ─────────────────────────
CREATE OR REPLACE TABLE `axiom-324e3.axiom_gold.lesson_performance` AS
SELECT
  subject_id,
  course_language,
  cefr_level,
  skill_tag,
  COUNT(*)                            AS lessons_completed,
  ROUND(AVG(accuracy_pct) * 100, 1)  AS avg_accuracy_pct,
  SUM(xp_earned)                      AS total_xp,
  ROUND(AVG(duration_seconds), 0)     AS avg_duration_s,
  MIN(event_date)                     AS first_lesson_date,
  MAX(event_date)                     AS last_lesson_date
FROM `axiom-324e3.axiom_staging.stg_events`
WHERE event_type = 'lesson_completed'
GROUP BY subject_id, course_language, cefr_level, skill_tag;


-- ── 3c. Answer accuracy by question type and skill ──────────
CREATE OR REPLACE TABLE `axiom-324e3.axiom_gold.answer_accuracy` AS
SELECT
  course_language,
  cefr_level,
  skill_tag,
  question_type,
  COUNT(*)                                      AS total_answers,
  COUNTIF(is_correct)                           AS correct_answers,
  ROUND(COUNTIF(is_correct) / COUNT(*) * 100, 1) AS accuracy_pct,
  ROUND(AVG(time_taken_ms), 0)                  AS avg_time_ms
FROM `axiom-324e3.axiom_staging.stg_events`
WHERE event_type = 'answer_submitted'
GROUP BY course_language, cefr_level, skill_tag, question_type
ORDER BY accuracy_pct ASC;


-- ── 3d. Retention — D1 / D7 / D30 ──────────────────────────
CREATE OR REPLACE TABLE `axiom-324e3.axiom_gold.retention` AS
WITH first_seen AS (
  SELECT
    subject_id,
    MIN(event_date) AS cohort_date
  FROM `axiom-324e3.axiom_staging.stg_events`
  GROUP BY subject_id
),
activity AS (
  SELECT DISTINCT
    subject_id,
    event_date
  FROM `axiom-324e3.axiom_staging.stg_events`
)
SELECT
  f.cohort_date,
  COUNT(DISTINCT f.subject_id)                              AS cohort_size,
  COUNT(DISTINCT CASE
    WHEN DATE_DIFF(a.event_date, f.cohort_date, DAY) = 1
    THEN f.subject_id END)                                  AS retained_d1,
  COUNT(DISTINCT CASE
    WHEN DATE_DIFF(a.event_date, f.cohort_date, DAY) = 7
    THEN f.subject_id END)                                  AS retained_d7,
  COUNT(DISTINCT CASE
    WHEN DATE_DIFF(a.event_date, f.cohort_date, DAY) = 30
    THEN f.subject_id END)                                  AS retained_d30
FROM first_seen f
LEFT JOIN activity a ON f.subject_id = a.subject_id
GROUP BY f.cohort_date
ORDER BY f.cohort_date DESC;


-- ── 3e. Streak distribution ──────────────────────────────────
CREATE OR REPLACE TABLE `axiom-324e3.axiom_gold.streak_distribution` AS
SELECT
  new_streak                AS streak_length,
  COUNT(DISTINCT subject_id) AS users_at_this_streak,
  COUNT(*)                   AS total_occurrences
FROM `axiom-324e3.axiom_staging.stg_events`
WHERE event_type = 'streak_updated'
  AND new_streak > 0
GROUP BY new_streak
ORDER BY new_streak;


-- ── 3f. Language popularity ──────────────────────────────────
CREATE OR REPLACE TABLE `axiom-324e3.axiom_gold.language_popularity` AS
SELECT
  language_code,
  COUNT(DISTINCT subject_id)  AS users_selected,
  COUNT(*)                    AS total_selections,
  MIN(event_date)             AS first_seen_date
FROM `axiom-324e3.axiom_staging.stg_events`
WHERE event_type = 'language_selected'
GROUP BY language_code
ORDER BY users_selected DESC;


-- ── 3g. Puzzle pair difficulty (hardest pairs to match) ──────
CREATE OR REPLACE TABLE `axiom-324e3.axiom_gold.puzzle_difficulty` AS
SELECT
  lesson_id                                          AS level_id,
  pair_id,
  COUNT(*)                                           AS total_attempts,
  COUNTIF(is_correct)                                AS correct_matches,
  ROUND(COUNTIF(is_correct) / COUNT(*) * 100, 1)    AS match_accuracy_pct,
  ROUND(AVG(time_to_match_ms), 0)                   AS avg_time_ms
FROM `axiom-324e3.axiom_staging.stg_events`
WHERE event_type = 'match_attempted'
GROUP BY lesson_id, pair_id
ORDER BY match_accuracy_pct ASC;
