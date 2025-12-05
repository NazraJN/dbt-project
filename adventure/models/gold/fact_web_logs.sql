{{ config(
    materialized='table'
) }}

-- Simplified web logs fact table
select * from {{ ref('weblogs') }}
