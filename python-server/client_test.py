import socket

SERVER_IP = "127.0.0.1"
PORT = 5000

client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client.connect((SERVER_IP, PORT))

print("Connected to server")

print("""
1 - Get CPU Usage
2 - Get RAM Usage
3 - Get Battery Status
4 - Get Running Apps
5 - Lock Screen
6 - Shutdown PC
0 - Exit
""")

while True:
    command = input("Enter option: ")

    if command == "0":
        break

    client.send(command.encode())
    response = client.recv(4096)
    print("\nServer response:")
    print(response.decode())

client.close()
print("Connection closed")
