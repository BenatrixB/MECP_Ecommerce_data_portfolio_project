FROM apache/airflow:3.0.1
RUN pip install dbt-postgres==1.9.0 "celery==5.4.0"