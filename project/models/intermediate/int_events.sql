{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key='event_id',
        on_schema_change='sync_all_columns'
    )
}}

WITH 

events AS (
    
    SELECT 
        *,
        CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS deduplicated_at,
        ROW_NUMBER() OVER(PARTITION BY event_id ORDER BY parsed_at DESC) AS rn
    FROM {{ ref('stg_events') }}
    {% if is_incremental() %}
        WHERE parsed_at > (SELECT MAX(parsed_at) FROM {{ this }})  -- To process only new parsed values
    {% endif %}

),

events_deduplicated AS (

    SELECT 
        event_id, -- change to surrogate
        event_details,
        start_time,
        last_modified_time,
        loaded_at,
        parsed_at,
        deduplicated_at
    FROM events
    WHERE rn = 1
)


SELECT * FROM events_deduplicated