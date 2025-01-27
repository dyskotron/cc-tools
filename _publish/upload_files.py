import os
import base64
import requests

# Configuration
SOURCE_DIR = "/Users/matejosanec/IdeaProjects/cctToolbox"
SERVER_URL = "https://cooperative-whispering-jaborosa.glitch.me/upload"

def url_encode(data):
    """URL encode the given string."""
    from urllib.parse import quote
    return quote(data, safe="")

def upload_file(filepath):
    """Upload a single file to the server."""
    filename = os.path.basename(filepath)
    print(f"Uploading {filename}...")

    # Read and base64 encode the file content
    with open(filepath, "rb") as f:
        file_content = f.read()
    encoded_content = base64.b64encode(file_content).decode("utf-8")

    # URL encode the filename and content
    encoded_filename = url_encode(filename)
    encoded_data = url_encode(encoded_content)

    # Prepare the payload
    payload = f"filename={encoded_filename}&data={encoded_data}"
    headers = {"Content-Type": "application/x-www-form-urlencoded"}

    # Send the POST request
    response = requests.post(SERVER_URL, data=payload, headers=headers)

    if response.status_code == 200:
        print(f"{filename} uploaded successfully.")
    else:
        print(f"Error uploading {filename}. Server responded with: {response.status_code}\n{response.text}")

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
            upload_file(filepath)

    print("All files uploaded successfully.")

if __name__ == "__main__":
    upload_all_files(SOURCE_DIR)
