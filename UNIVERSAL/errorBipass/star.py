import socket
import time

def send_command(ip, port, command):
    # Create a socket object
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    
    # Connect to the device
    s.connect((ip, port))
    
    # Send the command
    s.sendall(command.encode())
    
    # Receive response (optional, depends on the device)
    response = s.recv(1024).decode()
    print(f"Received: {response}")

    # Close the socket
    s.close()

if __name__ == "__main__":
    # Define the target IP and port
    TARGET_IP = "10.0.0.1"
    TARGET_PORT = 29999
    


    time.sleep(100)


    # Define the command to send
    COMMAND = "unlock protective stop"

    # Send the command
    send_command(TARGET_IP, TARGET_PORT, COMMAND)

    time.sleep(2)

    COMMAND = "brake release"

    send_command(TARGET_IP, TARGET_PORT, COMMAND)

