#!/usr/bin/env python3
import struct
import sys
import os


def make_icns_icon(icc_type: bytes, png_data: bytes) -> bytes:
    return icc_type + struct.pack(">I", len(png_data) + 8) + png_data


def main():
    output_path = sys.argv[1]
    icon_dir = "Resources/AppIcon.appiconset"

    sizes = [
        (b"ic07", "icon_128x128.png"),
        (b"ic08", "icon_256x256.png"),
        (b"ic09", "icon_512x512.png"),
        (b"ic10", "icon_512x512@2x.png"),
        (b"ic11", "icon_16x16@2x.png"),
        (b"ic12", "icon_32x32@2x.png"),
        (b"ic13", "icon_128x128@2x.png"),
        (b"ic14", "icon_256x256@2x.png"),
        (b"icp4", "icon_16x16.png"),
        (b"icp5", "icon_32x32.png"),
    ]

    entries = b""
    for icns_type, filename in sizes:
        with open(os.path.join(icon_dir, filename), "rb") as f:
            png_data = f.read()
        entries += make_icns_icon(icns_type, png_data)

    total_len = 8 + len(entries)
    icns_data = b"icns" + struct.pack(">I", total_len) + entries

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "wb") as f:
        f.write(icns_data)
    print(f"Written {len(icns_data)} bytes to {output_path}")


if __name__ == "__main__":
    main()
