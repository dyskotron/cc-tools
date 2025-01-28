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


    def do_POST(self):

        if self.path == '/upload':
            # Handle file upload

            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = urllib.parse.parse_qs(post_data.decode())

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
                            self.wfile.write("File {0} is up-to-date.".format(filename).encode())
                            return

                    # Save the file

                    with open(save_path, 'wb') as f:
                        f.write(file_data)
                        self.send_response(200)
                        self.end_headers()
                        self.wfile.write("File {0} uploaded successfully.".format(filename).encode())

                except Exception as e:
                    self.send_response(500)
                    self.end_headers()
                    self.wfile.write("Error processing file {0}: {1}".format(filename, e).encode())
            else:
                self.send_response(400)
                self.end_headers()
                self.wfile.write("{0}".format("Missing required fields in POST request.").encode())

        elif self.path == '/check_file':
            # Handle file existence and MD5 hash check

            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = urllib.parse.parse_qs(post_data.decode())

            filename = data.get('filename', [None])[0]

            if filename:
                save_dir = os.path.expanduser('~/ccraft/matejos')
                file_path = os.path.join(save_dir, filename)

                if os.path.exists(file_path):
                    md5 = calculate_md5(file_path)
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write('{{"md5": "{0}"}}'.format(md5).encode())
                else:
                    self.send_response(404)  # Not Found
                    self.end_headers()
                    self.wfile.write("{0}".format("File not found.").encode())
            else:
                self.send_response(400)
                self.end_headers()
                self.wfile.write("{0}".format("Filename is required.").encode())

        else:
            # Return a 404 for unrecognized paths
            self.send_response(404)
            self.end_headers()
            self.wfile.write("{0}".format("Unknown POST endpoint.").encode())

            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = urllib.parse.parse_qs(post_data.decode())

            filename = data.get('filename', [None])[0]

            if not filename:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b"Filename is required.")
                return


            save_dir = os.path.expanduser('~/ccraft/matejos')
            file_path = os.path.join(save_dir, filename)

            if os.path.exists(file_path):
                # Respond with success and file metadata
                self.send_response(200)
                self.end_headers()
                self.wfile.write(f"File exists: {filename}".encode())
            else:
                # Respond with file not found
                self.send_response(404)
                self.end_headers()
                self.wfile.write(b"File not found.")


# Start the server

# Start the server

def run(server_class=HTTPServer, handler_class=CustomHTTPRequestHandler, port=8010):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    logging.info('Starting server on port {0}...'.format(port))
    httpd.serve_forever()

if __name__ == '__main__':
    run()
