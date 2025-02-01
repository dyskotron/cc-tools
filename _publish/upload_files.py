import os
import base64
import hashlib
import requests
from urllib.parse import quote

# Configuration
SOURCE_DIR = "/Users/matejosanec/IdeaProjects/cctToolbox"
BASE_URL = "https://publish-fragrant-cloud-3528.fly.dev"
UPLOAD_ENDPOINT = f"{BASE_URL}/upload"
# The per-file check endpoint is no longer needed:
# CHECK_FILE_ENDPOINT = f"{BASE_URL}/check_file"

def calculate_md5(filepath):
    """Calculate the MD5 hash of a file."""
    hasher = hashlib.md5()
    with open(filepath, "rb") as f:
        while chunk := f.read(8192):
            hasher.update(chunk)
    return hasher.hexdigest()

def url_encode(data):
    """URL encode the given string."""
    return quote(data, safe="")

def get_server_file_list():
    """
    Retrieve the full list of files from the server.
    The server returns a plain text response with one line per file,
    in the format "relative_path|file_size".
    """
    response = requests.get(f"{BASE_URL}/files")
    if response.status_code == 200:
        server_files = {}
        for line in response.text.splitlines():
            if "|" in line:
                parts = line.split("|")
                if len(parts) == 2:
                    # parts[0] is the relative file path, parts[1] is its size
                    server_files[parts[0]] = int(parts[1])
        return server_files
    else:
        print("Error retrieving file list from server:", response.status_code, response.text)
        return {}

def upload_file(filepath, relative_path, server_files):
    """Upload a single file if it differs from the server copy."""
    print(f"Processing {relative_path}...")

    # Instead of calling the check_file endpoint per file,
    # compare local file size with the value from the bulk file list.
    local_size = os.path.getsize(filepath)
    if relative_path in server_files and server_files[relative_path] == local_size:
        print(f"Skipping {relative_path}, identical file already exists on the server.")
        return

    # Even though we use file size to decide, we still calculate MD5 for the payload.
    local_md5 = calculate_md5(filepath)
    print(f"Uploading {relative_path}...")

    # Read and base64 encode the file content.
    with open(filepath, "rb") as f:
        file_content = f.read()
    encoded_content = base64.b64encode(file_content).decode("utf-8")

    # URL encode filename and content.
    encoded_filename = url_encode(relative_path)
    encoded_data = url_encode(encoded_content)

    # Prepare the payload including the MD5 hash.
    payload = f"filename={encoded_filename}&data={encoded_data}&md5={local_md5}"
    headers = {"Content-Type": "application/x-www-form-urlencoded"}

    response = requests.post(UPLOAD_ENDPOINT, data=payload, headers=headers)
    if response.status_code == 200:
        print(f"{relative_path} uploaded successfully.")
    else:
        print(f"Error uploading {relative_path}. Server responded with: {response.status_code}\n{response.text}")

def upload_all_files(source_dir):
    """Upload all files from the source directory using a bulk server file list."""
    # Retrieve the complete list of files (and their sizes) from the server.
    server_files = get_server_file_list()

    for root, dirs, files in os.walk(source_dir):
        # Skip hidden and _-prefixed directories.
        dirs[:] = [d for d in dirs if not (d.startswith(".") or d.startswith("_"))]
        for file in files:
            # Skip hidden and _-prefixed files.
            if file.startswith(".") or file.startswith("_"):
                continue
            filepath = os.path.join(root, file)
            # Maintain folder structure via relative path.
            relative_path = os.path.relpath(filepath, source_dir)
            upload_file(filepath, relative_path, server_files)

    print("All files uploaded successfully.")

if __name__ == "__main__":
    upload_all_files(SOURCE_DIR)
