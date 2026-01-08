import sqlite3

DB_NAME = "system_data.db"

conn = sqlite3.connect(DB_NAME)
cur = conn.cursor()

print("\n================ RECENT ALERTS ================")
alerts = cur.execute("""
    SELECT timestamp, type, value
    FROM alerts
    ORDER BY timestamp DESC
    LIMIT 5
""").fetchall()

if alerts:
    for a in alerts:
        print(f"Time: {a[0]} | Type: {a[1]} | Value: {a[2]}%")
else:
    print("No alerts recorded")

print("\n============== COMMAND HISTORY ===============")
commands = cur.execute("""
    SELECT timestamp, command, status
    FROM command_logs
    ORDER BY timestamp DESC
""").fetchall()

if commands:
    for c in commands:
        print(f"Time: {c[0]} | Command: {c[1]} | Status: {c[2]}")
else:
    print("No command logs found")

print("\n============= USAGE TRENDS (Last 10) =========")
usage = cur.execute("""
    SELECT timestamp, cpu, ram
    FROM usage_trends
    ORDER BY timestamp DESC
    LIMIT 10
""").fetchall()

if usage:
    for u in usage:
        print(f"Time: {u[0]} | CPU: {u[1]}% | RAM: {u[2]}%")
else:
    print("No usage data found")

print("\n=========== USAGE SUMMARY (AVERAGE) ==========")
avg = cur.execute("""
    SELECT AVG(cpu), AVG(ram)
    FROM usage_trends
""").fetchone()

if avg and avg[0] is not None:
    print(f"Average CPU Usage: {round(avg[0],2)}%")
    print(f"Average RAM Usage: {round(avg[1],2)}%")
else:
    print("Not enough data for average")

conn.close()
