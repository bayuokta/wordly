"""Menyiapkan screenshot toko (1080x1920) dari tangkapan layar emulator."""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "docs" / "screenshots"
OUT = ROOT / "docs" / "store"

SHOTS = [
    ("29-onboarding.png", "01-onboarding.png"),
    ("30-home-setelah-onboarding.png", "02-home.png"),
    ("21-quiz-pilihan-ganda.png", "03-quiz.png"),
    ("15-flashcard-depan.png", "04-flashcard.png"),
    ("42-statistik-7-hari.png", "05-statistik.png"),
    ("13-practice-flashcard-siap.png", "06-latihan.png"),
]

TARGET = (1080, 1920)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for source, target in SHOTS:
        path = SRC / source
        if not path.exists():
            print(f"lewat: {source} tidak ada")
            continue
        image = Image.open(path).convert("RGB")
        # Potong bagian atas/bawah agar rasio 9:16 (syarat Play Store).
        width, height = image.size
        wanted_height = int(width * TARGET[1] / TARGET[0])
        if height > wanted_height:
            offset = (height - wanted_height) // 2
            image = image.crop((0, offset, width, offset + wanted_height))
        image = image.resize(TARGET, Image.LANCZOS)
        destination = OUT / target
        image.save(destination, optimize=True)
        print(f"{target}: {destination.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
