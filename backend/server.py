from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import socket


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        response = {
            "message": "Hello from backend API",
            "service": "backend",
            "hostname": socket.gethostname()
        }

        body = json.dumps(response).encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


server = HTTPServer(("0.0.0.0", 8000), Handler)

print("Backend API listening on port 8000", flush=True)
server.serve_forever()