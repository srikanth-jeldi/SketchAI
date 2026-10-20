"""Rebuild bundled WebP display assets from the retained PNG masters.
Requires Pillow with WebP support. Run from the repository root.
Masks are generated/verified separately with Flutter so its decoder matches runtime.
"""
from pathlib import Path
from PIL import Image

for source in sorted(Path("assets/artwork").glob("*.png")):
    with Image.open(source) as image:
        image.save(source.with_suffix(".webp"), quality=80, method=6)
for source in sorted(Path("assets/branding").glob("sketluma*.png")):
    with Image.open(source) as image:
        image.save(source.with_suffix(".webp"), quality=90, method=6)
