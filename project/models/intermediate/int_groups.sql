-- SQLBook: Code
{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key=['event_id', 'group_id'],
        on_schema_change='sync_all_columns'
    )
}}

WITH 

groups AS (
    
    select 
        *,
        CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS deduplicated_at,
        ROW_NUMBER() OVER(PARTITION BY event_id, group_id ORDER BY parsed_at DESC) AS rn
    FROM {{ ref('stg_groups') }}
    {% if is_incremental() %}
        WHERE parsed_at > (SELECT max(parsed_at) FROM {{ this }})  -- To process only new parsed values
    {% endif %}

),

groups_deduplicated AS (

    SELECT 
        event_id,
        group_id,
        group_name,
        parent_group_id,
        parent_group_name,
        grantparent_group_id,
        grandparent_group_name,
        loaded_at,
        parsed_at,
        deduplicated_at
    FROM groups
    WHERE rn = 1
)


SELECT * FROM groups_deduplicated