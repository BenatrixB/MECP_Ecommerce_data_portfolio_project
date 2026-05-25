from config import DB_CONFIG, TABLES
from loaders import get_engine, load_csv_to_raw
import logging

logger = logging.getLogger(__name__)

def run_ingestion():
    logger.info("Starting MECP ingestion pipeline")
    engine = get_engine(DB_CONFIG)
    
    for table_name, file_path in TABLES.items():
        load_csv_to_raw(engine, table_name, file_path)
    
    logger.info("Ingestion complete")

if __name__ == "__main__":
    run_ingestion()