{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key=[
            'market_id',
            'outcome_id',
            'event_sk'
        ],
        on_schema_change='sync_all_columns'
    )
}}

-- Markets is chosen as a fact table basement because markets data have too high cardinality to be a dimension table
WITH final AS (
    SELECT
        m.market_id,
        m.market_name,
        m.specifier,
        m.outcome_id,
        m.outcome_name,
        m.outcome_is_traded,
        m.outcome_format_decimal,
        m.outcome_format_american,
        m.outcome_status,
        m.outcome_true_odds,
        e.event_sk,
        e.event_details,
        m.deduplicated_at,
        CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS presented_at
    FROM {{ ref('int_markets') }} m
    LEFT JOIN {{ ref('dim_events') }} e ON m.event_id = e.event_id
    {% if is_incremental() %}
        WHERE m.deduplicated_at > (SELECT MAX(deduplicated_at) FROM {{ this }})
    {% endif %}
)

SELECT *
FROM final