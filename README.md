# Hostel Management (Flask)

Minimal README to setup and run the project locally.

**Prerequisites**
- Python 3.10+ (3.13 used in development here)
- MySQL server installed and running

**Project structure**
- `app.py` - Flask application and API endpoints
- `schema.sql` - schema, procedures, triggers and sample data
- `templates/` - HTML templates served by the Flask app
- `requirements.txt` - Python dependencies

**Environment / Configuration**
The app reads DB config from `app.py`'s `DB_CONFIG` dict. You can override host/port/debug with environment variables when starting the server.

Recommended environment variables for running locally:

- `HOST` - host Flask listens on (default `127.0.0.1`)
- `PORT` - port Flask listens on (default `5001`)
- `FLASK_DEBUG` - `1|true` to enable debug auto-reload (development only)

Example DB credentials in `app.py`:

```py
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '1234@Abc',
    'database': 'hostel_management'
}
```

**Setup (recommended)**

```bash
# from project root
cd /path/to/hostel_management
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
```

**Initialize the database**

Option A - automatic (quick):

```bash
# ensure MySQL is running and DB credentials in app.py are correct
source .venv/bin/activate
python - <<'PY'
from app import init_database
init_database()
PY
```

Option B - manual:

```bash
# run the SQL in schema.sql using MySQL client or Workbench
mysql -u root -p < schema.sql
```

**Run the app**

```bash
# defaults to 127.0.0.1:5001
source .venv/bin/activate
python app.py
```

Override host/port if needed:

```bash
HOST=0.0.0.0 PORT=5001 FLASK_DEBUG=1 python app.py
```

Open the app in your browser: `http://127.0.0.1:5001/`

**Notes / Troubleshooting**
- If you see CORS errors when the page fetches `/api/*`, make sure the frontend is using relative paths (e.g. `/api/dashboard/stats`) and you're loading the updated HTML (hard-refresh to avoid cached JS).
- If MySQL reports foreign-key errors during imports (Error 1452), either:
  - Reorder inserts so parent rows exist before children, or
  - Run imports with `SET FOREIGN_KEY_CHECKS=0;` and re-enable afterwards (use with caution).
- For production, use a proper WSGI server (gunicorn/uvicorn) and lock down CORS to specific origins.

**What I changed while helping you**
- Cleaned up `requirements.txt` to keep only real package entries.
- Added this `README.md` with run & setup instructions.
- Several small fixes were applied to `app.py` and templates to make the app easier to run locally (host/port defaults, CORS fallback for dev, endpoint fixes).

If you'd like, I can:
- Revert the temporary dev CORS fallback in `app.py` and replace it with stricter config.
- Add a `Makefile` or simple shell script (`run.sh`) to automate venv creation, DB init and server start.
- Add a `dev` requirements file with test packages and `requests` for integration tests.

Tell me which of those you'd like next and I'll implement it.# hostel-management
