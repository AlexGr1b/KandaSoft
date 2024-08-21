"""
This DAG represents our data pipeline

Before running this DAG PostgreSQL database and Airflow instance have to configured correctly
"""
from airflow.models.dag import DAG
from datetime import datetime, timedelta
from airflow.utils.task_group import TaskGroup
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from pipelines.tasks.collect_data_from_api import collect_data_from_api
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.operators.bash_operator import BashOperator


default_args = {
    "owner": "Alexei Grib",
    "depends_on_past": False,
    "start_date": datetime.today().strftime('%Y-%m-%d'),
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=1),
}

dag = DAG(
    dag_id="project_api_dag",
    default_args=default_args,
    description="DAG includes tasks, which scrap release notes sites and upload data into database",
    schedule_interval=timedelta(minutes=10),
    catchup=False
)

with dag:

    start_task = EmptyOperator(
        task_id="Start",
        dag=dag
    )

    collect_data_from_api_task = PythonOperator(
        task_id="collect_data_from_api",
        python_callable=collect_data_from_api,
        op_args=[PostgresHook(postgres_conn_id='project_database')],
        provide_context=True,
        dag=dag,
    )

    dbt_build_task = BashOperator(
        task_id='dbt_build',
        bash_command='dbt build --project-dir /opt/airflow/dags/pipelines/project --profiles-dir /opt/airflow/dags/pipelines/.dbt',
        dag=dag,
    )

    start_task >> collect_data_from_api_task >> dbt_build_task
