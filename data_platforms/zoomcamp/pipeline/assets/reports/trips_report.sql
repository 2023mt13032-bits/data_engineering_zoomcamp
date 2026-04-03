/* @bruin

# Docs:
# - SQL assets: https://getbruin.com/docs/bruin/assets/sql
# - Materialization: https://getbruin.com/docs/bruin/assets/materialization
# - Quality checks: https://getbruin.com/docs/bruin/quality/available_checks

name: reports.trips_report

# Docs: https://getbruin.com/docs/bruin/assets/sql
# suggested type: duckdb.sql
type: duckdb.sql

depends:
  - staging.trips

# For reports, `time_interval` is a good choice to rebuild only the relevant time window.
# Important: Use the same `incremental_key` as staging (e.g., pickup_datetime) for consistency.
materialization:
  type: table
  # suggested strategy: time_interval
  strategy: time_interval
  incremental_key: pickup_date
  time_granularity: date

columns:
  - name: taxi_type
    type: string
    description: Taxi type dimension (yellow or green).
    primary_key: true
  - name: payment_type_name
    type: string
    description: Human-readable payment type from lookup.
    primary_key: true
  - name: pickup_date
    type: DATE
    description: Calendar date of trip pickup.
    primary_key: true
  - name: trip_count
    type: BIGINT
    description: Number of trips in the group.
    checks:
      - name: non_negative
  - name: total_fare_amount
    type: float
    description: Sum of fare amount in USD.
    checks:
      - name: non_negative
  - name: total_amount
    type: float
    description: Sum of total amount in USD.
    checks:
      - name: non_negative
  - name: avg_trip_distance
    type: float
    description: Average trip distance in miles.
    checks:
      - name: non_negative

@bruin */

-- Purpose of reports:
-- - Aggregate staging data for dashboards and analytics
-- Required Bruin concepts:
-- - Filter using `{{ start_datetime }}` / `{{ end_datetime }}` for incremental runs
-- - GROUP BY your dimension + date columns

SELECT
  taxi_type,
  coalesce(payment_type_name, 'Unknown') AS payment_type_name,
  cast(pickup_datetime AS DATE) AS pickup_date,
  count(*) AS trip_count,
  sum(fare_amount) AS total_fare_amount,
  sum(total_amount) AS total_amount,
  avg(trip_distance) AS avg_trip_distance
FROM staging.trips
WHERE pickup_datetime >= '{{ start_datetime }}'
  AND pickup_datetime < '{{ end_datetime }}'
GROUP BY 1, 2, 3
