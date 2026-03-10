SELECT 
    --identifiers
    CAST(vendorid AS int) as vendor_id,
    CAST(ratecodeid AS int) as rate_code_id,
    CAST(pulocationid AS int) as pickup_location_id,
    CAST(dolocationid AS int) as dropoff_location_id,

    -- timestamps
    CAST(tpep_pickup_datetime AS timestamp) as pickup_datetime,
    CAST(tpep_dropoff_datetime AS timestamp) as dropoff_datetime,

    -- trip info
    store_and_fwd_flag,
    CAST(passenger_count AS int) as passenger_count,
    CAST(trip_distance AS float) as trip_distance,

    -- payment info
    CAST(fare_amount AS numeric) as fare_amount,
    CAST(extra AS numeric) as extra,
    CAST(mta_tax AS numeric) as mta_tax,
    CAST(tip_amount AS numeric) as tip_amount,
    CAST(tolls_amount AS numeric) as tolls_amount,
    CAST(improvement_surcharge AS numeric) as improvement_surcharge,
    CAST(total_amount AS numeric) as total_amount,
    CAST(payment_type AS int) as payment_type
FROM {{ source('raw_data', 'yellow_tripdata') }}
WHERE vendorid IS NOT NULL