-- Staging: deduped, validated stock price data sourced from RAW.
-- Downstream consumers (ANALYTICS) should read from here, not RAW.
CREATE OR REPLACE TABLE STOCK_DW.STAGING.stock_prices_clean AS
SELECT DISTINCT
    trade_date,
    ticker,
    sector,
    open_price,
    high_price,
    low_price,
    close_price,
    volume
FROM STOCK_DW.RAW.stock_prices_raw
WHERE close_price IS NOT NULL
  AND volume > 0; -- excludes non-trading days / bad ticks

-- Data Quality check / Validation
-- check if rows are completed
SELECT COUNT(*) AS row_count
FROM STOCK_DW.STAGING.stock_prices_clean;

-- expect 0 rows: grain should be one row per ticker per day
SELECT ticker, trade_date, COUNT(*)
FROM STOCK_DW.STAGING.stock_prices_clean
GROUP BY ticker, trade_date
HAVING COUNT(*) > 1;

-- expect 0 rows: required fields should never be null
SELECT COUNT(*) AS null_rows
FROM STOCK_DW.STAGING.stock_prices_clean
WHERE trade_date IS NULL OR ticker IS NULL;