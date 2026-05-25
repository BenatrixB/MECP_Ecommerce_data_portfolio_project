import pandas as pd
from sqlalchemy import create_engine, text
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

def get_engine(db_config):
    url = (
        f"postgresql+psycopg2://{db_config['user']}:{db_config['password']}"
        f"@{db_config['host']}:{db_config['port']}/{db_config['dbname']}"
    )
    return create_engine(url)

def load_csv_to_raw(engine, table_name, file_path):
    try:
        logger.info(f"Loading {file_path} → raw.{table_name}")
        df = pd.read_csv(file_path)
        with engine.begin() as conn:
            conn.execute(text(f"DROP TABLE IF EXISTS raw.{table_name}"))
        df.to_sql(
            name=table_name,
            con=engine,
            schema="raw",
            if_exists="replace",
            index=False,
            chunksize=10000,
        )
        logger.info(f"✅ raw.{table_name} — {len(df):,} rows loaded")
    except Exception as e:
        logger.error(f"❌ Failed to load {table_name}: {e}")
        raise