import socket

HOST = "127.0.0.1"
PORT = 4533

AZ = 0.0
EL = 0.0

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind((HOST, PORT))
server.listen(5)

print(f"Listening on {HOST}:{PORT}")
print("Waiting for SkyRoof...")

while True:
    conn, addr = server.accept()

    print(f"\nSkyRoof connected from {addr}")
    print("=" * 60)

    buffer = ""

    while True:
        data = conn.recv(4096)

        if not data:
            print("SkyRoof disconnected.")
            break

        buffer += data.decode("ascii", errors="replace")

        while "\n" in buffer:
            command, buffer = buffer.split("\n", 1)
            command = command.strip()

            if not command:
                continue

            print(f"RECEIVED: {command!r}")

            # Get current position
            if command == "p":
                response = f"{AZ:.6f}\n{EL:.6f}\n"
                conn.sendall(response.encode())

                print(f"  → Position: AZ={AZ:.3f}°  EL={EL:.3f}°")

            # Get status
            elif command == "S":
                conn.sendall(b"0\n")
                print("  → Status sent")

            # Set position
            elif command.startswith("P "):
                parts = command.split()

                if len(parts) >= 3:
                    try:
                        AZ = float(parts[1])
                        EL = float(parts[2])

                        print()
                        print("******** TARGET POSITION ********")
                        print(f"AZ = {AZ:.3f}°")
                        print(f"EL = {EL:.3f}°")
                        print("*********************************")
                        print()

                        conn.sendall(b"RPRT 0\n")

                    except ValueError:
                        conn.sendall(b"RPRT -1\n")

            # Stop
            elif command == "S":
                print("STOP command")

            else:
                print(f"  → Unknown command: {command!r}")

    conn.close()