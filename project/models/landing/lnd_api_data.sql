-- SQLBook: Code
{{
    config(
        materialized='incremental',
        incremental_strategy="append"
    )
}}
 -- `overwrite` can be used to save space if needed

/*
    We have only one source, so we can omit put source name into this and all other DBT modelnames
    in this project: `lnd_postgres__api_data` -> `lnd_api_data`
*/

WITH source_data AS (

    SELECT 
        RAW,
        loaded_at
    FROM {{ source('postgres', 'api_data') }}
)

SELECT *
FROM source_data
