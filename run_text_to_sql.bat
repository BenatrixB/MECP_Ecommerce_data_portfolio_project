@echo off
set DB_PORT=5433
set DB_NAME=mecp_db
set DB_USER=postgres
set DB_PASSWORD=postgres
set SCHEMA_PATH=dbt_project\mecp\models\marts\schema.yml
dist\text_to_sql.exe
pause
