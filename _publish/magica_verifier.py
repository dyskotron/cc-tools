import struct
import os
import sys

def verify_dat_file(file_path):
    try:
        file_size = os.path.getsize(file_path)
        print(f"Verifying file: {file_path} ({file_size} bytes)")

        with open(file_path, "rb") as f:
            # Read header (dimensions and voxel count)
            header_data = f.read(16)
            if len(header_data) < 16:
                raise ValueError("File is too small to contain a valid header.")
            length, width, height, voxel_count = struct.unpack("<4I", header_data)

            print(f"Dimensions: {length} x {width} x {height}")
            print(f"Voxel count: {voxel_count}")

            # Read color count
            color_count_data = f.read(4)
            if len(color_count_data) < 4:
                raise ValueError("File ended before reading color count.")
            color_count = struct.unpack("<I", color_count_data)[0]

            print(f"Color count: {color_count}")
            if color_count > 16:
                raise ValueError(f"Invalid color count: {color_count} (must be 16 or fewer).")

            # Read color definitions
            colors = []
            for i in range(color_count):
                color_data = f.read(4)
                if len(color_data) < 4:
                    raise ValueError("Unexpected EOF while reading color definitions.")
                index, r, g, b = struct.unpack("<BBBB", color_data)
                colors.append((index, r, g, b))
            print(f"Read {len(colors)} colors.")

            # Read voxel data
            voxel_data = []
            for i in range(voxel_count):
                voxel_entry = f.read(4)
                if len(voxel_entry) < 4:
                    raise ValueError(f"Unexpected EOF while reading voxel {i+1}/{voxel_count}.")
                x, y, z, color_index = struct.unpack("<BBBB", voxel_entry)
                voxel_data.append((x, y, z, color_index))

            print(f"Read {len(voxel_data)} voxels.")

            # Validate final file size
            expected_size = 16 + 4 + (color_count * 4) + (voxel_count * 4)
            if file_size != expected_size:
                raise ValueError(f"File size mismatch! Expected {expected_size} bytes, got {file_size}.")

            print("✅ File structure is valid!")

    except Exception as e:
        print(f"❌ Verification failed: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python magica_verifier.py <file.dat>")
    else:
        verify_dat_file(sys.argv[1])