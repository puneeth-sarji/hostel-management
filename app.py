from flask import Flask, render_template, request, jsonify, redirect, url_for
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
from datetime import datetime
import os

app = Flask(__name__)
CORS(app)

# Database Configuration
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'Password#7',
    'database': 'hostel_management'
}

def get_db_connection():
    """Create and return a database connection"""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        return connection
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

def init_database():
    """(unchanged) Initialize the database from schema.sql with support for triggers/functions."""
    try:
        connection = mysql.connector.connect(
            host=DB_CONFIG['host'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password']
        )
        cursor = connection.cursor()

        cursor.execute("CREATE DATABASE IF NOT EXISTS hostel_management")
        cursor.execute("USE hostel_management")

        sql_path = 'schema.sql'
        if not os.path.exists(sql_path):
            print(f"schema.sql not found at {sql_path}. Skipping initialization.")
            return

        with open(sql_path, 'r', encoding='utf-8') as f:
            sql_file = f.read()

        statements = []
        temp = ""
        delimiter = ";"

        for line in sql_file.splitlines():
            stripped = line.strip()

            # detect DELIMITER change
            if stripped.lower().startswith("delimiter"):
                delimiter = stripped.split()[1]
                continue

            temp += line + "\n"

            # check if the statement ends with the current delimiter
            if stripped.endswith(delimiter):
                # remove delimiter
                stmt = temp.strip().removesuffix(delimiter).strip()
                if stmt:
                    statements.append(stmt)
                temp = ""

        # Execute each statement
        for statement in statements:
            try:
                cursor.execute(statement)
            except Exception as e:
                print("Error executing SQL statement:")
                print(statement)
                print("Error:", e)
                raise e

        connection.commit()
        print("Database initialized successfully!")

    except Error as e:
        print("Database initialization failed:", e)

    finally:
        try:
            cursor.close()
            connection.close()
        except:
            pass

# Routes for serving HTML pages (unchanged)
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/students')
def students_page():
    return render_template('students.html')

@app.route('/rooms')
def rooms_page():
    return render_template('rooms.html')

@app.route('/mess')
def mess_page():
    return render_template('mess.html')

@app.route('/wardens')
def wardens_page():
    return render_template('wardens.html')

@app.route('/laundry')
def laundry_page():
    return render_template('laundry.html')

@app.route('/fees')
def fees_page():
    return render_template('fee.html')


# -----------------
# API Endpoints (now using stored procedures where available)
# -----------------

# Fees endpoint (keeps JOIN to include student name)
@app.route('/api/fees', methods=['GET'])
def get_fees():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("""
            SELECT 
                f.p_id,
                f.p_date,
                f.p_method,
                f.amount,
                s.s_id,
                CONCAT(s.f_name, ' ', IFNULL(s.m_name,''), ' ', s.l_name) AS student_name
            FROM fees f
            LEFT JOIN student_room_fees srf ON f.p_id = srf.p_id
            LEFT JOIN student s ON srf.s_id = s.s_id
            ORDER BY f.p_date DESC
        """)
        rows = cursor.fetchall()
        return jsonify(rows)
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Laundry submissions (kept select)
@app.route('/api/laundry/submissions', methods=['GET'])
def get_laundry_submissions():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("""
            SELECT 
                gl.s_id AS student_id,
                CONCAT(s.f_name, ' ', s.l_name) AS student_name,
                gl.l_no AS service_name,
                l.days_of_laundry AS days,
                (l.days_of_laundry * l.rate_per_day) AS cost,
                gl.submission_date AS date
            FROM gives_laundry gl
            JOIN student s ON gl.s_id = s.s_id
            JOIN laundry l ON gl.l_no = l.l_no
            ORDER BY gl.submission_date DESC
        """)
        rows = cursor.fetchall()
        return jsonify(rows)
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()


# Students API (list) — unchanged (keeps existing joins)
@app.route('/api/students', methods=['GET'])
def get_students():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("""
            SELECT s.*, 
                   srf.r_no, 
                   f.amount as fees_paid, 
                   f.p_date,
                   f.p_method,
                   m.m_name as mess_name,
                   lg.name as guardian_name,
                   lg.p_no as guardian_phone
            FROM student s
            LEFT JOIN student_room_fees srf ON s.s_id = srf.s_id
            LEFT JOIN fees f ON srf.p_id = f.p_id
            LEFT JOIN books_mess bm ON s.s_id = bm.s_id
            LEFT JOIN mess m ON bm.m_no = m.m_no
            LEFT JOIN local_guardian lg ON s.s_id = lg.s_id
        """)
        students = cursor.fetchall()
        return jsonify(students)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Rooms - list available rooms using stored procedure sp_list_available_rooms
@app.route('/api/rooms', methods=['GET'])
def get_rooms():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        # CALLS: sp_list_available_rooms()
        cursor.execute("CALL sp_list_available_rooms()")
        rows = cursor.fetchall()

        # If the procedure returns multiple result sets or leaves a pending result,
        # make sure to consume remaining result sets (safe pattern).
        try:
            while cursor.nextset():
                pass
        except:
            pass

        return jsonify(rows)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Filled rooms endpoint - uses stored procedure sp_list_filled_rooms
@app.route('/api/rooms/filled', methods=['GET'])
def get_filled_rooms():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = connection.cursor(dictionary=True)
        # CALLS: sp_list_filled_rooms()
        cursor.execute("CALL sp_list_filled_rooms()")
        filled_rooms = cursor.fetchall()
        try:
            while cursor.nextset():
                pass
        except:
            pass
        return jsonify(filled_rooms)
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()


# Get single student using stored procedure sp_get_student_details
@app.route('/api/students/<student_id>', methods=['GET'])
def get_student(student_id):
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        # CALLS: sp_get_student_details(s_id)
        cursor.execute("CALL sp_get_student_details(%s)", (student_id,))
        rows = cursor.fetchall()

        # consume remaining result sets if any
        try:
            while cursor.nextset():
                pass
        except:
            pass

        if not rows:
            return jsonify({'error': 'Student not found'}), 404
        # Procedure returns a comprehensive row (or multiple rows if designed so)
        return jsonify(rows[0])
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Add student — kept raw INSERT (no stored proc exists)
@app.route('/api/students', methods=['POST'])
def add_student():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        data = request.json
        cursor = connection.cursor()

        cursor.execute("""
            INSERT INTO student (s_id, f_name, m_name, l_name, p_no, leader_id)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (data['s_id'], data['f_name'], data.get('m_name'),
              data['l_name'], data['p_no'], data.get('leader_id')))

        # Insert local guardian if provided
        if 'guardian_name' in data and 'guardian_phone' in data:
            cursor.execute("""
                INSERT INTO local_guardian (s_id, name, p_no)
                VALUES (%s, %s, %s)
                ON DUPLICATE KEY UPDATE name = VALUES(name)
            """, (data['s_id'], data['guardian_name'], data['guardian_phone']))

        connection.commit()
        return jsonify({'message': 'Student added successfully'}), 201
    except Error as e:
        connection.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Update student — kept raw UPDATE (no stored proc exists)
@app.route('/api/students/<student_id>', methods=['PUT'])
def update_student(student_id):
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        data = request.json
        cursor = connection.cursor()

        cursor.execute("""
            UPDATE student 
            SET f_name = %s, m_name = %s, l_name = %s, p_no = %s, leader_id = %s
            WHERE s_id = %s
        """, (data['f_name'], data.get('m_name'), data['l_name'],
              data['p_no'], data.get('leader_id'), student_id))

        connection.commit()
        return jsonify({'message': 'Student updated successfully'})
    except Error as e:
        connection.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Delete student — kept raw DELETE
@app.route('/api/students/<student_id>', methods=['DELETE'])
def delete_student(student_id):
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor()
        cursor.execute("DELETE FROM student WHERE s_id = %s", (student_id,))
        connection.commit()
        return jsonify({'message': 'Student deleted successfully'})
    except Error as e:
        connection.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Get room occupants via stored procedure sp_get_room_occupants
@app.route('/api/rooms/<room_no>/students', methods=['GET'])
def get_room_students(room_no):
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        # CALLS: sp_get_room_occupants(p_room_no)
        cursor.execute("CALL sp_get_room_occupants(%s)", (room_no,))
        rows = cursor.fetchall()
        try:
            while cursor.nextset():
                pass
        except:
            pass
        return jsonify(rows)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Room availability (keeps using function)
@app.route('/api/rooms/<room_no>/available', methods=['GET'])
def get_room_available_slots(room_no):
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    try:
        cursor = connection.cursor()
        cursor.execute("SELECT room_available_slots(%s) as available", (room_no,))
        row = cursor.fetchone()
        available = row[0] if row else 0
        return jsonify({'r_no': room_no, 'available_slots': int(available)})
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Allocate room — remains as raw SQL because there's no dedicated 'allocate' stored proc.
@app.route('/api/rooms/allocate', methods=['POST'])
def allocate_room():
    """
    Allocates a room to a student:
    - creates a fees record
    - inserts student_room_fees row (triggers will update room occupancy and validate)
    NOTE: trigger will reject allocation if room is full or student already allocated.
    """
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        data = request.json
        cursor = connection.cursor()

        # Compose a unique fee id
        from uuid import uuid4
        fee_id = f"F{uuid4().hex[:18].upper()}"

        # Start transaction
        cursor.execute("START TRANSACTION")

        # Create fee record
        cursor.execute("""
            INSERT INTO fees (p_id, p_date, p_method, amount)
            VALUES (%s, %s, %s, %s)
        """, (fee_id, datetime.now().date(), data['p_method'], data['amount']))

        # Allocate room (insert triggers will update occupancy and validate capacity/student allocation)
        cursor.execute("""
            INSERT INTO student_room_fees (s_id, r_no, p_id, allotment_date)
            VALUES (%s, %s, %s, %s)
        """, (data['s_id'], data['r_no'], fee_id, datetime.now().date()))

        connection.commit()
        return jsonify({'message': 'Room allocated successfully'}), 201
    except Error as e:
        connection.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Deallocate room — kept raw DELETE (no stored proc exists)
@app.route('/api/rooms/deallocate', methods=['POST'])
def deallocate_room():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        data = request.json
        cursor = connection.cursor()
        cursor.execute("START TRANSACTION")

        cursor.execute("""
            DELETE FROM student_room_fees
            WHERE s_id = %s AND r_no = %s
        """, (data['s_id'], data['r_no']))

        if cursor.rowcount == 0:
            connection.rollback()
            return jsonify({'error': 'Allocation not found'}), 404

        connection.commit()
        return jsonify({'message': 'Deallocated successfully'})
    except Error as e:
        connection.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Endpoint to transfer student between rooms using stored procedure sp_transfer_student_room
@app.route('/api/rooms/transfer', methods=['POST'])
def transfer_room():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    try:
        data = request.json
        cursor = connection.cursor()
        # CALLS: sp_transfer_student_room(s_id, new_room_no)
        cursor.execute("CALL sp_transfer_student_room(%s, %s)", (data['s_id'], data['new_r_no']))
        connection.commit()
        # consume any leftover resultsets
        try:
            while cursor.nextset():
                pass
        except:
            pass
        return jsonify({'message': 'Student transferred successfully'})
    except Error as e:
        connection.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Mess API (list) - raw SELECT (no SP for listing mess)
@app.route('/api/mess', methods=['GET'])
def get_mess():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT * FROM mess")
        mess = cursor.fetchall()
        return jsonify(mess)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Mess booking - uses stored procedure sp_change_mess_booking
@app.route('/api/mess/book', methods=['POST'])
def book_mess():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        data = request.json
        cursor = connection.cursor()
        # CALLS: sp_change_mess_booking(s_id, m_no)
        cursor.execute("CALL sp_change_mess_booking(%s, %s)", (data['s_id'], data['m_no']))
        connection.commit()
        try:
            while cursor.nextset():
                pass
        except:
            pass
        return jsonify({'message': 'Mess booked successfully'}), 201
    except Error as e:
        connection.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Wardens API (kept as raw SQL)
@app.route('/api/wardens', methods=['GET'])
def get_wardens():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("""
            SELECT w.*, COUNT(m.s_id) as student_count
            FROM warden w
            LEFT JOIN monitors m ON w.w_id = m.w_id
            GROUP BY w.w_id
        """)
        wardens = cursor.fetchall()
        return jsonify(wardens)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

@app.route('/api/wardens/<warden_id>/students', methods=['GET'])
def get_warden_students(warden_id):
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("""
            SELECT s.*, m.assigned_date
            FROM student s
            JOIN monitors m ON s.s_id = m.s_id
            WHERE m.w_id = %s
        """, (warden_id,))
        students = cursor.fetchall()
        return jsonify(students)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Laundry API - list (raw SELECT)
@app.route('/api/laundry', methods=['GET'])
def get_laundry():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT * FROM laundry")
        laundry = cursor.fetchall()
        return jsonify(laundry)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Submit laundry - uses stored procedure sp_submit_laundry
@app.route('/api/laundry/submit', methods=['POST'])
def submit_laundry():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        data = request.json
        cursor = connection.cursor()
        # CALLS: sp_submit_laundry(s_id, l_no)
        cursor.execute("CALL sp_submit_laundry(%s, %s)", (data['s_id'], data['l_no']))
        connection.commit()
        try:
            while cursor.nextset():
                pass
        except:
            pass
        return jsonify({'message': 'Laundry submitted successfully'}), 201
    except Error as e:
        connection.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Student payments (uses function) — unchanged
@app.route('/api/students/<student_id>/payments', methods=['GET'])
def get_student_payments(student_id):
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    try:
        cursor = connection.cursor()
        cursor.execute("SELECT student_total_paid(%s) as total", (student_id,))
        row = cursor.fetchone()
        total = float(row[0]) if row and row[0] is not None else 0.0
        return jsonify({'s_id': student_id, 'total_paid': total})
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# New endpoint: call stored procedure sp_calculate_student_monthly_charges(s_id, month, year)
@app.route('/api/students/<student_id>/monthly_charges', methods=['GET'])
def get_student_monthly_charges(student_id):
    """
    Query params expected: ?month=MM&year=YYYY
    Calls stored procedure sp_calculate_student_monthly_charges
    """
    month = request.args.get('month', type=int)
    year = request.args.get('year', type=int)
    if not month or not year:
        return jsonify({'error': 'month and year query parameters required (e.g. ?month=1&year=2025)'}), 400

    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)
        # CALLS: sp_calculate_student_monthly_charges(s_id, month, year)
        cursor.execute("CALL sp_calculate_student_monthly_charges(%s, %s, %s)", (student_id, month, year))
        rows = cursor.fetchall()
        try:
            while cursor.nextset():
                pass
        except:
            pass
        # Procedure returns a single row (mess_fee, laundry_charges, total_charges, total_paid, balance)
        if not rows:
            return jsonify({'error': 'No data returned'}), 404
        return jsonify(rows[0])
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Assign warden — kept as raw SQL (can be changed to procedure if created)
@app.route('/api/wardens/assign', methods=['POST'])
def assign_warden():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        data = request.json
        cursor = connection.cursor()

        # Remove any existing assignment for this student
        cursor.execute("DELETE FROM monitors WHERE s_id = %s", (data['s_id'],))

        # Add new assignment
        cursor.execute("""
            INSERT INTO monitors (w_id, s_id, assigned_date)
            VALUES (%s, %s, CURDATE())
        """, (data['w_id'], data['s_id']))

        connection.commit()
        return jsonify({'message': 'Warden assigned successfully'})

    except Exception as e:
        connection.rollback()
        return jsonify({'error': str(e)}), 500

    finally:
        cursor.close()
        connection.close()

# Dashboard Statistics — unchanged (keeps raw queries)
@app.route('/api/dashboard/stats', methods=['GET'])
def get_dashboard_stats():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500

    try:
        cursor = connection.cursor(dictionary=True)

        stats = {}

        # Total students
        cursor.execute("SELECT COUNT(*) as count FROM student")
        stats['total_students'] = cursor.fetchone()['count']

        # Total rooms
        cursor.execute("SELECT COUNT(*) as count FROM room")
        stats['total_rooms'] = cursor.fetchone()['count']

        # Occupied rooms
        cursor.execute("SELECT COUNT(*) as count FROM room WHERE no_of_people > 0")
        stats['occupied_rooms'] = cursor.fetchone()['count']

        # Total revenue
        cursor.execute("SELECT SUM(amount) as total FROM fees")
        result = cursor.fetchone()
        stats['total_revenue'] = float(result['total']) if result['total'] else 0

        # Mess bookings
        cursor.execute("SELECT COUNT(*) as count FROM books_mess")
        stats['mess_bookings'] = cursor.fetchone()['count']

        return jsonify(stats)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

# Generate hostel report using stored procedure sp_generate_hostel_report
@app.route('/api/report', methods=['GET'])
def generate_report():
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    try:
        cursor = connection.cursor(dictionary=True)
        # CALLS: sp_generate_hostel_report()
        cursor.execute("CALL sp_generate_hostel_report()")
        rows = cursor.fetchall()
        try:
            while cursor.nextset():
                pass
        except:
            pass
        return jsonify(rows)
    except Error as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        connection.close()

if __name__ == '__main__':
    # Uncomment the line below to initialize database on first run
    # init_database()
    app.run(debug=True, host='0.0.0.0', port=5000)
