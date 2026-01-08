import psutil
import os
import platform
import socket
from datetime import datetime
from database import log_alert, log_usage

# ================= THRESHOLDS =================
CPU_THRESHOLD = 80
RAM_THRESHOLD = 80

# ================= FIXED SYSTEM INFO (FETCH ONCE) =================
SYSTEM_INFO = {
    "hostname": socket.gethostname(),
    "os": f"{platform.system()} {platform.release()}",
    "boot_time": datetime.fromtimestamp(psutil.boot_time()),
    "cpu_physical": psutil.cpu_count(logical=False),
    "cpu_logical": psutil.cpu_count(logical=True),
}

# ================= HELPERS =================
def now():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# ================= DYNAMIC METRICS =================
def get_cpu():
    cpu = psutil.cpu_percent(interval=1)
    ram = psutil.virtual_memory().percent
    log_usage(cpu, ram)

    if cpu > CPU_THRESHOLD:
        log_alert("CPU", cpu)
        return f"[{now()}] ALERT: High CPU Usage - {cpu}%"

    return f"[{now()}] CPU Usage: {cpu}%"

def get_ram():
    cpu = psutil.cpu_percent(interval=1)
    ram = psutil.virtual_memory().percent
    log_usage(cpu, ram)

    if ram > RAM_THRESHOLD:
        log_alert("RAM", ram)
        return f"[{now()}] ALERT: High RAM Usage - {ram}%"

    return f"[{now()}] RAM Usage: {ram}%"

def get_battery():
    battery = psutil.sensors_battery()
    if battery:
        return (
            f"[{now()}] Battery: {battery.percent}%, "
            f"Charging: {battery.power_plugged}"
        )
    return f"[{now()}] No battery detected"

def get_running_apps():
    apps = []
    for proc in psutil.process_iter(['name']):
        try:
            if proc.info['name']:
                apps.append(proc.info['name'])
        except:
            pass

    apps = list(set(apps))[:10]
    return f"[{now()}] Running Apps:\n" + ", ".join(apps)

def get_disk_usage():
    disk = psutil.disk_usage('/')
    return (
        f"[{now()}] Disk Usage: "
        f"{disk.percent}% used "
        f"({disk.used // (1024**3)}GB / {disk.total // (1024**3)}GB)"
    )

def get_uptime():
    uptime_seconds = (
        datetime.now() - SYSTEM_INFO["boot_time"]
    ).total_seconds()

    hours = int(uptime_seconds // 3600)
    minutes = int((uptime_seconds % 3600) // 60)

    return f"[{now()}] System Uptime: {hours} hrs {minutes} mins"

# ================= FIXED INFO (CACHED) =================
def get_os_info():
    return (
        f"[{now()}]\n"
        f"Hostname: {SYSTEM_INFO['hostname']}\n"
        f"OS: {SYSTEM_INFO['os']}\n"
        f"CPU Cores: "
        f"{SYSTEM_INFO['cpu_physical']} Physical / "
        f"{SYSTEM_INFO['cpu_logical']} Logical\n"
        f"Boot Time: {SYSTEM_INFO['boot_time']}"
    )

# ================= CONTROL ACTIONS =================
def lock_screen():
    if platform.system() == "Windows":
        os.system("rundll32.exe user32.dll,LockWorkStation")
        return f"[{now()}] Screen locked"
    return f"[{now()}] Lock screen not supported"

def shutdown_pc():
    if platform.system() == "Windows":
        os.system("shutdown /s /t 5")
        return f"[{now()}] PC shutting down in 5 seconds"
    return f"[{now()}] Shutdown not supported"

def restart_pc():
    if platform.system() == "Windows":
        os.system("shutdown /r /t 5")
        return f"[{now()}] PC restarting in 5 seconds"
    return f"[{now()}] Restart not supported"
