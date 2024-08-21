"""
This file contains all functions that can be used by Airflow DAG
"""
import requests
import json


def collect_data_from_api(hook, license_id: str = 'US-NJ', lang: str = 'en', limit: int = 18):
    """
    Collects data from a specified API endpoint and inserts it into a database.

    Parameters:
    hook: The database Airflow hook object that provides the connection to the database.
    license_id (str): The license ID parameter for the API request.
    lang (str): The language parameter for the API request (default is 'en').
    limit (int): The limit parameter for the API request, determining the number of records to fetch (default is 18).

    Raises:
    requests.exceptions.HTTPError: If the API request fails with an HTTP error.

    Example usage:
    PostgresHook(postgres_conn_id='some_database')
    collect_data_from_api(hook, license_id='US-CA', lang='es', limit=10)
    """

    url = 'https://your_link.com'
    params = {
        'licenseId': license_id,
        'lang': lang,
        'limit': limit
    }

    response = requests.get(url, params=params)

    # Check if the request was successful
    if response.status_code == 200:
        # Parse the JSON response
        data = response.json()
    else:
        response.raise_for_status()

    conn = hook.get_conn()
    cursor = conn.cursor()

    insert_data = (json.dumps(data),)
    insert_query = f"""
    INSERT INTO landing.api_data(raw) VALUES (%s)
    """

    try:
        cursor.execute(insert_query, insert_data)
        conn.commit()
        print("Data inserted successfully.")

    except Exception as e:
        conn.rollback()
        print(f"Error occurred: {e}")

    finally:
        cursor.close()
        conn.close()


