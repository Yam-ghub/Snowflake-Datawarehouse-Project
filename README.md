# Stock Market Data Warehouse — Snowflake

An end-to-end data pipeline that extracts daily stock price data via API, loads it into Snowflake, and models it into a star schema for analysis.

**Stack:** Python (yfinance, pandas) · Snowflake (stages, COPY INTO, SQL) · python-dotenv

---

## Architecture

```
yfinance API
     │
     ▼
Python (ingestion.py) — extract
     │
     ▼
Snowflake internal stage (compressed CSV)
     │  PUT / COPY INTO
     ▼
RAW schema — landing table, minimal transformation
     │  SQL (03_staging.sql)
     ▼
STAGING schema — deduplicated, validated
     │  SQL (04_analytics.sql)
     ▼
ANALYTICS schema — star schema (fact + dimensions)
     │
     ▼
Analytical queries (05_analysis.sql)

```
## Project structure

```
├── 01_setup.sql          -- database, warehouse, schemas, file format, stage
├── 02_raw.sql             -- RAW table DDL
├── 03_staging.sql         -- cleaning / deduplication
├── 04_analytics.sql       -- star schema (dim_date, dim_ticker, fact_stock_prices)
├── 05_analysis.sql        -- exploratory analytical queries
├── ingestion.py            -- extract (yfinance) + load (Snowflake connector)
├── .env.example            -- required environment variables (no real values)
├── .gitignore
├── requirements.txt
└── star_schema_diagram.svg
```
## Key findings
- **Volatility by sector:** [e.g. "Energy showed the highest volatility of the three sectors, with a standard deviation of X% in daily returns, compared to Y% for Tech."]
  <img src="https://github.com/Yam-ghub/Snowflake-Datawarehouse-Project/blob/main/img/volatility.png" alt="Pipeline Architecture" width="1200">
- **Moving average trend:** [what you noticed comparing daily close price against the 7-day moving average — smoothing effects, any notable divergence]
- **Volume:** [which sector traded the most volume, and any hypothesis why]

## Notable issue & fix

While loading data into Snowflake, `COPY INTO` reported success (`Load complete`) but the target table was empty. Investigating with `VALIDATION_MODE = 'RETURN_ERRORS'` and `COPY_HISTORY` showed the real cause: the file format's `DATE_FORMAT` was set to `DD/MM/YYYY`, but the actual dates in the CSV were ISO format (`YYYY-MM-DD`). The pipeline had `ON_ERROR = 'CONTINUE'`, which silently skipped every failed row instead of raising an error.

**Fix:** changed `DATE_FORMAT` to `AUTO` on the file format, and removed `ON_ERROR = 'CONTINUE'` from the load step so future failures raise a real exception instead of failing silently.

## What I'd do differently at scale

- **Incremental loads** instead of full truncate-and-reload, using a watermark on `trade_date` or a Snowflake Stream on the raw table.
- **Orchestration** (Airflow, Dagster, or a scheduled Snowflake Task) instead of a manually triggered script.
- **`MERGE` instead of `CREATE OR REPLACE`** for the staging table, to avoid unnecessary full rebuilds.
- **Automated data quality tests** (e.g. dbt tests or custom SQL assertions) run as part of the pipeline, not just ad hoc validation queries.
