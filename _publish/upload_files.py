import os
import base64
import hashlib
import requests
from urllib.parse import quote

UPLOAD_PASSWORD = os.getenv("CCTOOLS_UPLOAD_PASSWORD")  #

# Configuration
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SOURCE_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
BASE_URL = "https://publish-fragrant-cloud-3528.fly.dev"
UPLOAD_ENDPOINT = f"{BASE_URL}/upload"

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
                    server_files[parts[0]] = parts[1]
        return server_files
    else:
        print("Error retrieving file list from server:", response.status_code, response.text)
        return {}

def upload_file(filepath, relative_path, server_files):
    print(f"Uploading {relative_path}...")

    with open(filepath, "rb") as f:
        file_content = f.read()
    encoded_content = base64.b64encode(file_content).decode("utf-8")

    encoded_filename = url_encode(relative_path)
    encoded_data = url_encode(encoded_content)

    payload = f"password={UPLOAD_PASSWORD}&filename={encoded_filename}&data={encoded_data}"
    headers = {"Content-Type": "application/x-www-form-urlencoded"}

    response = requests.post(UPLOAD_ENDPOINT, data=payload, headers=headers)

    if response.status_code == 200:
        print(f"{relative_path} uploaded successfully.")
        return True  # Upload success

    elif response.status_code == 403:
        print("\n🚨 ERROR: Forbidden (403) - Invalid password! Stopping upload process.\n")
        exit(1)  # ❌ Immediate exit

    else:
        print(f"Error uploading {relative_path}. Server responded with: {response.status_code}\n{response.text}")
        return False  # General failure

def upload_all_files(source_dir):
    """Upload all files from the source directory using a bulk server file list."""
    server_files = get_server_file_list()
    uploaded_files = []  # List to store successfully uploaded/updated files

    for root, dirs, files in os.walk(source_dir):
        dirs[:] = [d for d in dirs if not (d.startswith(".") or d.startswith("_"))]
        for file in files:
            if file.startswith(".") or file.startswith("_"):
                continue

            filepath = os.path.join(root, file)
            relative_path = os.path.relpath(filepath, source_dir)

            local_md5 = calculate_md5(filepath)
            server_md5 = server_files.get(relative_path, None)

            if server_md5 and server_md5 == local_md5:
                print(f"Skipping {relative_path}, already up-to-date")
                continue  # Skip upload if MD5 is the same

            if upload_file(filepath, relative_path, server_files):
                uploaded_files.append(relative_path)

    if uploaded_files:
        print("\nUploaded/Updated Files:")
        for file in uploaded_files:
            print(f"- {file}")
    else:
        print("\nNo files needed to be uploaded.")

    print("\nAll file operations completed.")

if __name__ == "__main__":
    upload_all_files(SOURCE_DIR)
