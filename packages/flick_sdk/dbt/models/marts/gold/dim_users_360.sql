{{
  config(materialized = 'table')
}}

-- One row per subject_id across the entire Flick ecosystem.
-- This is the core B2B data product: a 360-view of each anonymized user.

with events as (

    select * from {{ ref('stg_flick_events') }}

),

per_app as (

    select
        subject_id,
        app_id,

        count(distinct session_id)                                        as total_sessions,
        count(distinct date_trunc('day', emitted_at_utc))                 as active_days,
        count(case when event_type = 'lesson_completed' then 1 end)       as lessons_completed,
        count(case when event_type = 'answer_submitted' then 1 end)       as answers_submitted,
        count(case when event_type = 'answer_submitted'
                    and is_correct = true then 1 end)                     as correct_answers,

        avg(case when event_type = 'lesson_completed'
                 then accuracy_pct end)                                   as avg_accuracy,

        sum(case when event_type = 'lesson_completed'
                 then xp_earned else 0 end)                               as total_xp,

        sum(case when event_type = 'lesson_completed'
                 then duration_seconds else 0 end)                        as total_time_seconds,

        max(case when event_type = 'lesson_completed'
                 then streak_day end)                                     as max_streak,

        min(emitted_at_utc)                                               as first_seen_at,
        max(emitted_at_utc)                                               as last_seen_at

    from events
    group by 1, 2

),

pivoted as (

    select
        subject_id,

        -- ── Per-app session counts ─────────────────────────────────────────
        max(case when app_id = 'axiom'        then total_sessions end)    as axiom_sessions,
        max(case when app_id = 'golf_flick'   then total_sessions end)    as golf_sessions,
        max(case when app_id = 'health_flick' then total_sessions end)    as health_sessions,
        max(case when app_id = 'ridely_flick' then total_sessions end)    as ridely_sessions,

        -- ── Cross-app aggregates ───────────────────────────────────────────
        sum(total_sessions)                                               as total_sessions_all_apps,
        sum(active_days)                                                  as total_active_days,
        sum(lessons_completed)                                            as total_lessons_completed,
        sum(answers_submitted)                                            as total_answers_submitted,
        sum(correct_answers)                                              as total_correct_answers,

        case
            when sum(answers_submitted) > 0
            then round(sum(correct_answers) * 1.0 / sum(answers_submitted), 4)
        end                                                               as overall_accuracy,

        sum(total_xp)                                                     as total_xp_all_apps,
        sum(total_time_seconds)                                           as total_time_seconds_all_apps,
        max(max_streak)                                                   as max_streak_all_apps,

        -- ── Lifecycle ─────────────────────────────────────────────────────
        min(first_seen_at)                                                as cohort_date,
        max(last_seen_at)                                                 as last_active_at,
        date_diff('day', min(first_seen_at), max(last_seen_at))          as lifetime_days,

        -- D30 retention flag — set by downstream job after 30 days
        case
            when date_diff('day', min(first_seen_at), max(last_seen_at)) >= 30
             and sum(total_sessions) >= 2
            then true else false
        end                                                               as retained_d30

    from per_app
    group by 1

)

select * from pivoted
