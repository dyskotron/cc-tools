import os
import base64
import hashlib
import requests

# Configuration
SOURCE_DIR = "/Users/matejosanec/IdeaProjects/cctToolbox"

BASE_URL = "https://publish-fragrant-cloud-3528.fly.dev"
UPLOAD_ENDPOINT = f"{BASE_URL}/upload"
CHECK_FILE_ENDPOINT = f"{BASE_URL}/check_file"

def calculate_md5(filepath):
    """Calculate the MD5 hash of a file."""
    hasher = hashlib.md5()
    with open(filepath, "rb") as f:
        while chunk := f.read(8192):
            hasher.update(chunk)
    return hasher.hexdigest()

def url_encode(data):
    """URL encode the given string."""
    from urllib.parse import quote
    return quote(data, safe="")

def upload_file(filepath, relative_path):
    """Upload a single file to the server."""
    print(f"Processing {relative_path}...")

    # Calculate the file's MD5 hash
    local_md5 = calculate_md5(filepath)

    # Check if the file exists on the server and compare hashes
    response = requests.post(CHECK_FILE_ENDPOINT, data={"filename": relative_path})
    if response.status_code == 200:
        server_md5 = response.json().get("md5")
        if server_md5 == local_md5:
            print(f"Skipping {relative_path}, identical file already exists on the server.")
            return
    elif response.status_code != 404:
        print(f"Error checking file {relative_path}: {response.status_code}\n{response.text}")
        return

    print(f"Uploading {relative_path}...")

    # Read and base64 encode the file content
    with open(filepath, "rb") as f:
        file_content = f.read()
    encoded_content = base64.b64encode(file_content).decode("utf-8")

    # URL encode the filename (including relative path) and content
    encoded_filename = url_encode(relative_path)
    encoded_data = url_encode(encoded_content)

    # Prepare the payload with the MD5 hash
    payload = f"filename={encoded_filename}&data={encoded_data}&md5={local_md5}"
    headers = {"Content-Type": "application/x-www-form-urlencoded"}

    # Send the POST request
    response = requests.post(UPLOAD_ENDPOINT, data=payload, headers=headers)

    if response.status_code == 200:
        print(f"{relative_path} uploaded successfully.")
    else:
        print(f"Error uploading {relative_path}. Server responded with: {response.status_code}\n{response.text}")

def upload_all_files(source_dir):
    """Upload all files from the source directory."""
    for root, dirs, files in os.walk(source_dir):
        # Skip hidden and _-prefixed directories
        dirs[:] = [d for d in dirs if not (d.startswith(".") or d.startswith("_"))]

        for file in files:
            # Skip hidden and _-prefixed files
            if file.startswith(".") or file.startswith("_"):
                continue

            filepath = os.path.join(root, file)
            # Calculate the relative path to maintain the folder structure
            relative_path = os.path.relpath(filepath, source_dir)
            upload_file(filepath, relative_path)

    print("All files uploaded successfully.")

if __name__ == "__main__":
    upload_all_files(SOURCE_DIR)
