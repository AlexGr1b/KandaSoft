-- SQLBook: Code
{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key='participant_id',
        on_schema_change='sync_all_columns'
    )
}}


WITH participants AS (
    
    SELECT
        participant_id,
        MD5(CAST(participant_id AS TEXT)) as participant_sk,
        participant_name,
        participant_abbreviation,
        deduplicated_at,
        CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS presented_at
    FROM {{ ref('int_participants') }}
    {% if is_incremental() %}
        WHERE deduplicated_at > (SELECT MAX(deduplicated_at) FROM {{ this }})
    {% endif %}
)

SELECT *
FROM participants