{{
  config(
    materialized     = 'incremental',
    unique_key       = 'event_id',
    on_schema_change = 'sync_all_columns'
  )
}}

with source as (

    select * from {{ source('bronze', 'raw_events') }}

    {% if is_incremental() %}
    -- Only process new rows since last run; received_at_utc is set by the
    -- ingestor and is monotonically increasing even if devices emit late.
    where received_at_utc > (select max(received_at_utc) from {{ this }})
    {% endif %}

),

parsed as (

    select
        -- ── Envelope ──────────────────────────────────────────────────────
        event_id,
        event_type,
        app_id,
        app_version,
        platform,

        -- ── Identity ──────────────────────────────────────────────────────
        subject_id,
        session_id,

        -- ── Timestamps ────────────────────────────────────────────────────
        cast(emitted_at_utc  as timestamp) as emitted_at_utc,
        cast(received_at_utc as timestamp) as received_at_utc,

        -- ── Payload — promoted to first-class columns ─────────────────────
        -- lesson events
        json_extract_scalar(payload_json, '$.lesson_id')       as lesson_id,
        json_extract_scalar(payload_json, '$.course_language') as course_language,
        json_extract_scalar(payload_json, '$.cefr_level')      as cefr_level,
        json_extract_scalar(payload_json, '$.skill_tag')       as skill_tag,

        try_cast(
            json_extract_scalar(payload_json, '$.exercise_count')
        as int)    as exercise_count,

        try_cast(
            json_extract_scalar(payload_json, '$.correct_count')
        as int)    as correct_count,

        try_cast(
            json_extract_scalar(payload_json, '$.accuracy_pct')
        as double) as accuracy_pct,

        try_cast(
            json_extract_scalar(payload_json, '$.duration_seconds')
        as int)    as duration_seconds,

        try_cast(
            json_extract_scalar(payload_json, '$.xp_earned')
        as int)    as xp_earned,

        try_cast(
            json_extract_scalar(payload_json, '$.streak_day')
        as int)    as streak_day,

        -- answer events
        json_extract_scalar(payload_json, '$.question_id')     as question_id,
        json_extract_scalar(payload_json, '$.question_type')   as question_type,

        try_cast(
            json_extract_scalar(payload_json, '$.is_correct')
        as boolean) as is_correct,

        try_cast(
            json_extract_scalar(payload_json, '$.time_taken_ms')
        as int)    as time_taken_ms,

        -- chat events
        try_cast(
            json_extract_scalar(payload_json, '$.message_len')
        as int)    as message_len,

        try_cast(
            json_extract_scalar(payload_json, '$.turn_number')
        as int)    as turn_number,

        -- ── Raw payload preserved for schema evolution ────────────────────
        payload_json

    from source

)

select * from parsed
