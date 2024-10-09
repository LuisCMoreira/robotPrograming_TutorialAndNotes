import socket
import time

# IP address and port of the robot controller
robot_ip = '10.0.0.1'  # Example IP address, replace with your robot's IP
robot_port = 30002  # Default port used by Universal Robots

# Create a TCP/IP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

try:
    # Connect to the robot controller
    sock.connect((robot_ip, robot_port))
    print("Connected to robot controller")

    # Send URScript command to power on the robot motors
    ur_script_command = "power_on()\n"
    sock.send(ur_script_command.encode())

    # Wait for a short time to allow the motors to start up
    time.sleep(1)

    # Send URScript command to release the brakes and enable motion
    ur_script_command = "set_freedrive(1)\n"  # This command enables "freedrive" mode
    sock.send(ur_script_command.encode())

    # Wait for a short time to allow the brakes to release
    time.sleep(1)

    print("Robot motors started and brakes released, robot enabled for motion")

finally:
    # Close the socket connection
    sock.close()
    print("Socket connection closed")
