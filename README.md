# Snowflake-Datawarehouse-Project
Stock Market Data Warehouse — Snowflake

An end-to-end data pipeline that extracts daily stock price data via API, loads it into Snowflake, and models it into a star schema for analysis.

Stack: Python (yfinance, pandas) · Snowflake (stages, COPY INTO, SQL) · python-dotenv

Architecture
```
yfinance API
     │
     ▼
Python (ingestion.py) — extract
     │
     ▼
Snowflake internal stage (compressed CSV) PUT / COPY INTO
     │  
     ▼
RAW schema — landing table, minimal transformation SQL (03_staging.sql)
     │  
     ▼
STAGING schema — deduplicated, validated SQL (04_analytics.sql)
     │  
     ▼
ANALYTICS schema — star schema (fact + dimensions)
     │
     ▼
Analytical queries (05_analysis.sql)
```
