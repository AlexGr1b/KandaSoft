-- SQLBook: Code
{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key=['event_id', 'market_id', 'outcome_id'],
        on_schema_change='sync_all_columns'
    )
}}

WITH 

markets AS (
    
    SELECT 
        *,
        CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS deduplicated_at,
        ROW_NUMBER() OVER(PARTITION BY event_id, market_id, outcome_id ORDER BY parsed_at DESC) AS rn
    FROM {{ ref('stg_markets') }}
    {% if is_incremental() %}
        WHERE parsed_at > (SELECT MAX(parsed_at) FROM {{ this }})  -- To process only new parsed values
    {% endif %}

),

markets_deduplicated AS (

    SELECT 
        event_id,
        market_id,
        market_name,
        specifier,
        outcome_id,
        outcome_name,
        outcome_is_traded,
        outcome_format_decimal,
        outcome_format_american,
        outcome_status,
        outcome_true_odds,
        loaded_at,
        parsed_at,
        deduplicated_at
    FROM markets
    WHERE rn = 1
)


SELECT * FROM markets_deduplicated