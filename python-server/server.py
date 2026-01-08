import socket
from commands import *
from database import init_db, log_command, get_latest_alert

HOST = "0.0.0.0"   # Allow access from other devices
PORT = 5000


init_db()

# ================= CREATE SOCKET =================
server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind((HOST, PORT))
server.listen(5)

print("Server started...")
print(f"Listening on port {PORT}")

# ================= MAIN SERVER LOOP =================
while True:
    conn, addr = server.accept()
    client_ip = addr[0]
    print("Connected by:", addr)

    command = ""

    try:
        data = conn.recv(1024)
        if not data:
            conn.close()
            continue

        command = data.decode().strip()
        print("Command received:", command)

        # ---------- COMMAND HANDLING ----------
        if command == "0":
            response = "PONG"

        elif command == "1":
            response = get_cpu()

        elif command == "2":
            response = get_ram()

        elif command == "3":
            response = get_battery()

        elif command == "4":
            response = get_running_apps()

        elif command == "5":
            response = lock_screen()

        elif command == "6":
            response = shutdown_pc()

        elif command == "7":
            response = restart_pc()

        elif command == "8":
            response = get_disk_usage()

        elif command == "9":
            response = get_uptime()

        elif command == "10":
            response = get_os_info()

        elif command == "11":
            response = get_latest_alert()

        else:
            response = "Invalid command"

        log_command(command, "SUCCESS")

    except Exception as e:
        response = f"Error: {str(e)}"
        log_command(command, "FAILED")

    # ---------- SEND RESPONSE ----------
    try:
        conn.sendall((response + "\n").encode())
    except:
        pass

    conn.close()
