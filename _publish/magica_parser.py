import struct
import os
import sys
from collections import Counter

class VoxFileParser:
    def __init__(self, filepath):
        self.filepath = filepath
        self.voxels = []
        self.size = (0, 0, 0)

    def parse(self):
        file_size = os.path.getsize(self.filepath)
        with open(self.filepath, 'rb') as f:
            if f.read(4) != b'VOX ':  # Magic number
                raise ValueError("Not a valid VOX file.")

            f.seek(8)  # Skip version and magic
            while f.tell() < file_size:
                chunk_id = f.read(4).decode()
                chunk_size = struct.unpack('<I', f.read(4))[0]
                children_size = struct.unpack('<I', f.read(4))[0]

                if chunk_id == 'SIZE':
                    self.size = struct.unpack('<3I', f.read(12))

                elif chunk_id == 'XYZI':
                    num_voxels = struct.unpack('<I', f.read(4))[0]
                    self.voxels = [struct.unpack('<4B', f.read(4)) for _ in range(num_voxels)]

                else:
                    f.seek(chunk_size, 1)  # Skip unknown chunks

    def export_to_dat(self, output_path):
        length, width, height = self.size
        voxel_count = len(self.voxels)

        with open(output_path, 'wb') as f:
            # Write header
            f.write(struct.pack('<3I', length, width, height))  # Dimensions
            f.write(struct.pack('<I', voxel_count))  # Total voxel count

            # Write voxel data
            for voxel in self.voxels:
                f.write(struct.pack('<4B', *voxel))

        self.log_summary(output_path)

    def log_summary(self, output_path):
        length, width, height = self.size
        total_voxels = len(self.voxels)
        color_counts = Counter(voxel[3] for voxel in self.voxels)

        with open(output_path.replace('.dat', '.log'), 'w') as log_file:
            log_file.write(f"Model dimensions: {length}x{width}x{height}\n")
            log_file.write(f"Total voxels: {total_voxels}\n")
            log_file.write("Color usage (Minecraft palette):\n")
            for color, count in sorted(color_counts.items()):
                stacks = count // 64 + (1 if count % 64 > 0 else 0)
                log_file.write(f"  Color {color}: {count} voxels ({stacks} stack{'s' if stacks > 1 else ''})\n")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script.py <path_to_vox_file>")
        sys.exit(1)

    filepath = sys.argv[1]

    if not os.path.isfile(filepath):
        print(f"Error: File '{filepath}' does not exist.")
        sys.exit(1)

    output_path = os.path.splitext(filepath)[0] + ".dat"

    parser = VoxFileParser(filepath)
    parser.parse()
    parser.export_to_dat(output_path)
    print(f"Model exported to {output_path}")
