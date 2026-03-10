/*
To do
- one row per trip. (doesn't matter if yellow or green)          ✅
- add a primary key (trip_id). It has to be unique               ✅
- find all the duplicates and understand why they happen          ✅
- find a way to enrich payment_type with the actual name          ✅

Why duplicates happen:
  Raw taxi data often contains duplicate rows because data is ingested
  from overlapping file dumps, retry logic in GPS/meter systems, or
  vendor reporting errors. Two rows can be identical across every column.
  We fix this by keeping only the first occurrence (ROW_NUMBER = 1)
  partitioned by the columns that define a unique trip.

  Don't run this query.. 
*/

WITH trips AS (
    SELECT * FROM {{ ref('int_trips_unioned') }}
),

-- Deduplicate: keep one row per unique combination of trip-defining columns.
-- Duplicates come from overlapping data loads or vendor reporting errors.
deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                vendor_id,
                pickup_datetime,
                dropoff_datetime,
                pickup_location_id,
                dropoff_location_id,
                passenger_count,
                trip_distance,
                fare_amount,
                total_amount
            ORDER BY vendor_id
        ) AS row_num
    FROM trips
),

final AS (
    SELECT
        -- Primary key: hash of the columns that make a trip unique
        MD5(
            COALESCE(CAST(vendor_id AS VARCHAR), '') ||
            COALESCE(CAST(pickup_datetime AS VARCHAR), '') ||
            COALESCE(CAST(dropoff_datetime AS VARCHAR), '') ||
            COALESCE(CAST(pickup_location_id AS VARCHAR), '') ||
            COALESCE(CAST(dropoff_location_id AS VARCHAR), '') ||
            COALESCE(CAST(passenger_count AS VARCHAR), '') ||
            COALESCE(CAST(trip_distance AS VARCHAR), '') ||
            COALESCE(CAST(fare_amount AS VARCHAR), '') ||
            COALESCE(CAST(total_amount AS VARCHAR), '')
        ) AS trip_id,

        -- identifiers
        vendor_id,
        rate_code_id,
        pickup_location_id,
        dropoff_location_id,

        -- timestamps
        pickup_datetime,
        dropoff_datetime,

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
        improvement_surcharge,
        total_amount,
        payment_type,

        -- Enriched: human-readable payment type name
        CASE payment_type
            WHEN 0 THEN 'Flex Fare trip'
            WHEN 1 THEN 'Credit Card'
            WHEN 2 THEN 'Cash'
            WHEN 3 THEN 'No Charge'
            WHEN 4 THEN 'Dispute'
            WHEN 5 THEN 'Unknown'
            WHEN 6 THEN 'Voided Trip'
        END AS payment_type_name

    FROM deduplicated
    WHERE row_num = 1
)

SELECT * FROM final