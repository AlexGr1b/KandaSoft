{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key=[
            'event_sk',
            'group_sk',
            'participant_sk'
        ],
        on_schema_change='sync_all_columns'
    )
}}

WITH final AS (
    SELECT
        MD5(CAST(e.event_id AS TEXT)) as event_sk,
        MD5(CAST(group_id AS TEXT)) as group_sk,
        MD5(CAST(participant_id AS TEXT)) as participant_sk,
        p.participant_position,
        e.deduplicated_at,
        CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS presented_at
    FROM {{ ref('int_events') }} e
    LEFT JOIN {{ ref('int_groups') }} g ON e.event_id = g.event_id
    LEFT JOIN {{ ref('int_participants') }} p ON e.event_id = p.event_id
    {% if is_incremental() %}
        WHERE e.deduplicated_at > (SELECT MAX(deduplicated_at) FROM {{ this }})  -- To process only new parsed values
    {% endif %}
)

SELECT *
FROM final