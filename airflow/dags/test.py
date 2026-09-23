# airflow/dags/test_dag.py
from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    dag_id='test_simple',
    start_date=datetime(2025, 1, 1),
    catchup=False,
) as dag:

    test = BashOperator(
        task_id='test',
        bash_command='echo HELLO WORLD',
    )