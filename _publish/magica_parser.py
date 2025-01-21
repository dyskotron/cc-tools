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

    def test_dat_file(self, dat_path):
        with open(dat_path, 'rb') as f:
            # Read header
            length = struct.unpack('<I', f.read(4))[0]
            width = struct.unpack('<I', f.read(4))[0]
            height = struct.unpack('<I', f.read(4))[0]
            voxel_count = struct.unpack('<I', f.read(4))[0]

            print(f"Dimensions: {length}x{width}x{height}, Voxel count: {voxel_count}")

            # Read and group voxels by Z-layer
            layers = {}
            for _ in range(voxel_count):
                x, y, z, color = struct.unpack('<BBBB', f.read(4))
                if z not in layers:
                    layers[z] = []
                layers[z].append((x, y, z, color))

            # Print grouped voxels
            for z in sorted(layers):
                print(f"LAYER {z}:")
                for voxel in layers[z]:
                    x, y, z, color = voxel
                    print(f"  Voxel - X: {x}, Y: {y}, Z: {z}, Color: {color}")

            # Find minimum and maximum voxels
            all_voxels = [voxel for layer in layers.values() for voxel in layer]
            min_voxel = min(all_voxels, key=lambda v: (v[2], v[1], v[0]))
            max_voxel = max(all_voxels, key=lambda v: (v[2], v[1], v[0]))

            print(f"Lowest voxel: X: {min_voxel[0]}, Y: {min_voxel[1]}, Z: {min_voxel[2]}")
            print(f"Highest voxel: X: {max_voxel[0]}, Y: {max_voxel[1]}, Z: {max_voxel[2]}")

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

    # Test the .dat file
    parser.test_dat_file(output_path)
