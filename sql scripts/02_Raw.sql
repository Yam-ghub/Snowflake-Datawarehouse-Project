CREATE OR REPLACE FILE FORMAT STOCK_DW.RAW.csv_format
  TYPE = 'CSV'
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1
  DATE_FORMAT = 'AUTO';

-- CSV file 
CREATE STAGE IF NOT EXISTS STOCK_DW.RAW.stock_stage
  FILE_FORMAT = STOCK_DW.RAW.csv_format;

-- Creation of raw table 
CREATE OR REPLACE TABLE STOCK_DW.RAW.stock_prices_raw (
  trade_date   DATE,
  close_price  FLOAT,
  high_price   FLOAT,
  low_price    FLOAT,
  open_price   FLOAT,
  volume       NUMBER,
  ticker       STRING,
  sector       STRING
);

-- Verification if the file was loaded
SELECT COUNT(*) FROM STOCK_DW.RAW.stock_prices_raw;
SELECT * FROM STOCK_DW.RAW.stock_prices_raw ORDER BY TRADE_DATE DESC LIMIT 10
