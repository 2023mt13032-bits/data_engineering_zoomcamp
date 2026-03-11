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
