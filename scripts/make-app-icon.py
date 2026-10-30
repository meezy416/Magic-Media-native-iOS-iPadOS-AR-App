#!/usr/bin/env python3
"""Regenerate every AppIcon size in the asset catalog from one 1024x1024 master.

Usage:  python3 scripts/make-app-icon.py path/to/new-icon-1024.png

Reads MagicKettle/Assets.xcassets/AppIcon.appiconset/Contents.json, resizes the
master into each size that catalog declares, and overwrites the PNGs in place —
so Contents.json itself never changes and Xcode picks the new art up as-is.

App icons must be fully opaque: iOS applies the rounded-corner mask itself, and
an icon shipped with alpha is rejected at submission. Any transparency in the
master is flattened onto black here.
"""
import json
import pathlib
import sys

from PIL import Image

ICONSET = (
    pathlib.Path(__file__).resolve().parent.parent
    / "MagicKettle/Assets.xcassets/AppIcon.appiconset"
)


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2

    master_path = pathlib.Path(sys.argv[1])
    if not master_path.is_file():
        print(f"error: no such file: {master_path}")
        return 1

    master = Image.open(master_path)
    if master.size != (1024, 1024):
        print(f"error: master must be 1024x1024, got {master.size[0]}x{master.size[1]}")
        return 1

    # Flatten any alpha onto black so the shipped PNGs are fully opaque.
    if master.mode in ("RGBA", "LA", "P"):
        master = master.convert("RGBA")
        flat = Image.new("RGB", master.size, (0, 0, 0))
        flat.paste(master, mask=master.split()[-1])
        master = flat
        print("note: master had an alpha channel; flattened onto black")
    else:
        master = master.convert("RGB")

    contents = json.loads((ICONSET / "Contents.json").read_text())

    written = 0
    for entry in contents["images"]:
        filename = entry.get("filename")
        if not filename:
            continue  # unfilled slot in the catalog
        points = float(entry["size"].split("x")[0])
        scale = int(entry["scale"].rstrip("x"))
        px = round(points * scale)
        resized = master if px == 1024 else master.resize((px, px), Image.LANCZOS)
        resized.save(ICONSET / filename, "PNG", optimize=True)
        print(f"  {px:>4}px  {filename}")
        written += 1

    print(f"\nwrote {written} icon files to {ICONSET}")
    print("Open the project in Xcode and build — no catalog changes needed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
