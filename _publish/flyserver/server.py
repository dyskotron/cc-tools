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

def list_files_recursive(directory):
    """Recursively lists files with their MD5 hashes."""
    files = []
    for root, _, filenames in os.walk(directory):
        for filename in filenames:
            filepath = os.path.join(root, filename)
            relative_path = os.path.relpath(filepath, directory)  # Get relative path
            file_md5 = calculate_md5(filepath)
            files.append(f"{relative_path}|{file_md5}")
    return files

class CustomHTTPRequestHandler(SimpleHTTPRequestHandler):

    def do_GET(self):
        """Handles GET requests."""
        if self.path == "/files":
            save_dir = "/data/matejos"
            try:
                os.makedirs(save_dir, exist_ok=True)

                files = list_files_recursive(save_dir)
                response_data = "\n".join(files)

                self.send_response(200)
                self.send_header('Content-type', 'text/plain')
                self.end_headers()
                self.wfile.write(response_data.encode())
            except Exception as e:
                logging.error(f"Error listing files: {e}")
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f"Error listing files: {e}".encode())

        elif self.path.startswith("/download?"):
            # Handle file download request
            query = urllib.parse.urlparse(self.path).query
            params = urllib.parse.parse_qs(query)
            filename = params.get("filename", [None])[0]

            if filename:
                save_dir = "/data/matejos"
                file_path = os.path.join(save_dir, filename)

                if os.path.exists(file_path):
                    try:
                        with open(file_path, "rb") as f:
                            file_data = f.read()
                        self.send_response(200)
                        self.send_header('Content-type', 'application/octet-stream')
                        self.send_header('Content-Disposition', f'attachment; filename="{filename}"')
                        self.end_headers()
                        self.wfile.write(file_data)
                    except Exception as e:
                        logging.error(f"Error reading file {filename}: {e}")
                        self.send_response(500)
                        self.end_headers()
                        self.wfile.write(f"Error reading file: {e}".encode())
                else:
                    logging.error(f"File not found: {file_path}")
                    self.send_response(404)
                    self.end_headers()
                    self.wfile.write(f"File {filename} not found.".encode())

    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        data = urllib.parse.parse_qs(post_data.decode())



        # Require password for uploads
        UPLOAD_PASSWORD = os.getenv("UPLOAD_PASSWORD")
        provided_password = data.get('password', [None])[0]
        if provided_password != UPLOAD_PASSWORD:
            self.send_response(403)
            self.end_headers()
            self.wfile.write(b"Forbidden: Invalid password.")
            return

        if self.path == "/upload":
            # Existing upload logic
            filename = data.get('filename', [None])[0]
            file_data = data.get('data', [None])[0]

            if filename and file_data:
                try:
                    # Decode file data
                    file_data = base64.b64decode(file_data)

                    # Set the save path
                    save_dir = "/data/matejos"
                    save_path = os.path.join(save_dir, filename)
                    os.makedirs(os.path.dirname(save_path), exist_ok=True)

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

def run(server_class=HTTPServer, handler_class=CustomHTTPRequestHandler, port=3000):
    server_address = ("0.0.0.0", port)
    httpd = server_class(server_address, handler_class)
    logging.info('Starting server on port {0}...'.format(port))
    httpd.serve_forever()

if __name__ == '__main__':
    run()