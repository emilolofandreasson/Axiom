-- Singular test: fails if any event_id appears more than once in Silver.
-- The incremental model uses event_id as unique_key, but this test catches
-- any dedup logic regression.

select
    event_id,
    count(*) as cnt
from {{ ref('stg_flick_events') }}
group by 1
having cnt > 1
