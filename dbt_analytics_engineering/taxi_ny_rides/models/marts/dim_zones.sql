WITH taxi_zone_lookup AS (
    SELECT
        *
    FROM {{ ref('taxi_zone_lookup') }}
),

renamed AS (
    SELECT
    locationID as location_id,
    borough,
    zone,
    service_zone
    from taxi_zone_lookup
)

SELECT * FROM renamed