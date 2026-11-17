"""Membuat efek suara pendek (WAV) untuk Wordly.

Jalankan: python tool/make_sounds.py
Output: assets/sounds/{correct,wrong,streak}.wav
"""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "sounds"
RATE = 44100


def tone(freq: float, duration: float, volume: float = 0.35) -> list[float]:
    samples = int(RATE * duration)
    fade = int(RATE * 0.01)
    data = []
    for i in range(samples):
        envelope = 1.0
        if i < fade:
            envelope = i / fade
        elif i > samples - fade:
            envelope = max(0.0, (samples - i) / fade)
        data.append(volume * envelope * math.sin(2 * math.pi * freq * i / RATE))
    return data


def silence(duration: float) -> list[float]:
    return [0.0] * int(RATE * duration)


def write(name: str, samples: list[float]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    with wave.open(str(path), "w") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, value)) * 32767)) for value in samples
        )
        handle.writeframes(frames)
    print(f"{name:14} {path.stat().st_size // 1024} KB  {len(samples) / RATE:.2f}s")


def main() -> None:
    correct = tone(880, 0.09) + tone(1174.66, 0.12)
    wrong = tone(233.08, 0.16, volume=0.28) + tone(196.0, 0.18, volume=0.24)
    streak = tone(659.25, 0.08) + silence(0.02) + tone(830.61, 0.08) + silence(0.02) + tone(1046.5, 0.16)
    write("correct.wav", correct)
    write("wrong.wav", wrong)
    write("streak.wav", streak)


if __name__ == "__main__":
    main()
