import struct
import os
import sys
from collections import Counter, defaultdict

class VoxFileParser:
    def __init__(self, filepath):
        self.filepath = filepath
        self.voxels = []
        self.size = (0, 0, 0)
        self.colors = []  # List of used colors with index, RGB value, and count

    def parse(self):
        file_size = os.path.getsize(self.filepath)
        with open(self.filepath, "rb") as f:
            if f.read(4) != b"VOX ":  # Magic number
                raise ValueError("Not a valid VOX file.")

            f.seek(8)  # Skip version and magic
            while f.tell() < file_size:
                chunk_id = f.read(4).decode()
                chunk_size = struct.unpack("<I", f.read(4))[0]
                children_size = struct.unpack("<I", f.read(4))[0]

                if chunk_id == "SIZE":
                    self.size = struct.unpack("<3I", f.read(12))

                elif chunk_id == "XYZI":
                    num_voxels = struct.unpack("<I", f.read(4))[0]
                    self.voxels = [struct.unpack("<4B", f.read(4)) for _ in range(num_voxels)]

                elif chunk_id == "RGBA":
                    self.palette = [struct.unpack("<4B", f.read(4)) for _ in range(256)]

                else:
                    f.seek(chunk_size, 1)  # Skip unknown chunks

        self._calculate_colors()

    def _calculate_colors(self):
        # Count usage of each color index
        color_counter = Counter(voxel[3] for voxel in self.voxels)

        # Create a list of used colors with their RGB values and counts
        for index, count in color_counter.items():
            r, g, b, a = self.palette[index - 1]  # Palette is 0-based
            if a > 0:  # Include only colors with non-zero alpha
                self.colors.append({"index": index, "rgb": (r, g, b), "count": count})

    def export_to_dat(self, output_path):
        length, width, height = self.size
        voxel_count = len(self.voxels)

        with open(output_path, "wb") as f:
            # Write header
            f.write(struct.pack("<3I", length, width, height))  # Dimensions
            f.write(struct.pack("<I", voxel_count))  # Total voxel count

            # Write color information
            f.write(struct.pack("<I", len(self.colors)))  # Number of used colors
            for color in self.colors:
                r, g, b = color["rgb"]
                f.write(struct.pack("<4B", color["index"], r, g, b))  # Index and RGB

            # Write voxel data
            for voxel in self.voxels:
                f.write(struct.pack("<4B", *voxel))

        self.log_summary(output_path)

    def log_summary(self, output_path):
        length, width, height = self.size
        total_voxels = len(self.voxels)

        print(f"Model dimensions: {length}x{width}x{height}")
        print(f"Total voxels: {total_voxels}")
        print("Used colors:")
        for color in self.colors:
            index, (r, g, b), count = color["index"], color["rgb"], color["count"]
            print(f"  Index {index}: RGB({r}, {g}, {b}), Used {count} times")

    def load_and_log_dat(self, dat_path):
        with open(dat_path, "rb") as f:
            # Read header
            length = struct.unpack("<I", f.read(4))[0]
            width = struct.unpack("<I", f.read(4))[0]
            height = struct.unpack("<I", f.read(4))[0]
            voxel_count = struct.unpack("<I", f.read(4))[0]

            print(f"Dimensions: {length}x{width}x{height}, Voxel count: {voxel_count}")

            # Read color information
            color_count = struct.unpack("<I", f.read(4))[0]
            print(f"Number of colors: {color_count}")
            for _ in range(color_count):
                index, r, g, b = struct.unpack("<4B", f.read(4))
                print(f"  Color Index {index}: RGB({r}, {g}, {b})")

            # Read voxels (optional logging)
            for _ in range(voxel_count):
                x, y, z, color = struct.unpack("<BBBB", f.read(4))
                print(f"  Voxel - X: {x}, Y: {y}, Z: {z}, Color Index: {color}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script.py <path_to_vox_file>")
        sys.exit(1)

    filepath = sys.argv[1]
    output_path = os.path.splitext(filepath)[0] + ".dat"

    parser = VoxFileParser(filepath)
    parser.parse()
    parser.export_to_dat(output_path)
    print(f"Model exported to {output_path}")

    # Test loading and logging the .dat file
    parser.load_and_log_dat(output_path)
