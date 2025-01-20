import struct
import sys
import os
import math

class MagicaVoxelParser:
    def __init__(self, filename):
        self.filename = filename
        self.voxel_count = 0
        self.used_colors = {}
        self.minecraft_palette = self._load_minecraft_palette()
        self.model_data = None  # Store a single model's data

    def _load_minecraft_palette(self):
        return [
            (255, 255, 255),  # White
            (255, 127, 0),    # Orange
            (255, 0, 255),    # Magenta
            (0, 127, 255),    # Light Blue
            (255, 255, 0),    # Yellow
            (0, 255, 0),      # Lime
            (255, 192, 203),  # Pink
            (128, 128, 128),  # Gray
            (192, 192, 192),  # Light Gray
            (0, 0, 255),      # Blue
            (0, 255, 255),    # Cyan
            (0, 255, 127),    # Green
            (127, 0, 255),    # Purple
            (139, 69, 19),    # Brown
            (255, 0, 0),      # Red
            (0, 0, 0)         # Black
        ]

    def _map_to_minecraft_palette(self, color_index):
        return (color_index % 16) + 1

    def parse(self):
        output_filename = self.filename.replace('.vox', '.dat')
        log_filename = self.filename.replace('.vox', '_report.log')

        with open(self.filename, 'rb') as file:
            self._verify_magic(file)
            self.model_data = self._process_chunks(file)

        self._write_binary_format(output_filename)
        self._write_log_file(log_filename)
        print(f"Exported to {output_filename}. Log written to {log_filename}.")

    def _verify_magic(self, file):
        magic = file.read(4)
        if magic != b'VOX ':
            raise ValueError("Not a valid MagicaVoxel .vox file")

    def _process_chunks(self, file):
        version = struct.unpack('<I', file.read(4))[0]
        print(f"File version: {version}")

        model_data = {
            'length': 0,
            'width': 0,
            'height': 0,
            'planes': [],
            'voxel_count': 0,
            'used_colors': {}
        }

        while chunk := self._read_chunk(file):
            chunk_id, content, children = chunk
            if chunk_id == b'MAIN':
                self._parse_main_chunk(content, children, model_data)

        return model_data

    def _read_chunk(self, file):
        chunk_id = file.read(4)
        if not chunk_id:
            return None

        content_size, children_size = struct.unpack('<II', file.read(8))
        content = file.read(content_size)
        children = file.read(children_size)

        return chunk_id, content, children

    def _parse_main_chunk(self, content, children, model_data):
        offset = 0
        while offset < len(children):
            child_id = children[offset:offset + 4]
            content_size, children_size = struct.unpack('<II', children[offset + 4:offset + 12])
            content = children[offset + 12:offset + 12 + content_size]
            offset += 12 + content_size + children_size

            if child_id == b'SIZE':
                self._parse_size_chunk(content, model_data)
            elif child_id == b'XYZI':
                self._parse_xyzi_chunk(content, model_data)

    def _parse_size_chunk(self, content, model_data):
        x, y, z = struct.unpack('<III', content[:12])
        model_data['length'] = x
        model_data['width'] = y
        model_data['height'] = z
        print(f"Model size: {x}x{y}x{z}")

    def _parse_xyzi_chunk(self, content, model_data):
        num_voxels = struct.unpack('<I', content[:4])[0]
        print(f"Number of voxels: {num_voxels}")
        model_data['voxel_count'] = num_voxels

        planes = {}
        used_colors = {}

        for i in range(num_voxels):
            x, y, z, color_index = struct.unpack('<BBBB', content[4 + i * 4:8 + i * 4])
            mc_color_index = self._map_to_minecraft_palette(color_index)

            used_colors[mc_color_index] = used_colors.get(mc_color_index, 0) + 1

            if z not in planes:
                planes[z] = {}
            if y not in planes[z]:
                planes[z][y] = []

            planes[z][y].append((x, mc_color_index))

        model_data['planes'] = planes
        model_data['used_colors'] = used_colors

    def _write_binary_format(self, output_filename):
        with open(output_filename, 'wb') as file:
            file.write(struct.pack('<III', self.model_data['length'], self.model_data['width'], self.model_data['height']))
            for z, rows in self.model_data['planes'].items():
                file.write(struct.pack('<I', z))
                for y, voxels in rows.items():
                    file.write(struct.pack('<I', y))
                    file.write(struct.pack('<I', len(voxels)))
                    for x, color_index in voxels:
                        file.write(struct.pack('<BB', x, color_index))

    def _write_log_file(self, log_filename):
        with open(log_filename, 'w') as log:
            log.write(f"Model dimensions: {self.model_data['length']}x{self.model_data['width']}x{self.model_data['height']}\n")
            log.write(f"Total voxels: {self.model_data['voxel_count']}\n")
            log.write("Color usage (Minecraft palette):\n")

            for color_index, count in sorted(self.model_data['used_colors'].items()):
                stacks = math.ceil(count / 64)
                color = self.minecraft_palette[color_index - 1]
                log.write(f"  Color {color_index} ({color}): {count} voxels ({stacks} stack{'s' if stacks > 1 else ''})\n")

# Example usage
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script.py <input_vox_file>")
        sys.exit(1)

    input_file = sys.argv[1]

    parser = MagicaVoxelParser(input_file)
    parser.parse()
