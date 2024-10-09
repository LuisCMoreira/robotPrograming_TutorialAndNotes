import socket

# IP address and port of the robot controller
robot_ip = '192.168.1.100'  # Example IP address, replace with your robot's IP
robot_port = 30002  # Default port used by Universal Robots

# Create a TCP/IP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

try:
    # Connect to the robot controller
    sock.connect((robot_ip, robot_port))
    print("Connected to robot controller")

    # Example URScript command to move the robot to a position
    ur_script_command = "movej([0.1, -0.2, 0.3, -2.0, 1.5, 0], a=1.4, v=0.25)\n"

    # Send the URScript command
    sock.send(ur_script_command.encode())

    # Optionally receive and print response from the robot
    # response = sock.recv(1024)
    # print("Received:", response.decode())

finally:
    # Close the socket connection
    sock.close()
    print("Socket connection closed")
