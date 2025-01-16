import os
from http.server import SimpleHTTPRequestHandler, HTTPServer
import urllib.parse
import base64
import logging

# Set up logging
#logging.basicConfig(level=logging.INFO)
logging.basicConfig(level=logging.ERROR)

# URL Encoding in Python
def url_encode(data):
    return urllib.parse.quote(data, safe='')

# URL Decoding in Python
def url_decode(data):
    return urllib.parse.unquote(data)

class CustomHTTPRequestHandler(SimpleHTTPRequestHandler):

    def list_files_recursive(self, directory):
        # Recursively list all files in the directory and subdirectories
        file_list = []
        for root, dirs, files in os.walk(directory):
            for file in files:
                file_list.append(os.path.relpath(os.path.join(root, file), directory))
        return file_list

    def do_POST(self):
        if self.path == '/upload':
            # Read the content length from the request header
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)

            # Parse the POST data
            data = urllib.parse.parse_qs(post_data.decode())

            # Debug: Print received data
            logging.debug("Received data: %s", data)

            filename = data.get('filename', [None])[0]
            file_data = data.get('data', [None])[0]

            logging.info(f"Processing: {filename}")

            # Check if filename and file data are present
            if filename and file_data:
                try:
                    # Decode file data from base64
                    file_data = base64.b64decode(file_data)
                    # base64.b64decode(file_data, validate=True)
                    # file_data = url_decode(file_data)

                    # Ensure the directory to save the file exists
                    script_dir = os.path.dirname(os.path.abspath(__file__))
                    save_dir = os.path.join(script_dir, 'cc_data')
                    os.makedirs(save_dir, exist_ok=True)

                    # Define the full path where the file should be saved
                    save_path = os.path.join(save_dir, filename)
                    # Ensure the directory structure for the file exists
                    os.makedirs(os.path.dirname(save_path), exist_ok=True)

                    logging.info(f"Saving file to: {save_path}")

                    # Save the file to disk
                    with open(save_path, 'wb') as f:
                        f.write(file_data)

                    logging.info(f"File {filename} uploaded successfully.")
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(f"File {filename} uploaded successfully.".encode())
                except Exception as e:
                    logging.error(f"[log] Error writing file  {filename} - {e}")
                    self.send_response(500)
                    self.end_headers()
                    self.wfile.write(f" [write] Error writing file {filename} - {e}".encode())
            else:
                logging.warning("Missing filename or file data.")
                self.send_response(400)
                self.end_headers()
                self.wfile.write("Missing filename or file data".encode())
        else:
            # Handle other requests with default behavior
            super().do_POST()

    def do_GET(self):
        # Handle file download and listing
        if self.path == '/files':
            # List all available files in the 'cc_data' folder, recursively
            script_dir = os.path.dirname(os.path.abspath(__file__))
            files_dir = os.path.join(script_dir, 'cc_data')
            try:
                files = self.list_files_recursive(files_dir)
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(','.join(files).encode())
            except Exception as e:
                logging.error(f"Error listing files: {e}")
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f"Error listing files: {e}".encode())

        elif self.path.startswith('/download'):
            # Handle file download
            file_name = self.path[len('/download/'):]  # Extract filename from URL
            file_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'cc_data', file_name)
            if os.path.exists(file_path):
                try:
                    with open(file_path, 'rb') as f:
                        file_data = f.read()
                        self.send_response(200)
                        self.send_header('Content-type', 'application/octet-stream')
                        self.send_header('Content-Disposition', f'attachment; filename={file_name}')
                        self.end_headers()
                        self.wfile.write(file_data)
                except Exception as e:
                    logging.error(f"Error reading file: {e}")
                    self.send_response(500)
                    self.end_headers()
                    self.wfile.write(f"Error reading file: {e}".encode())
            else:
                self.send_response(404)
                self.end_headers()
                self.wfile.write(f"File {file_name} not found.".encode())

        else:
            super().do_GET()

def run(server_class=HTTPServer, handler_class=CustomHTTPRequestHandler, port=8000):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    logging.info(f'Starting server on port {port}...')
    httpd.serve_forever()

if __name__ == '__main__':
    run()
