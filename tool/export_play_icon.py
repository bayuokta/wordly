"""Ekspor ikon 512x512 untuk Google Play dari aset brand."""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "branding" / "app_icon.png"
OUT = ROOT / "assets" / "branding" / "play_store_icon_512.png"


def main() -> None:
    icon = Image.open(SRC).convert("RGB")
    resized = icon.resize((512, 512), Image.LANCZOS)
    resized.save(OUT, optimize=True)
    print(f"{OUT.name}: {resized.size[0]}x{resized.size[1]}, {OUT.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
