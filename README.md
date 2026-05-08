
## Author

Benas Baranovskis | Data Analyst/Analytics Engineer
[LinkedIn](https://www.linkedin.com/in/bbaranovskis/)
[GitHub](https://github.com/BenatrixB)


# Maven Fuzzy Factory — E-commerce Analytics Pipeline

A end-to-end analytics engineering portfolio project covering data ingestion, 
transformation, modelling, and business intelligence for a fictional 
e-commerce company.

## Project Overview

Maven Fuzzy Factory is a US-based direct-to-consumer e-commerce company 
selling premium plush toys. This project analyses three years of transactional 
and behavioural data (2012–2015) across ~1.73 million records to answer 
10 key business questions spanning customer value, acquisition, conversion, 
product performance, and growth trends.

## Project Status

| Phase | Status |
|---|---|
| I — Planning & EDA | ✅ Complete |
| II — Ingestion & Docker setup | 🔄 In progress |
| III — dbt modelling & testing | ⏳ Upcoming |
| IV — Airflow orchestration | ⏳ Upcoming |
| V — Dashboards & reporting | ⏳ Upcoming |

## Documentation

Full project brief, data model diagrams, and architecture documentation 
available in the `docs/` folder.

## Tech Stack

| Layer | Tool |
|---|---|
| Containerisation | Docker + docker-compose |
| Storage | PostgreSQL |
| Ingestion | Custom Python scripts |
| Transformation | dbt |
| Orchestration | Apache Airflow 3.x |
| BI & Reporting | Power BI |

## Project Structure

├── docs/                    # Project brief, data models, architecture diagrams
├── data/raw/                # Source CSV files (see Data section below)
├── ingestion/               # Python ingestion scripts
├── dbt_project/             # dbt models (staging, intermediate, marts)
├── airflow/dags/            # Airflow DAG definitions
├── dashboards/              # Power BI dashboard files
├── analysis/eda/            # Exploratory data analysis notebooks
├── docker-compose.yml       # Full environment setup
└── .env.example             # Environment variable template

## Data

Source data consists of six CSV files from the Maven Fuzzy Factory 
transactional database. Due to file size, raw CSV files are not included 
in this repository. Download the dataset from:

[Maven Analytics Data Playground](https://mavenanalytics.io/data-playground/toy-store-e-commerce-database)

Place downloaded files in `data/raw/`.

| File | Rows | Description |
|---|---|---|
| website_sessions.csv | ~472k | Sessions with UTM and device info |
| website_pageviews.csv | ~1.19M | Individual pageviews per session |
| orders.csv | ~32k | Orders with revenue and COGS |
| order_items.csv | ~40k | Order line items per product |
| order_item_refunds.csv | ~1.7k | Refund records |
| products.csv | 4 | Product catalogue |

## Business Questions

**This project addresses 10 business questions across four domains:**

**Customer intelligence**
- BQ1: What is the value segmentation of our customer base? (RFM)
- BQ3: How well does the business retain customers over time?
- BQ8: What is the lifetime value of our customers by segment and channel?

**Acquisition & channel performance**
- BQ4: Which acquisition channels bring the highest quality traffic?
- BQ5: Is there a significant conversion gap between device types?

**Website & conversion performance**
- BQ2: Where in the conversion funnel do we lose the most customers?
- BQ10: Which website experiments improved conversion rates?

**Product & financial performance**
- BQ6: Which products drive the most revenue and margin?
- BQ7: What is the refund rate by product and its financial impact?
- BQ9: Is the business growing, and are there seasonal patterns?

## Getting Started

### Prerequisites
- Docker Desktop installed
- Python 3.9+
- dbt Core installed
