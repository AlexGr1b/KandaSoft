{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key='event_id',
        on_schema_change='sync_all_columns'
    )
}}

WITH

flatenned_events AS (
    
    SELECT
        CAST(e->>'id' AS INTEGER) AS event_id,
        CAST(e->>'eventDetails' AS JSONB) AS event_details,
        CAST(e->>'startTime' AS TIMESTAMP) AS start_time,
        CAST(e->>'lastModifiedTime' AS TIMESTAMP) AS last_modified_time,
        -- I've intentionally omit messageTime field, but this can be added and used in fact table if it's used by business
        /*
            More fields can be added here if needed
        */
        CAST(ad.loaded_at AS TIMESTAMP) AS loaded_at,
        CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS parsed_at
    FROM {{ ref('lnd_api_data') }} AS ad,
        JSONB_ARRAY_ELEMENTS(raw) AS e
    {% if is_incremental() %}
        WHERE loaded_at > (SELECT MAX(loaded_at) FROM {{ this }})  -- To process only new parsed values
    {% endif %}
)

SELECT * FROM flatenned_events