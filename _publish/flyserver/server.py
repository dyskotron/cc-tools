import os
from http.server import SimpleHTTPRequestHandler, HTTPServer
import urllib.parse
import base64
import hashlib
import logging


def calculate_md5(filepath):
    """Calculate the MD5 hash of a file."""
    hasher = hashlib.md5()
    with open(filepath, "rb") as f:
        chunk = f.read(8192)
        while chunk:
            hasher.update(chunk)
            chunk = f.read(8192)
    return hasher.hexdigest()

class CustomHTTPRequestHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/files":
            # Define the directory containing files
            save_dir = os.path.expanduser("~/ccraft/matejos")

            try:
                # Ensure the directory exists
                os.makedirs(save_dir, exist_ok=True)

                # Recursively list all files and maintain directory structure
                file_list = []
                for root, _, files in os.walk(save_dir):
                    for file in files:
                        # Preserve the full path relative to the base directory
                        rel_path = os.path.relpath(os.path.join(root, file), save_dir)
                        file_list.append(rel_path)

                # Send response
                self.send_response(200)
                self.send_header("Content-type", "text/plain")
                self.end_headers()
                self.wfile.write("\n".join(file_list).encode())

            except Exception as e:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f"Error listing files: {e}".encode())


    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        data = urllib.parse.parse_qs(post_data.decode())

        if self.path == "/check_file":
            # Handle file existence and MD5 hash check
            filename = data.get('filename', [None])[0]

            if filename:
                save_dir = os.path.expanduser('~/ccraft/matejos')
                file_path = os.path.join(save_dir, filename)

                if os.path.exists(file_path):
                    md5 = calculate_md5(file_path)
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(f'{{"md5": "{md5}"}}'.encode())
                else:
                    self.send_response(404)  # Not Found
                    self.end_headers()
                    self.wfile.write(b"File not found.")
            else:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"Filename is required.")

        elif self.path == "/upload":
            # Existing upload logic
            filename = data.get('filename', [None])[0]
            file_data = data.get('data', [None])[0]
            md5_hash = data.get('md5', [None])[0]

            if filename and file_data and md5_hash:
                try:
                    # Decode file data
                    file_data = base64.b64decode(file_data)

                    # Set the save path
                    save_dir = os.path.expanduser('~/ccraft/matejos')
                    save_path = os.path.join(save_dir, filename)
                    os.makedirs(os.path.dirname(save_path), exist_ok=True)

                    # Check for existing file and compare hashes
                    if os.path.exists(save_path):
                        server_md5 = calculate_md5(save_path)
                        if server_md5 == md5_hash:
                            self.send_response(304)  # Not Modified
                            self.end_headers()
                            self.wfile.write(f"File {filename} is up-to-date.".encode())
                            return

                    # Save the file
                    with open(save_path, 'wb') as f:
                        f.write(file_data)
                        self.send_response(200)
                        self.end_headers()
                        self.wfile.write(f"File {filename} uploaded successfully.".encode())

                except Exception as e:
                    self.send_response(500)
                    self.end_headers()
                    self.wfile.write(f"Error processing file {filename}: {e}".encode())

            else:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"Missing required fields in POST request.")

        else:
            # Return a 404 for unrecognized paths
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"Unknown POST endpoint.")

# Start the server

# Start the server

def run(server_class=HTTPServer, handler_class=CustomHTTPRequestHandler, port=3000):
    server_address = ("0.0.0.0", port)
    httpd = server_class(server_address, handler_class)
    logging.info('Starting server on port {0}...'.format(port))
    httpd.serve_forever()

if __name__ == '__main__':
    run()
