# Maven E-Commerce Project (MECP)

**Author:** Benas Baranovskis | Data Analyst / Analytics Engineer | [LinkedIn](https://www.linkedin.com/in/bbaranovskis/) | [GitHub](https://github.com/BenatrixB)

An end-to-end analytics engineering portfolio project covering data ingestion, transformation, modelling, statistical analysis, business intelligence, and natural language querying for a fictional e-commerce company.

---

## Project Status

| Phase | Status |
|---|---|
| I — Planning & EDA | ✅ Complete |
| II — Ingestion & Docker setup | ✅ Complete |
| III — dbt modelling & testing | ✅ Complete |
| IV — Airflow orchestration | ✅ Complete |
| V — Dashboards & reporting | ✅ Complete |
| VI — Statistical analysis & A/B testing | ✅ Complete |
| VII — Natural language querying (Text-to-SQL) | ✅ Complete |

---

## Project Overview

Maven Fuzzy Factory is a US-based direct-to-consumer e-commerce company selling premium plush toys. This project analyses three years of transactional and behavioural data (2012–2015) across ~1.73 million records to answer 10 key business questions spanning customer value, acquisition, conversion, product performance, and growth trends.

---

## Tech Stack

| Layer | Tool |
|---|---|
| Containerisation | Docker + docker-compose |
| Storage | PostgreSQL |
| Ingestion | Custom Python scripts |
| Transformation | dbt Core |
| Orchestration | Apache Airflow 3.x |
| BI & Reporting | Power BI |
| Statistical Analysis | Python (scipy, statsmodels, pandas) |
| Natural Language Querying | Ollama + Llama 3.2 (local LLM) |

---

## Key Findings

**BQ9 — Is the business growing, and are there seasonal patterns?**
- Revenue grew 174% YoY (2013→2014), driven by new product launches and channel expansion
- Total revenue: $1.94M across 32K orders, AOV $59.99, overall conversion rate 6.83%

**BQ4 — Which acquisition channels bring the highest quality traffic?**
- Direct/organic (blank channel) converts at 7.34% — highest quality despite lower volume
- Paid gsearch: 6.75%; Socialbook: 3.21% — brand awareness investment recommended to grow organic traffic

**BQ5 — Is there a significant conversion gap between device types?**
- Desktop converts at 8.5% vs mobile 3.09% — a 2.75x gap
- Mobile accounts for 30.84% of sessions but significantly underperforms — mobile UX improvements recommended

**BQ2 — Where in the conversion funnel do we lose the most customers?**
- 93% of sessions never convert; funnel completion rate: 6.83%
- Biggest drop-offs: Product page (44.76%) and Cart stage (63.65%)
- Recommendation: improve product descriptions and implement cart abandonment email campaigns

**BQ1 — What is the value segmentation of our customer base? (RFM)**
- Only 8.4% of customers are Champions; 35.13% are At Risk of churning
- Repeat buyer rate is just 1.86% — significant retention problem
- Average LTV: $61.16; Socialbook drives highest LTV customers despite lowest volume

**BQ3 — How well does the business retain customers over time?**
- Most cohorts retain less than 20% of customers by Month 2
- Average Month 1 retention: 0.84%; best retention cohort: 2014-04
- Recommendation: post-purchase email sequences, loyalty programs, and personalised offers

**BQ8 — What is the lifetime value of our customers by segment and channel?**
- Champion segment LTV: $74; At Risk: $68; Potential: $50; Loyal: $41
- LTV fairly consistent across acquisition channels (~$61–65) — channel quality matters more for conversion volume

**BQ10 — Which website experiments improved conversion rates?**
- /lander-5 converts 3x better than /lander-3 (10.17% vs 3.39%)
- /billing-2 improved checkout completion by +18.57pp vs /billing (63.36% vs 44.79%), +41.5% relative lift
- Chi-square test: χ² = 3,261, p ≈ 0; 9/10 pairwise comparisons significant after Bonferroni correction (α = 0.005)

**BQ6 — Which products drive the most revenue and margin?**
- The Original Mr. Fuzzy drives 62% of total revenue ($1.21M) with 22.6% gross margin
- Newer products underperform — recommend focusing marketing spend on flagship product

**BQ7 — What is the refund rate by product and its financial impact?**
- Overall refund rate: 4.40%; total refunds: $85.34K
- Birthday Sugar Panda has the highest refund rate (6.02%) — potential quality or expectation mismatch issue
- Recommendation: investigate Sugar Panda quality issues while protecting Mr. Fuzzy's reputation

---

## Project Structure

```
├── docs/                    # Project brief, data models, architecture diagrams
├── data/raw/                # Source CSV files (see Data section below)
├── ingestion/               # Python ingestion scripts
├── dbt_project/             # dbt models (staging, intermediate, marts)
├── airflow/dags/            # Airflow DAG definitions
├── dashboards/              # Power BI dashboard files
├── analysis/eda/            # Exploratory data analysis & statistical testing notebooks
├── docker-compose.yml       # Full environment setup
├── text_to_sql.py           # Natural language to SQL query engine
└── .env.example             # Environment variable template
```

---

## dbt Models

| Layer | Models | Tests |
|---|---|---|
| Staging | 6 models | 43 tests |
| Intermediate | 7 models | 57 tests |
| Marts | 7 models | 97 tests |
| **Total** | **20 models** | **157 tests** |

---

## Statistical Analysis

Full hypothesis testing pipeline in [`analysis/eda/ab_test_statistical_analysis.ipynb`](analysis/eda/ab_test_statistical_analysis.ipynb):

- **Chi-square test of independence** — overall significance across lander variants
- **Bonferroni-corrected pairwise z-tests** — all 10 variant pairs with adjusted α = 0.005
- **Wilson 95% confidence intervals** — precision estimates per variant
- **Sample size & power analysis** — minimum detectable effect and post-hoc power
- **Billing page head-to-head z-test** — two-proportion test with effect size quantification
- **Forest plot visualisation** — CI comparison across all variants

---

## Text-to-SQL (Natural Language Querying)

Ask business questions in plain English and get SQL results instantly — no SQL knowledge required.

### How it works

1. `text_to_sql.py` reads `dbt_project/mecp/models/marts/schema.yml` — all 7 mart models with column descriptions
2. Builds a schema context string and sends it to a locally running **Llama 3.2** model via Ollama
3. Llama generates a PostgreSQL query from the natural language question
4. The query is executed against the MECP PostgreSQL database and results are printed

Everything runs **100% locally** — no cloud API, no data leaves your machine.

### Usage

```bash
# Interactive mode
DB_PORT=5433 DB_NAME=mecp_db DB_USER=postgres DB_PASSWORD=postgres python text_to_sql.py

# Single question
DB_PORT=5433 DB_NAME=mecp_db DB_USER=postgres DB_PASSWORD=postgres \
  python text_to_sql.py --question "What is the total revenue by year?"

# Generate SQL without executing (dry run)
python text_to_sql.py --dry-run
```

### Example questions

```
What are the top 5 customers by lifetime value?
What is the total revenue by product?
What is the conversion rate by acquisition channel?
Which customer segment has the highest average LTV?
What is the monthly revenue trend for 2014?
What is the refund rate by product?
How many sessions converted in each device type?
```

### Example output

```
Question: What are the top 5 customers by lifetime value?

── SQL ──
SELECT user_id, ltv FROM marts.mart_users ORDER BY ltv DESC LIMIT 5;

── Results ──
user_id  ltv
-------  ------
341972   251.94
324814   245.95
172266   237.95
275098   235.95
142410   219.96

(5 rows)
```

---

## Data

Source data consists of six CSV files from the Maven Fuzzy Factory transactional database. Due to file size, raw CSV files are not included in this repository. Download the dataset from:

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

---

## Business Questions

This project addresses 10 business questions across four domains:

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

---

## Getting Started

### Prerequisites
- Docker Desktop
- Python 3.12
- Git
- [Ollama](https://ollama.com/download) (for natural language querying)

### Setup

1. Clone the repository
```bash
git clone https://github.com/BenatrixB/MECP_Ecommerce_data_portfolio_project.git
cd MECP_Ecommerce_data_portfolio_project
```

2. Copy environment template
```bash
cp .env.example .env
# Fill in your credentials
```

3. Start Docker environment
```bash
docker compose up -d
```

4. Download source data and place CSV files in `data/raw/`

5. Run ingestion
```bash
python ingestion/ingest.py
```

6. Run dbt models
```bash
cd dbt_project/mecp
dbt run
dbt test
```

7. Access Airflow UI at `http://localhost:8080`

8. Install Ollama and pull Llama 3.2 (for Text-to-SQL)

   Download and install Ollama from [https://ollama.com/download](https://ollama.com/download), then pull the model:
   ```bash
   ollama pull llama3.2
   ```
   Requires ~2GB disk space. Runs locally — no API key or internet connection needed after download.

9. Install Python dependencies for Text-to-SQL
```bash
pip install psycopg2-binary pyyaml
```
