# Hostel Management System

A comprehensive web-based Hostel Management System built with Flask and MySQL. This application helps in managing various aspects of a hostel, including student allocations, room management, mess bookings, laundry services, and fee tracking.

## Features
- **Student Management**: Add, update, view, and delete student records along with their local guardian details.
- **Room Allocation**: Monitor room availability, allocate rooms to students, deallocate, or transfer students between rooms while respecting maximum room capacities.
- **Mess Management**: Track mess bookings for students and different mess options available in the hostel.
- **Laundry Submissions**: Manage laundry records and calculate charges based on the laundry package selected by students.
- **Fee Management**: Keep track of fees paid by students, including room fees, mess fees, and laundry charges.
- **Warden Dashboard**: Assign wardens to students and monitor their assignments.
- **Dashboard Statistics**: View overall statistics of the hostel such as total students, occupied rooms, revenue, and more.

## Technology Stack
- **Backend**: Python 3.10+, Flask, Flask-CORS
- **Database**: MySQL (utilizing Functions, Triggers, Views, and Stored Procedures for robust data integrity and business logic)
- **Frontend**: HTML, CSS, JavaScript (Templates)

## Database Architecture
The system uses advanced MySQL features:
- **Views**: For simplified retrieval of student room, mess, and warden data.
- **Functions**: To calculate available room slots and total paid fees per student.
- **Triggers**: Ensure data integrity during fee insertion, room allocation (capacity checks), and automatic fee generation for laundry/mess bookings.
- **Stored Procedures**: Encapsulate complex operations like transferring rooms, calculating monthly charges, and generating hostel reports.

## Setup Instructions

### Prerequisites
- Python 3.10+ (3.13 used in development here)
- MySQL server installed and running

### Installation Guide

1. **Clone the repository:**
   ```bash
   git clone https://github.com/puneeth-sarji/hostel-management.git
   cd hostel-management
   ```

2. **Environment Setup (Recommended):**
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   python -m pip install --upgrade pip setuptools wheel
   pip install -r requirements.txt
   ```

3. **Database Configuration:**
   - Ensure MySQL is running on your machine.
   - The app reads DB config from `app.py`'s `DB_CONFIG` dict.
   - Example DB credentials in `app.py`:
     ```python
     DB_CONFIG = {
         'host': 'localhost',
         'user': 'root', # your mysql username
         'password': 'Password#7', # your mysql password
         'database': 'hostel_management'
     }
     ```

4. **Initialize the Database:**
   
   Option A - automatic (quick):
   ```bash
   source .venv/bin/activate
   python - <<'PY'
   from app import init_database
   init_database()
   PY
   ```
   
   Option B - manual:
   ```bash
   mysql -u root -p < schema.sql
   ```

5. **Run the Application:**
   ```bash
   # defaults to 127.0.0.1:5001 (or 5000 based on app.py)
   source .venv/bin/activate
   python app.py
   ```
   *Override host/port if needed:*
   ```bash
   HOST=0.0.0.0 PORT=5001 FLASK_DEBUG=1 python app.py
   ```
   Open the app in your browser: `http://127.0.0.1:5000/`

## Notes / Troubleshooting
- If you see CORS errors when the page fetches `/api/*`, make sure the frontend is using relative paths (e.g. `/api/dashboard/stats`) and you're loading the updated HTML (hard-refresh to avoid cached JS).
- If MySQL reports foreign-key errors during imports (Error 1452), either:
  - Reorder inserts so parent rows exist before children, or
  - Run imports with `SET FOREIGN_KEY_CHECKS=0;` and re-enable afterwards (use with caution).
- For production, use a proper WSGI server (gunicorn/uvicorn) and lock down CORS to specific origins.

## API Documentation
The backend provides several RESTful endpoints. Key ones include:
- `GET /api/students`: Fetch all student records.
- `GET /api/rooms`: Fetch all available rooms.
- `GET /api/dashboard/stats`: Get hostel summary statistics.
- *Refer to `app.py` for all available endpoints and detailed payload structures.*

## License
This project is licensed under the MIT License.
