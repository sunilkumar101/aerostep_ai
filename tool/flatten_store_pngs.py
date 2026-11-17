"""Play Console rejects alpha in screenshots / feature graphic: flatten them to 24-bit RGB.

Run after tool/store_assets_render_test.dart:
    python tool/flatten_store_pngs.py
"""
import glob

from PIL import Image

files = glob.glob("store_assets/play/screenshots/*.png") + ["store_assets/play/feature_graphic_1024x500.png"]
for f in files:
    Image.open(f).convert("RGB").save(f, optimize=True)
    print("RGB", f)
