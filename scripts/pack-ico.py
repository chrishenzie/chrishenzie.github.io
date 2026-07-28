"""Pack PNGs into an ICO, one frame per input.

ImageMagick can write the ICO directly, but its writer stores frames as
uncompressed BMP, about five times the size for the same three frames.
"""

import struct
import sys

PNG_MAGIC = b"\x89PNG\r\n\x1a\n"


def dimensions(png):
    if not png.startswith(PNG_MAGIC):
        raise ValueError("not a PNG")
    # IHDR is the first chunk: 8-byte magic, 4-byte length, 4-byte type.
    width, height = struct.unpack(">II", png[16:24])
    if not (0 < width <= 256 and 0 < height <= 256):
        raise ValueError(f"{width}x{height} does not fit an ICO frame")
    return width, height


def main(out_path, png_paths):
    frames = [open(p, "rb").read() for p in png_paths]
    header = struct.pack("<HHH", 0, 1, len(frames))
    offset = len(header) + 16 * len(frames)
    directory = b""
    for frame in frames:
        width, height = dimensions(frame)
        # 0 means 256 in the directory's single-byte size fields.
        directory += struct.pack(
            "<BBBBHHII", width % 256, height % 256, 0, 0, 1, 32, len(frame), offset
        )
        offset += len(frame)
    with open(out_path, "wb") as out:
        out.write(header + directory + b"".join(frames))


if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(f"usage: {sys.argv[0]} OUT.ico IN.png [IN.png ...]")
    main(sys.argv[1], sys.argv[2:])
