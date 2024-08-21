FROM apache/airflow:2.7.0

# Install dbt Core and dbt-postgres
RUN pip install dbt-core==1.8.3 \
    pip install dbt-postgres==1.8.2
