import socket

# IP address and port of the robot controller
robot_ip = '10.0.0.1'  # Example IP address, replace with your robot's IP
robot_port = 30002  # Default port used by Universal Robots

# Create a TCP/IP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

try:
    # Connect to the robot controller
    sock.connect((robot_ip, robot_port))
    print("Connected to robot controller")

    # Send URScript command to get the robot's current joint positions
    ur_script_command = "get_actual_joint_positions()\n"
    sock.send(ur_script_command.encode())

    # Receive response from the robot controller
    response = sock.recv(1024).decode()#.strip()
    print(response)

    # Parse the response to extract joint positions
    if response.startswith('[') and response.endswith(']'):
        joint_positions = [float(pos) for pos in response[1:-1].split(',')]
        print("Robot joint positions:", joint_positions)
    else:
        print("Invalid response received:", response)

finally:
    # Close the socket connection
    sock.close()
    print("Socket connection closed")
