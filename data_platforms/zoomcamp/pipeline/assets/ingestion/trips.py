"""@bruin
name: ingestion.trips
type: python
image: python:3.11
connection: duckdb-default

materialization:
  type: table
  strategy: append
@bruin"""

import json
import os
from datetime import datetime, timezone

import pandas as pd


BASE_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data"


def _month_floor(ts: pd.Timestamp) -> pd.Timestamp:
  return pd.Timestamp(year=ts.year, month=ts.month, day=1)


def _iter_month_starts(start_date: str, end_date: str):
  """Yield month starts in [start_date, end_date)."""
  start_ts = pd.Timestamp(start_date)
  end_ts = pd.Timestamp(end_date)

  current = _month_floor(start_ts)
  while current < end_ts:
    yield current
    current = current + pd.DateOffset(months=1)


def _get_taxi_types() -> list[str]:
  raw_vars = os.getenv("BRUIN_VARS", "{}")
  try:
    parsed = json.loads(raw_vars)
  except json.JSONDecodeError:
    parsed = {}

  taxi_types = parsed.get("taxi_types", ["yellow"])
  if not isinstance(taxi_types, list) or not taxi_types:
    return ["yellow"]

  normalized = [str(t).strip().lower() for t in taxi_types if str(t).strip()]
  return normalized or ["yellow"]


def materialize():
  start_date = os.getenv("BRUIN_START_DATE")
  end_date = os.getenv("BRUIN_END_DATE")

  if not start_date or not end_date:
    raise ValueError("BRUIN_START_DATE and BRUIN_END_DATE must be provided.")

  taxi_types = _get_taxi_types()
  extracted_at = datetime.now(timezone.utc)

  frames = []
  for month_start in _iter_month_starts(start_date, end_date):
    month_str = month_start.strftime("%Y-%m")
    for taxi_type in taxi_types:
      file_name = f"{taxi_type}_tripdata_{month_str}.parquet"
      source_url = f"{BASE_URL}/{file_name}"

      try:
        df = pd.read_parquet(source_url)
      except Exception as exc:
        # Missing files can happen for some taxi type / month combinations.
        print(f"Skipping {source_url}: {exc}")
        continue

      df["taxi_type"] = taxi_type
      df["source_file"] = file_name
      df["source_url"] = source_url
      df["extracted_at"] = extracted_at
      frames.append(df)

  if not frames:
    return pd.DataFrame(
      columns=["taxi_type", "source_file", "source_url", "extracted_at"]
    )

  return pd.concat(frames, ignore_index=True)


