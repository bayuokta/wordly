"""Membuat aset brand Wordly: ikon aplikasi + logo splash.

Warna mengikuti token design system (bg #0E1116, primary #7C9CFF).
Jalankan: python tool/make_brand_assets.py
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "branding"
FONT = ROOT / "assets" / "fonts" / "PlusJakartaSans-ExtraBold.ttf"

BG = (14, 17, 22)
GLOW = (124, 156, 255)
GRAD_TOP = (147, 172, 255)
GRAD_BOTTOM = (95, 127, 230)


def gradient_text(size: int, text: str, font: ImageFont.FreeTypeFont) -> Image.Image:
    """Huruf dengan gradien vertikal + bayangan halus."""
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).text((size / 2, size / 2), text, font=font, fill=255, anchor="mm")

    grad = Image.new("RGBA", (size, size))
    for y in range(size):
        ratio = y / max(size - 1, 1)
        color = tuple(
            round(GRAD_TOP[i] + (GRAD_BOTTOM[i] - GRAD_TOP[i]) * ratio) for i in range(3)
        )
        ImageDraw.Draw(grad).line([(0, y), (size, y)], fill=color + (255,))

    canvas.paste(grad, (0, 0), mask)
    return canvas


def glow(size: int, radius_ratio: float = 0.42) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    r = int(size * radius_ratio)
    cx, cy = size * 0.62, size * 0.3
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=GLOW + (70,))
    return layer.filter(ImageFilter.GaussianBlur(size * 0.16))


def build_icon(size: int = 1024) -> Image.Image:
    base = Image.new("RGBA", (size, size), BG + (255,))
    base.alpha_composite(glow(size))
    font = ImageFont.truetype(str(FONT), int(size * 0.56))
    base.alpha_composite(gradient_text(size, "W", font))
    return base


def build_foreground(size: int = 1024) -> Image.Image:
    """Adaptive icon: hanya huruf, area aman ~66%."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    font = ImageFont.truetype(str(FONT), int(size * 0.40))
    layer.alpha_composite(gradient_text(size, "W", font))
    return layer


def build_splash_logo(size: int = 640) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    font = ImageFont.truetype(str(FONT), int(size * 0.5))
    layer.alpha_composite(gradient_text(size, "W", font))
    return layer


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    icon = build_icon()
    # Ikon legacy Android/iOS tidak perlu sudut membulat: launcher memotongnya.
    icon.save(OUT / "app_icon.png")
    build_foreground().save(OUT / "app_icon_foreground.png")
    build_splash_logo().save(OUT / "splash_logo.png")

    # Pratinjau kecil untuk dokumentasi.
    preview = icon.resize((192, 192), Image.LANCZOS)
    preview.save(OUT / "app_icon_192.png")

    for name in ("app_icon.png", "app_icon_foreground.png", "splash_logo.png", "app_icon_192.png"):
        path = OUT / name
        print(f"{name:28} {path.stat().st_size / 1024:6.1f} KB")


if __name__ == "__main__":
    main()
