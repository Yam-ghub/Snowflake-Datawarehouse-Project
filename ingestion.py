import yfinance as yf
import pandas as pd
from dotenv import load_dotenv
import os
import snowflake.connector


def extract_data():
    tickers = ["AAPL", "MSFT", "JPM", "GS", "XOM", "CVX"]
    sector_map = {
        "AAPL": "Tech", "MSFT": "Tech",
        "JPM": "Finance", "GS": "Finance",
        "XOM": "Energy", "CVX": "Energy"
    }

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

    return pd.concat(all_data, ignore_index=True)


def get_connection():
    load_dotenv()
    return snowflake.connector.connect(
        user=os.environ["SNOWFLAKE_USER"],
        password=os.environ["SNOWFLAKE_PASSWORD"],
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
        database=os.environ["SNOWFLAKE_DATABASE"],
        schema=os.environ["SNOWFLAKE_SCHEMA"]
    )


def load_to_snowflake(csv_filename):
    conn = get_connection()
    cs = conn.cursor()

    try:
        # Avoid duplicate rows if this script runs more than once
        cs.execute("TRUNCATE TABLE STOCK_DW.RAW.stock_prices_raw")

        file_path = os.path.abspath(csv_filename).replace("\\", "/")
        cs.execute(f"PUT file://{file_path} @STOCK_DW.RAW.stock_stage OVERWRITE = TRUE")

        cs.execute("""
            COPY INTO STOCK_DW.RAW.stock_prices_raw
            FROM @STOCK_DW.RAW.stock_stage/stock_prices_raw.csv.gz
            FILE_FORMAT = STOCK_DW.RAW.csv_format
            ON_ERROR = 'CONTINUE'
            FORCE = TRUE;
        """)

        print("Load complete.")

    except Exception as e:
        print(f"Load failed: {e}")
        raise

    finally:
        cs.close()
        conn.close()


if __name__ == "__main__":
    csv_filename = "stock_prices_raw.csv"

    df = extract_data()
    df.to_csv(csv_filename, index=False)
    print(f"Extracted {len(df)} rows to {csv_filename}")

    load_to_snowflake(csv_filename)