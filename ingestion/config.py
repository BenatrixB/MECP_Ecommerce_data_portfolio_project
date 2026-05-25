import os
from dotenv import load_dotenv

load_dotenv()

DB_CONFIG = {
    "host": os.getenv("POSTGRES_HOST"),
    "port": os.getenv("POSTGRES_PORT"),
    "dbname": os.getenv("POSTGRES_DB"),
    "user": os.getenv("POSTGRES_USER"),
    "password": os.getenv("POSTGRES_PASSWORD"),
}


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data", "raw")

TABLES = {
    "orders": f"{DATA_DIR}/orders.csv",
    "order_items": f"{DATA_DIR}/order_items.csv",
    "order_item_refunds": f"{DATA_DIR}/order_item_refunds.csv",
    "products": f"{DATA_DIR}/products.csv",
    "website_sessions": f"{DATA_DIR}/website_sessions.csv",
    "website_pageviews": f"{DATA_DIR}/website_pageviews.csv",
}