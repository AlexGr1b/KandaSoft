-- SQLBook: Code
{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key=['event_id', 'participant_id'],
        on_schema_change='sync_all_columns'
    )
}}

WITH 

participants AS (
    
    SELECT 
        *,
        CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS deduplicated_at,
        ROW_NUMBER() OVER(PARTITION BY event_id, participant_id ORDER BY parsed_at DESC) AS rn
    FROM {{ ref('stg_participants') }}
    {% if is_incremental() %}
        WHERE parsed_at > (SELECT MAX(parsed_at) FROM {{ this }})  -- To process only new parsed values
    {% endif %}

),

participants_deduplicated AS (

    SELECT 
        event_id,
        participant_id,
        participant_name,
        participant_position,
        participant_abbreviation,
        loaded_at,
        parsed_at,
        deduplicated_at
    FROM participants
    WHERE rn = 1
)


SELECT * FROM participants_deduplicated