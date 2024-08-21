-- SQLBook: Code
{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key='group_id',
        on_schema_change='sync_all_columns'
    )
}}

/*
    There is no need to put parent groups as separate records because group object structure is solid (based on the data provided) 
    and each group object has group, parent group and grandparent group.
*/

WITH groups AS (
    
    SELECT
        group_id,
        MD5(CAST(group_id AS TEXT)) as group_sk,
        group_name,
        parent_group_id,
        parent_group_name,
        grantparent_group_id,
        grandparent_group_name,
        deduplicated_at,
        CURRENT_TIMESTAMP AT TIME ZONE 'UTC' AS presented_at
    FROM {{ ref('int_groups') }}
    {% if is_incremental() %}
        WHERE deduplicated_at > (SELECT MAX(deduplicated_at) FROM {{ this }})  -- To process only new parsed values
    {% endif %}
)

SELECT *
FROM groups