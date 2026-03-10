SELECT 
    -- identifiers
    CAST(vendorid AS int) as vendor_id,
    CAST(ratecodeid AS int) as rate_code_id,
    CAST(pulocationid AS int) as pickup_location_id,
    CAST(dolocationid AS int) as dropoff_location_id,

    -- timestamps
    lpep_pickup_datetime as pickup_datetime,
    lpep_dropoff_datetime as dropoff_datetime,

    -- trip info
    store_and_fwd_flag,
    passenger_count,
    trip_distance,
    trip_type,

    -- payment info
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    ehail_fee,
    improvement_surcharge,
    total_amount,
    payment_type
FROM {{ source('raw_data', 'green_tripdata') }} 