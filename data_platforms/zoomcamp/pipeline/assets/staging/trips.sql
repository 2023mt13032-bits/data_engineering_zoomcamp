/* @bruin

# Docs:
# - Materialization: https://getbruin.com/docs/bruin/assets/materialization
# - Quality checks (built-ins): https://getbruin.com/docs/bruin/quality/available_checks
# - Custom checks: https://getbruin.com/docs/bruin/quality/custom


name: staging.trips

type: duckdb.sql

depends:
  - ingestion.trips
  - ingestion.payment_lookup

# - This module expects you to use `time_interval` to reprocess only the requested window.
materialization:
  type: table

# Docs: https://getbruin.com/docs/bruin/quality/custom
custom_checks:
  - name: dropoff_after_pickup
    description: Ensure no trip has dropoff earlier than pickup.
    query: |
      SELECT COUNT(*)
      FROM staging.trips
      WHERE dropoff_datetime < pickup_datetime
    value: 0

@bruin */

--
-- Purpose of staging:
-- - Clean and normalize schema from ingestion
-- - Deduplicate records (important if ingestion uses append strategy)
-- - Enrich with lookup tables (JOINs)
-- - Filter invalid rows (null PKs, negative values, etc.)
--
-- Why filter by {{ start_datetime }} / {{ end_datetime }}?
-- When using `time_interval` strategy, Bruin:
--   1. DELETES rows where `incremental_key` falls within the run's time window
--   2. INSERTS the result of your query
-- Therefore, your query MUST filter to the same time window so only that subset is inserted.
-- If you don't filter, you'll insert ALL data but only delete the window's data = duplicates.

WITH typed AS (
  SELECT
    lower(trim(t.taxi_type)) AS taxi_type,
    try_cast(t.tpep_pickup_datetime AS TIMESTAMP) AS pickup_datetime,
    try_cast(t.tpep_dropoff_datetime AS TIMESTAMP) AS dropoff_datetime,
    try_cast(t.pu_location_id AS INTEGER) AS pickup_location_id,
    try_cast(t.do_location_id AS INTEGER) AS dropoff_location_id,
    try_cast(t.payment_type AS INTEGER) AS payment_type_id,
    try_cast(t.vendor_id AS INTEGER) AS vendor_id,
    try_cast(t.passenger_count AS INTEGER) AS passenger_count,
    try_cast(t.trip_distance AS DOUBLE) AS trip_distance,
    try_cast(t.fare_amount AS DOUBLE) AS fare_amount,
    try_cast(t.total_amount AS DOUBLE) AS total_amount,
    try_cast(t.extracted_at AS TIMESTAMP) AS extracted_at,
    t.source_file,
    t.source_url
  FROM ingestion.trips t
),
windowed AS (
  SELECT *
  FROM typed
  WHERE pickup_datetime >= '{{ start_datetime }}'
    AND pickup_datetime < '{{ end_datetime }}'
),
deduped AS (
  SELECT
    *,
    row_number() OVER (
      PARTITION BY taxi_type, pickup_datetime, dropoff_datetime, pickup_location_id, dropoff_location_id, fare_amount
      ORDER BY extracted_at DESC, source_file DESC
    ) AS row_num
  FROM windowed
  WHERE pickup_datetime IS NOT NULL
    AND dropoff_datetime IS NOT NULL
    AND pickup_location_id IS NOT NULL
    AND dropoff_location_id IS NOT NULL
    AND fare_amount >= 0
    AND coalesce(trip_distance, 0) >= 0
)
SELECT
  d.taxi_type,
  d.pickup_datetime,
  d.dropoff_datetime,
  d.pickup_location_id,
  d.dropoff_location_id,
  d.vendor_id,
  d.passenger_count,
  d.trip_distance,
  d.fare_amount,
  d.payment_type_id,
  p.payment_type_name,
  d.total_amount,
  d.extracted_at,
  d.source_file,
  d.source_url
FROM deduped d
LEFT JOIN ingestion.payment_lookup p
  ON d.payment_type_id = p.payment_type_id
WHERE d.row_num = 1
