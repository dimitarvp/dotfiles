"""shot.py PAGE_DIR OUT_DIR [FILE] [WIDTHS] [SCHEMES] — screenshots of a local page.

Runs inside the research-browser container in a headless Chromium of its own, with a fresh temporary
profile: never the research browser and never its profile. For each width and colour scheme it opens
PAGE_DIR/FILE in a new context, waits for the page and its fonts, and saves a full-page
OUT_DIR/WIDTH-SCHEME.png. OUT_DIR/report.json holds per shot the viewport width, the page's
scrollWidth and clientWidth (unequal means sideways overflow), its console errors and failed requests.
FILE defaults to index.html; WIDTHS and SCHEMES are comma-separated, by default 390,1280 and light,dark.

Exit codes: 0 done · 1 bad usage · 6 the render failed
"""

import enum
import itertools
import json
import os
import pathlib
import sys

from playwright.sync_api import Error as PlaywrightError
from playwright.sync_api import sync_playwright

CHROMIUM = "/usr/bin/chromium"
SCHEMES = ("light", "dark")
MIN_WIDTH, MAX_WIDTH = 200, 3840
PHONE_BELOW = 600  # narrower viewports render at scale 2, as a phone screen does


class Outcome(enum.IntEnum):
    DONE = 0
    USAGE = 1
    RENDER_FAILED = 6


class Usage(Exception):
    pass


def parse(args):
    """Return (page file path, out dir, [(width, scheme), ...]) from the command line."""
    if not 2 <= len(args) <= 5:
        raise Usage("expected PAGE_DIR OUT_DIR [FILE] [WIDTHS] [SCHEMES]")
    page_dir, out_dir, *given = args
    file, widths, schemes = given + ["index.html", "390,1280", "light,dark"][len(given) :]
    root = os.path.realpath(page_dir)
    path = os.path.realpath(os.path.join(root, file))
    if not path.startswith(root + os.sep):
        raise Usage(f"FILE {file!r} is outside the page folder")
    try:
        width_list = [int(w) for w in widths.split(",")]
    except ValueError:
        raise Usage(f"WIDTHS {widths!r} is not a comma-separated list of numbers") from None
    if not all(MIN_WIDTH <= w <= MAX_WIDTH for w in width_list):
        raise Usage(f"WIDTHS {widths!r}: each width is {MIN_WIDTH} to {MAX_WIDTH}")
    scheme_list = schemes.split(",")
    if not all(s in SCHEMES for s in scheme_list):
        raise Usage(f"SCHEMES {schemes!r}: each scheme is light or dark")
    return path, out_dir, list(itertools.product(width_list, scheme_list))


def shoot(browser, url, width, scheme, out_dir):
    phone = width < PHONE_BELOW
    ctx = browser.new_context(
        viewport={"width": width, "height": 844 if phone else 800},
        device_scale_factor=2 if phone else 1,
        color_scheme=scheme,
    )
    page = ctx.new_page()
    errors, failed = [], []
    page.on("console", lambda m: errors.append(m.text) if m.type == "error" else None)
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.on("requestfailed", lambda r: failed.append(f"{r.url} {r.failure}"))
    page.on("response", lambda r: failed.append(f"{r.url} HTTP {r.status}") if r.status >= 400 else None)
    try:
        page.goto(url, wait_until="load", timeout=60000)
        try:
            page.wait_for_load_state("networkidle", timeout=15000)
        except PlaywrightError:
            pass
        page.evaluate("document.fonts.ready.then(() => null)")
        scroll_width, client_width = page.evaluate(
            "[document.documentElement.scrollWidth, document.documentElement.clientWidth]"
        )
        png = f"{width}-{scheme}.png"
        page.screenshot(path=os.path.join(out_dir, png), full_page=True)
    finally:
        ctx.close()
    return {
        "png": png,
        "width": width,
        "scheme": scheme,
        "scrollWidth": scroll_width,
        "clientWidth": client_width,
        "consoleErrors": errors,
        "failedRequests": failed,
    }


def main():
    try:
        path, out_dir, shots = parse(sys.argv[1:])
    except Usage as e:
        print(f"shot: {e}\nusage: {__doc__.splitlines()[0]}", file=sys.stderr)
        return Outcome.USAGE
    if not os.path.isfile(path):
        print(f"shot: no such file in the page folder: {os.path.basename(path)}", file=sys.stderr)
        return Outcome.RENDER_FAILED
    os.makedirs(out_dir, exist_ok=True)
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(executable_path=CHROMIUM, chromium_sandbox=True)
            report = [shoot(browser, pathlib.Path(path).as_uri(), w, s, out_dir) for w, s in shots]
            browser.close()
    except Exception as e:  # any failure here is a failed render to the caller, never a usage error
        print(f"shot: render failed: {type(e).__name__}: {str(e).splitlines()[0][:200]}", file=sys.stderr)
        return Outcome.RENDER_FAILED
    with open(os.path.join(out_dir, "report.json"), "w") as f:
        json.dump(report, f, indent=1)
    overflow = [r["png"] for r in report if r["scrollWidth"] > r["clientWidth"]]
    print(f"shot: {len(report)} screenshots of {os.path.basename(path)}; sideways overflow: {', '.join(overflow) or 'none'}")
    return Outcome.DONE


if __name__ == "__main__":
    sys.exit(int(main()))
