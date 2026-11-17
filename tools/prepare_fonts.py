import re
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FONT_DIR = ROOT / "src" / "assets" / "fonts"
CSS_OUT = ROOT / "src" / "assets" / "fonts.css"
UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
)
URL = (
    "https://fonts.googleapis.com/css2"
    "?family=Plus+Jakarta+Sans:wght@600;700;800"
    "&family=Inter:wght@400;500;600"
    "&family=Noto+Sans:wght@400;500"
    "&display=swap"
)

req = urllib.request.Request(URL, headers={"User-Agent": UA})
css = urllib.request.urlopen(req, timeout=30).read().decode("utf-8")

blocks = re.split(r"/\*\s*([\w-]+)\s*\*/", css)
out = []
seen = {}

for i in range(1, len(blocks), 2):
    subset, body = blocks[i], blocks[i + 1]
    if subset not in ("latin", "latin-ext"):
        continue
    family = re.search(r"font-family:\s*'([^']+)'", body).group(1)
    weight = re.search(r"font-weight:\s*(\d+)", body).group(1)
    url = re.search(r"url\((https://[^)]+\.woff2)\)", body).group(1)
    name = re.sub(r"[^a-z0-9]+", "-", family.lower()).strip("-")
    fname = f"{name}-{weight}-{subset}.woff2"
    target = FONT_DIR / fname
    if fname not in seen:
        data = urllib.request.urlopen(
            urllib.request.Request(url, headers={"User-Agent": UA}), timeout=30
        ).read()
        target.write_bytes(data)
        seen[fname] = len(data)
    out.append(body.replace(url, f"fonts/{fname}").strip())

CSS_OUT.write_text("\n\n".join(out) + "\n", encoding="utf-8")
for name, size in sorted(seen.items()):
    print(f"{name}  {size} bytes")
print(f"{len(seen)} font files")
