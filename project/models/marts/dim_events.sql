{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key='event_id',
        on_schema_change='sync_all_columns'
    )
}}


WITH events AS (
    
    SELECT
        MD5(CAST(event_id AS TEXT)) as event_sk,
        event_id,
        event_details,
        start_time AS event_start_dt,
        last_modified_time AS event_last_modified_dt,
        deduplicated_at,
        CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS presented_at
    FROM {{ ref('int_events') }}
    {% if is_incremental() %}
        WHERE deduplicated_at > (SELECT MAX(deduplicated_at) FROM {{ this }})
    {% endif %}
)

SELECT *
FROM events
