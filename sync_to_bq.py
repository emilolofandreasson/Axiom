# -*- coding: utf-8 -*-
"""
Sync Supabase data to BigQuery
Created on Sun May 10 22:34:01 2026
@author: EmilOlofAndreasson
"""

import os
import sys
from urllib.parse import quote_plus
import pandas as pd
from sqlalchemy import create_engine, text
from google.oauth2 import service_account
from dotenv import load_dotenv

# Load secrets.env if running locally (override=True ensures Spyder doesn't cache old values)
# In GitHub Actions, environment variables are injected directly — no file needed
if os.path.exists('secrets.env'):
    load_dotenv('secrets.env', override=True)
elif not os.getenv('SUPABASE_USER'):
    print("ERROR: secrets.env file not found and no environment variables set!")
    print("Locally: create secrets.env based on secrets.env.example")
    print("GitHub Actions: add secrets in repo Settings → Secrets and variables → Actions")
    sys.exit(1)

# Load configuration from environment variables
SUPABASE_USER = os.getenv('SUPABASE_USER')
SUPABASE_PASSWORD = os.getenv('SUPABASE_PASSWORD')
SUPABASE_HOST = os.getenv('SUPABASE_HOST')
SUPABASE_PORT = os.getenv('SUPABASE_PORT', '5432')
SUPABASE_DB = os.getenv('SUPABASE_DB', 'postgres')
BIGQUERY_PROJECT_ID = os.getenv('BIGQUERY_PROJECT_ID')
BIGQUERY_CREDENTIALS_FILE = os.getenv('BIGQUERY_CREDENTIALS_FILE', 'google_creds.json')
TABLES_TO_SYNC_CONFIG = os.getenv('TABLES_TO_SYNC', '')

# Validate required configuration
missing = []
if not SUPABASE_USER: missing.append('SUPABASE_USER')
if not SUPABASE_PASSWORD: missing.append('SUPABASE_PASSWORD')
if not SUPABASE_HOST: missing.append('SUPABASE_HOST')
if not BIGQUERY_PROJECT_ID: missing.append('BIGQUERY_PROJECT_ID')
if not os.path.exists(BIGQUERY_CREDENTIALS_FILE):
    missing.append(f'BIGQUERY_CREDENTIALS_FILE ({BIGQUERY_CREDENTIALS_FILE})')

if missing:
    print(f"ERROR: Missing configuration: {', '.join(missing)}")
    print("Update secrets.env with the required values")
    sys.exit(1)

# URL-encode user and password to handle special characters (e.g. !, @, etc.)
encoded_user = quote_plus(SUPABASE_USER)
encoded_password = quote_plus(SUPABASE_PASSWORD)

# Build Supabase connection string
SUPABASE_CONN = f"postgresql+psycopg2://{encoded_user}:{encoded_password}@{SUPABASE_HOST}:{SUPABASE_PORT}/{SUPABASE_DB}"


# Debug: Show connection info (without exposing password)
print(f"Connecting to: {SUPABASE_HOST}:{SUPABASE_PORT}/{SUPABASE_DB}")
print(f"User: {SUPABASE_USER}")
print(f"Password length: {len(SUPABASE_PASSWORD)} chars")

# Create connection
engine = create_engine(SUPABASE_CONN)

def get_all_tables():
    """Fetch all user tables from Supabase database."""
    try:
        with engine.connect() as conn:
            query = text("""
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public'
                AND table_type = 'BASE TABLE'
                ORDER BY table_name
            """)
            result = conn.execute(query)
            tables = [row[0] for row in result.fetchall()]
            return tables
    except Exception as e:
        print(f"ERROR: Could not fetch tables from database: {e}")
        sys.exit(1)

# Determine which tables to sync
if TABLES_TO_SYNC_CONFIG.strip():
    # If explicitly configured, use those tables
    tables_to_sync = [t.strip() for t in TABLES_TO_SYNC_CONFIG.split(',')]
    print(f"Syncing configured tables: {tables_to_sync}")
else:
    # Otherwise, auto-detect all tables from Supabase
    tables_to_sync = get_all_tables()
    print(f"Auto-detected {len(tables_to_sync)} tables: {tables_to_sync}")

def sync():
    """Sync Supabase tables to BigQuery."""
    for table in tables_to_sync:
        print(f"Attempting to fetch data from: {table}...")

        try:
            # Step 1: Fetch from Supabase
            raw_conn = engine.raw_connection()
            query = f"SELECT * FROM {table}"
            df = pd.read_sql(query, raw_conn)
            raw_conn.close()

            print(f"Success! Fetched {len(df)} rows from Supabase.")

            # Step 2: Load BigQuery credentials
            credentials = service_account.Credentials.from_service_account_file(
                BIGQUERY_CREDENTIALS_FILE
            )

            # Convert UUID to string for BigQuery
            if 'id' in df.columns:
                df['id'] = df['id'].astype(str)

            # Step 3: Send to BigQuery
            print(f"Sending data to BigQuery...")
            df.to_gbq(
                destination_table=f'supabase_raw.{table}',
                project_id=BIGQUERY_PROJECT_ID,
                if_exists='replace',
                credentials=credentials
            )

            print(f"✓ Data synced to BigQuery 'supabase_raw.{table}'")

        except Exception as e:
            print(f"ERROR: Failed to sync {table}: {e}")
            sys.exit(1)

if __name__ == "__main__":
    sync()