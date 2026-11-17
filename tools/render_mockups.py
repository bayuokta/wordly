import json
import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parent.parent
SHOTS = [
    ("01-onboarding", "01-onboarding.png"),
    ("02-home", "02-home.png"),
    ("03-word-detail", "03-word-detail.png"),
    ("04-explore", "04-explore.png"),
    ("05-flashcard", "05-flashcard.png"),
    ("06-quiz", "06-quiz.png"),
    ("07-my-words", "07-my-words.png"),
    ("08-profile", "08-profile.png"),
]

OVERFLOW_JS = """() => {
  const screen = document.querySelector('.screen');
  const sr = screen.getBoundingClientRect();
  const problems = [];
  screen.querySelectorAll('.content *').forEach(el => {
    const r = el.getBoundingClientRect();
    if (r.height > 0) {
      const over = r.bottom - sr.top - 915;
      if (over > 1) problems.push(el.className + ' +' + Math.round(over) + 'px');
    }
  });
  return problems.slice(0, 6);
}"""


def render_screens(browser, out_dir, theme):
    out_dir.mkdir(parents=True, exist_ok=True)
    page = browser.new_page(viewport={"width": 560, "height": 1070}, device_scale_factor=3)
    page.emulate_media(reduced_motion="reduce")
    for slug, out in SHOTS:
        page.goto((ROOT / "src" / "screens" / f"{slug}.html").as_uri())
        if theme == "light":
            page.evaluate("() => document.querySelector('.screen').classList.add('light')")
        page.evaluate("() => document.fonts.ready.then(() => true)")
        page.wait_for_timeout(150)
        problems = page.evaluate(OVERFLOW_JS)
        if problems:
            print(f"  ! {theme}/{slug}: {problems}")
        page.locator(".phone").screenshot(path=str(out_dir / out))
        print(f"wrote {out_dir.relative_to(ROOT)}/{out}")
    page.close()


def render_board(browser, source, out):
    board = browser.new_page(viewport={"width": 1960, "height": 2230}, device_scale_factor=1.5)
    board.goto((ROOT / "src" / source).as_uri())
    board.evaluate("() => document.fonts.ready.then(() => true)")
    board.wait_for_load_state("networkidle")
    board.wait_for_timeout(300)
    board.screenshot(path=str(out))
    print(f"wrote {out.relative_to(ROOT)}")
    board.close()


def main():
    theme = sys.argv[1] if len(sys.argv) > 1 else "all"
    with sync_playwright() as p:
        browser = p.chromium.launch()
        if theme in ("dark", "all"):
            render_screens(browser, ROOT / "mockups", "dark")
            render_board(browser, "overview.html", ROOT / "mockups" / "00-overview.png")
        if theme in ("light", "all"):
            render_screens(browser, ROOT / "mockups" / "light", "light")
            render_board(
                browser,
                "overview-light.html",
                ROOT / "mockups" / "light" / "00-overview.png",
            )
        browser.close()

    report = {}
    for d in (ROOT / "mockups", ROOT / "mockups" / "light"):
        for f in sorted(d.glob("*.png")):
            report[str(f.relative_to(ROOT))] = f.stat().st_size
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
