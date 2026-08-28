-- Exploratory analysis on fact_stock_prices.
-- 1. 7-day moving average close price, per ticker
SELECT
    ticker,
    date_key,
    close_price,
    AVG(close_price) OVER (
        PARTITION BY ticker ORDER BY date_key
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7d
FROM STOCK_DW.ANALYTICS.fact_stock_prices
ORDER BY ticker, date_key DESC;

-- 2. Volatility (stddev of daily % change) by sector
-- Higher stddev = more price swings = higher risk/volatility
SELECT
    d.sector,
    STDDEV(f.daily_pct_change) AS volatility
FROM STOCK_DW.ANALYTICS.fact_stock_prices f
JOIN STOCK_DW.ANALYTICS.dim_ticker d ON f.ticker = d.ticker
GROUP BY d.sector
ORDER BY volatility DESC;

-- 3. Best and worst single trading day, per ticker
SELECT
    ticker,
    date_key,
    daily_pct_change
FROM (
    SELECT
        ticker,
        date_key,
        daily_pct_change,
        RANK() OVER (PARTITION BY ticker ORDER BY daily_pct_change DESC) AS best_rank,
        RANK() OVER (PARTITION BY ticker ORDER BY daily_pct_change ASC)  AS worst_rank
    FROM STOCK_DW.ANALYTICS.fact_stock_prices
)
WHERE best_rank = 1 OR worst_rank = 1
ORDER BY ticker;

-- 4. Monthly average close price, per ticker
-- Useful for spotting longer-term trend vs. daily noise
SELECT
    ticker,
    d.year,
    d.month,
    ROUND(AVG(f.close_price), 2) AS avg_close_price
FROM STOCK_DW.ANALYTICS.fact_stock_prices f
JOIN STOCK_DW.ANALYTICS.dim_date d ON f.date_key = d.date_key
GROUP BY ticker, d.year, d.month
ORDER BY ticker, d.year, d.month;

-- 5. Total trading volume by sector — which sector saw the most activity
SELECT
    d.sector,
    SUM(f.volume) AS total_volume
FROM STOCK_DW.ANALYTICS.fact_stock_prices f
JOIN STOCK_DW.ANALYTICS.dim_ticker d ON f.ticker = d.ticker
GROUP BY d.sector
ORDER BY total_volume DESC;