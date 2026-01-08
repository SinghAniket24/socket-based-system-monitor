import sqlite3
from datetime import datetime

DB_NAME = "system_data.db"

def get_connection():
    return sqlite3.connect(DB_NAME)

def init_db():
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
    CREATE TABLE IF NOT EXISTS alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        type TEXT,
        value REAL
    )
    """)

    cur.execute("""
    CREATE TABLE IF NOT EXISTS command_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        command TEXT,
        status TEXT
    )
    """)

    cur.execute("""
    CREATE TABLE IF NOT EXISTS usage_trends (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        cpu REAL,
        ram REAL
    )
    """)

    conn.commit()
    conn.close()

def log_alert(alert_type, value):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO alerts VALUES (NULL, ?, ?, ?)",
        (datetime.now().strftime("%Y-%m-%d %H:%M:%S"), alert_type, value)
    )
    conn.commit()
    conn.close()

def log_command(command, status):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO command_logs VALUES (NULL, ?, ?, ?)",
        (datetime.now().strftime("%Y-%m-%d %H:%M:%S"), command, status)
    )
    conn.commit()
    conn.close()

def log_usage(cpu, ram):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO usage_trends VALUES (NULL, ?, ?, ?)",
        (datetime.now().strftime("%Y-%m-%d %H:%M:%S"), cpu, ram)
    )
    conn.commit()
    conn.close()
    
def get_latest_alert():
    conn = get_connection()
    cur = conn.cursor()

    cur.execute(
        "SELECT timestamp, type, value FROM alerts ORDER BY id DESC LIMIT 1"
    )
    row = cur.fetchone()

    conn.close()

    if row:
        timestamp, alert_type, value = row
        return f"[{timestamp}] ALERT: {alert_type} = {value}"
    else:
        return ""
