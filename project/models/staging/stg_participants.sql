-- SQLBook: Code
{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key='participant_id',
        on_schema_change='sync_all_columns'
    )
}}

WITH 

participants AS (
    
    SELECT
        CAST(e->>'id' AS INTEGER) AS event_id,
        CAST(participant->>'id' AS INTEGER) AS participant_id,
        CAST(participant->>'name' AS TEXT) AS participant_name,
        CAST(participant->>'position' AS TEXT) AS participant_position,
        CAST(participant->>'abbreviation' AS TEXT) AS participant_abbreviation,
        CAST(ad.loaded_at AS TIMESTAMP) AS loaded_at,
        CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS parsed_at
    FROM {{ ref('lnd_api_data') }} AS ad,
        JSONB_ARRAY_ELEMENTS(raw) AS e,
        JSONB_ARRAY_ELEMENTS(CAST(e->>'participants' AS JSONB)) AS participant
    {% if is_incremental() %}
        WHERE loaded_at > (SELECT MAX(loaded_at) FROM {{ this }})  -- To process only new parsed values
    {% endif %}
)

SELECT * FROM participants