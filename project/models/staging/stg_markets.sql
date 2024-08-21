-- SQLBook: Code
{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key='market_id',
        on_schema_change='sync_all_columns'
    )
}}

WITH 

markets AS (
    
    SELECT
        CAST(e->>'id' AS INTEGER) AS event_id,
        CAST(market->>'id' AS TEXT) AS market_id,
        CAST(market->>'name' AS TEXT) AS market_name,
        CAST(market->>'specifier' AS TEXT) AS specifier,
        CAST(outcome->>'id' AS TEXT) AS outcome_id,
        CAST(outcome->>'name' AS TEXT) AS outcome_name,
        CAST(outcome->>'isTraded' AS BOOLEAN) AS outcome_is_traded,
        CAST(outcome->>'formatDecimal' AS NUMERIC(12, 2)) AS outcome_format_decimal, -- Total digits can be adjusted
        CAST(outcome->>'formatAmerican' AS TEXT) AS outcome_format_american,
        CAST(outcome->>'status' AS TEXT) AS outcome_status,
        CAST(outcome->>'trueOdds' AS NUMERIC(19, 9)) AS outcome_true_odds,
        CAST(ad.loaded_at AS TIMESTAMP) AS loaded_at,
        CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS parsed_at
    FROM {{ ref('lnd_api_data') }} AS ad,
        JSONB_ARRAY_ELEMENTS(raw) AS e,
        JSONB_ARRAY_ELEMENTS(CAST(e->>'markets' AS JSONB)) AS market,
        JSONB_ARRAY_ELEMENTS(CAST(market->>'outcomes' AS JSONB)) AS outcome
    {% if is_incremental() %}
        WHERE loaded_at > (SELECT MAX(loaded_at) FROM {{ this }})  -- To process only new parsed values
    {% endif %}
)

SELECT * FROM markets