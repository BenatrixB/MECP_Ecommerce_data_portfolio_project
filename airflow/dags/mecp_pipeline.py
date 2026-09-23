from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'mecp',
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='mecp_pipeline',
    default_args=default_args,
    description='MECP end-to-end pipeline: ingestion → dbt staging → intermediate → marts → test',
    schedule='@daily',
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=['mecp', 'pipeline'],
) as dag:

    ingestion = BashOperator(
    task_id='ingestion',
    bash_command='cd /opt/airflow/ingestion && python ingest.py',
    env={
        'POSTGRES_HOST': 'mecp-postgres',
        'POSTGRES_PORT': '5432',
        'POSTGRES_DB': 'mecp_db',
        'POSTGRES_USER': 'postgres',
        'POSTGRES_PASSWORD': 'postgres',
    }
    )

    dbt_staging = BashOperator(
    task_id='dbt_staging',
    bash_command='cd /opt/airflow/dbt && /home/airflow/.local/bin/dbt run --select staging.*',
    )

    dbt_intermediate = BashOperator(
    task_id='dbt_intermediate',
    bash_command='cd /opt/airflow/dbt && /home/airflow/.local/bin/dbt run --select intermediate.*',
    )

    dbt_marts = BashOperator(
    task_id='dbt_marts',
    bash_command='cd /opt/airflow/dbt && /home/airflow/.local/bin/dbt run --select marts.*',
    )

    dbt_test = BashOperator(
    task_id='dbt_test',
    bash_command='cd /opt/airflow/dbt && /home/airflow/.local/bin/dbt test',
    )

    ingestion >> dbt_staging >> dbt_intermediate >> dbt_marts >> dbt_test