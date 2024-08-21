{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key='group_id',
        on_schema_change='sync_all_columns'
    )
}}

WITH 

groups AS (
    
    SELECT
        CAST(e->>'id' AS INTEGER) as event_id,
        CAST(e->'group'->>'id' AS INTEGER) AS group_id,
        CAST(e->'group'->>'name' AS TEXT) AS group_name,
        CAST(e->'group'->'parentGroup'->>'id' AS INTEGER) AS parent_group_id,
        CAST(e->'group'->'parentGroup'->>'name' AS TEXT) AS parent_group_name,
        CAST(e->'group'->'parentGroup'->'parentGroup'->>'id' AS INTEGER) AS grantparent_group_id,
        CAST(e->'group'->'parentGroup'->'parentGroup'->>'name' AS TEXT) AS grandparent_group_name,
        CAST(ad.loaded_at AS TIMESTAMP) as loaded_at,
        CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS parsed_at
    FROM {{ ref('lnd_api_data') }} AS ad,
        JSONB_ARRAY_ELEMENTS(raw) AS e
    {% if is_incremental() %}
        WHERE loaded_at > (SELECT MAX(loaded_at) FROM {{ this }})  -- To process only new parsed values
    {% endif %}
)

SELECT * FROM groups