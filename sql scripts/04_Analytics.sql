-- Analytics: star schema for stock price analysis.
-- fact_stock_prices is the grain table (one row per ticker per day),
-- joined to dim_ticker and dim_date for descriptive attributes.

CREATE OR REPLACE TABLE STOCK_DW.ANALYTICS.dim_ticker AS
SELECT DISTINCT
    ticker,
    sector
FROM STOCK_DW.STAGING.stock_prices_clean;

CREATE OR REPLACE TABLE STOCK_DW.ANALYTICS.dim_date AS
SELECT DISTINCT
    trade_date AS date_key,
    YEAR(trade_date)        AS year,
    MONTH(trade_date)       AS month,
    QUARTER(trade_date)     AS quarter,
    DAYOFWEEK(trade_date)   AS day_of_week
FROM STOCK_DW.STAGING.stock_prices_clean;

CREATE OR REPLACE TABLE STOCK_DW.ANALYTICS.fact_stock_prices AS
SELECT
    trade_date AS date_key,
    ticker,
    open_price,
    high_price,
    low_price,
    close_price,
    volume,
    close_price - open_price AS daily_change,
    ROUND((close_price - open_price) / open_price * 100, 2) AS daily_pct_change
FROM STOCK_DW.STAGING.stock_prices_clean;


-- Data Quality Check
SELECT COUNT(*) FROM STOCK_DW.ANALYTICS.dim_ticker;          -- expect 6

SELECT COUNT(*) FROM STOCK_DW.ANALYTICS.dim_date;             -- expect ~251

SELECT COUNT(*) FROM STOCK_DW.ANALYTICS.fact_stock_prices;    -- expect ~1,506

-- fact table should join cleanly to both dimensions with no orphans
SELECT COUNT(*) AS orphan_rows
FROM STOCK_DW.ANALYTICS.fact_stock_prices f
LEFT JOIN STOCK_DW.ANALYTICS.dim_ticker d ON f.ticker = d.ticker
WHERE d.ticker IS NULL;