import yfinance as yf
import pandas as pd
from dotenv import load_dotenv
import os
import snowflake.connector

# Define the list of tickers and their corresponding sectors
tickers = ["AAPL", "MSFT", "JPM", "GS", "XOM", "CVX"]
sector_map = {
    "AAPL": "Tech", "MSFT": "Tech",
    "JPM": "Finance", "GS": "Finance",
    "XOM": "Energy", "CVX": "Energy"
}

# Download historical stock data for the last year
all_data = []
for t in tickers:
    df = yf.download(t, period="1y", interval="1d")

    # Flatten MultiIndex columns (newer yfinance versions add a ticker level)
    if isinstance(df.columns, pd.MultiIndex):
        df.columns = df.columns.get_level_values(0)

    df = df.reset_index()  # turns the Date index into a real column
    df["ticker"] = t
    df["sector"] = sector_map[t]
    all_data.append(df)

# Concatenate all dataframes into a single dataframe
final_df = pd.concat(all_data, ignore_index=True)
final_df.to_csv("stock_prices_raw.csv", index=False)

# Connect to Snowflake
load_dotenv()  # reads .env into environment variables

conn = snowflake.connector.connect(
    user=os.environ["SNOWFLAKE_USER"],
    password=os.environ["SNOWFLAKE_PASSWORD"],
    account=os.environ["SNOWFLAKE_ACCOUNT"],
    warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
    database=os.environ["SNOWFLAKE_DATABASE"],
    schema=os.environ["SNOWFLAKE_SCHEMA"]
)

cs = conn.cursor()

try:
    # Upload the local CSV to the Snowflake stage
    file_path = os.path.abspath("stock_prices_raw.csv").replace("\\", "/")
    cs.execute(f"PUT file://{file_path} @STOCK_DW.RAW.stock_stage OVERWRITE = TRUE")

    # Load staged file into the raw table
    cs.execute("""
        COPY INTO STOCK_DW.RAW.stock_prices_raw
        FROM @STOCK_DW.RAW.stock_stage/stock_prices_raw.csv.gz
        FILE_FORMAT = csv_format
        ON_ERROR = 'CONTINUE'
        FORCE = TRUE
    """)

    print("Load complete.")
finally:
    cs.close()
    conn.close()