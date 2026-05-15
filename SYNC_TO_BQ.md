# Supabase to BigQuery Sync

Syncs data from Supabase PostgreSQL to BigQuery for analytics and reporting.

## Setup

### 1. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 2. Create `secrets.env` File

Copy `secrets.env.example` to `secrets.env` and fill in your credentials:

```bash
cp secrets.env.example secrets.env
```

Edit `secrets.env` with your actual credentials:
- **Supabase**: Connection details (user, password, host, port, db)
- **BigQuery**: GCP project ID
- **Google Cloud**: Path to service account JSON credentials file

### 3. Set Up Google Cloud Credentials

Download your BigQuery service account JSON file:
1. Go to Google Cloud Console
2. Create/select a service account
3. Generate a JSON key
4. Save it as `google_creds.json` in this directory

**⚠️ WARNING**: Never commit `google_creds.json` or `secrets.env` to git. They're already in `.gitignore`.

### 4. Run the Sync

```bash
python sync_to_bq.py
```

The script will:
- Validate all required configuration
- Connect to Supabase
- Fetch data from specified tables
- Upload to BigQuery `supabase_raw.*` datasets

## Configuration

Edit `secrets.env` to customize:

```env
SUPABASE_USER=postgres
SUPABASE_PASSWORD=your_password
SUPABASE_HOST=aws-1-eu-central-1.pooler.supabase.com
SUPABASE_PORT=5432
SUPABASE_DB=postgres

BIGQUERY_PROJECT_ID=your-gcp-project
BIGQUERY_CREDENTIALS_FILE=google_creds.json

# Optional: specify tables to sync (comma-separated)
# Leave empty to sync ALL tables automatically
TABLES_TO_SYNC=
```

### Auto-Detection (Default)

If `TABLES_TO_SYNC` is empty, the script will automatically detect and sync **all tables** in the public schema from Supabase. This means:
- ✅ New tables are automatically included without configuration changes
- ✅ No need to maintain a list of tables

### Manual Selection

To sync only specific tables, set `TABLES_TO_SYNC`:

```env
TABLES_TO_SYNC=users,lessons,progress
```

## Security

✅ Credentials are loaded from `secrets.env` (not in git)
✅ Service account JSON is external (`google_creds.json`)
✅ All sensitive files are in `.gitignore`

Never hardcode credentials in the script or commit secret files!
