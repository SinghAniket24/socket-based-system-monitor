# Socket-Based System Monitor

A system monitoring application built using a Python socket server and a Flutter mobile app.  
The mobile app communicates with the Python server over a network to request and display system information.

---

## Overview

This project consists of:
- A **Python socket server** that handles client connections and executes system-related commands
- A **database layer** to store command logs and system usage data
- A **Flutter mobile application** that acts as a client and interacts with the server

The goal of the project is to demonstrate socket-based communication between a server and a mobile application.

---

## Python Socket Server

The Python server:
- Listens for incoming socket connections
- Accepts predefined command codes from the client
- Returns system information such as CPU usage, RAM usage, uptime, disk usage, and OS details
- Logs command activity and usage data in a database

Location:  
`python-server/`

---

## Mobile Application

The mobile application:
- Built using Flutter
- Connects to the Python server using sockets
- Sends commands and displays responses from the server
- Provides a simple interface for monitoring system status remotely

Location:  
`mobile-app/`

---

## Database

The database is used to:
- Store command execution logs
- Track command status (success or failure)
- Maintain historical system usage records

The database is managed entirely by the Python server.

---

## Communication Flow

1. Mobile app sends a command to the server  
2. Python server processes the request  
3. Server fetches system data or performs the action  
4. Result is sent back to the mobile app  
5. Command details are logged in the database

---

## Technologies Used

- Python (Socket Programming)
- Flutter (Mobile Application)
- Database integration for logging and monitoring
