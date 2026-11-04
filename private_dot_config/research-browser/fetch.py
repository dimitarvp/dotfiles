"""fetch.py URL OUTFILE — read one page through the research browser.

Runs inside the research-browser container. Connects over CDP to the Chromium the container
started, opens the page in a new tab, waits out a bot challenge in front of it, and writes the
HTML to OUTFILE and the visible text to OUTFILE.txt. A PDF or any other download (a manual, a
zip, JSON served as a file) is saved as-is to OUTFILE. At most SLOTS fetches run at a time
across every caller; a caller waits up to SLOT_WAIT seconds for a free slot.

Exit codes, shared with the robeast wrapper rfetch and the delegates' briefs:
  0 page read · 2 still behind a bot wall after WALL_WAIT seconds (files written anyway)
  3 browser not listening · 4 no free slot within SLOT_WAIT seconds · 6 navigation failed
"""

import enum
import os
import re
import sys
import time

from playwright.sync_api import Error as PlaywrightError
from playwright.sync_api import sync_playwright

CDP = "http://127.0.0.1:9222"
SLOT_DIR = "/tmp/fetch-slots"
SLOTS = 3
SLOT_WAIT = 100
SLOT_STALE = 300
WALL_WAIT = 90
LOG = "/out/.fetch.log"

WALL = re.compile(
    r"just a moment|attention required|access denied|verify you are human|checking your browser"
    r"|enable javascript and cookies|captcha|bot detection|unusual traffic|cf-chl|challenge-platform"
    r"|are you a robot|pardon our interruption|request blocked|making sure you.re not a bot|anubis"
    r"|proof.of.work|verifying your browser|checking if the site connection is secure|ddos-guard"
    r"|please wait while we verify|one more step|human verification|press and hold|press & hold"
    r"|security verification|security check|robot check|verify to continue|checking your connection"
    r"|please verify yourself|verify yourself|slide to verify|prove your humanity|blocked by network security",
    re.I,
)
TURNSTILE = 'iframe[src*="challenges.cloudflare.com"]'
CONSENT_BUTTONS = (
    "button#onetrust-accept-btn-handler",
    "button[data-testid='uc-accept-all-button']",
    "button#didomi-notice-agree-button",
    "button[aria-label='Accept all']",
    "button:has-text('Accept all')",
    "button:has-text('Accept All')",
    "button:has-text('Alle akzeptieren')",
    "button:has-text('Приемам')",
    "button:has-text('I agree')",
    "button:has-text('Agree')",
)
BINARY_TYPES = ("application/pdf", "application/octet-stream", "application/zip", "application/x-", "image/")


class Outcome(enum.IntEnum):
    READ = 0
    WALLED = 2
    NO_BROWSER = 3
    NO_SLOT = 4
    NAV_FAILED = 6


class Slot:
    """One of SLOTS directories under SLOT_DIR; holding one means running."""

    def __init__(self):
        self.path = None

    def __enter__(self):
        os.makedirs(SLOT_DIR, exist_ok=True)
        deadline = time.time() + SLOT_WAIT
        while True:
            for i in range(1, SLOTS + 1):
                cand = os.path.join(SLOT_DIR, str(i))
                try:
                    if time.time() - os.stat(cand).st_mtime > SLOT_STALE:
                        os.rmdir(cand)
                except FileNotFoundError:
                    pass
                except OSError:
                    pass
                try:
                    os.mkdir(cand)
                    self.path = cand
                    return self
                except FileExistsError:
                    continue
            if time.time() > deadline:
                raise TimeoutError(f"all {SLOTS} fetch slots busy for {SLOT_WAIT} s; retry in a minute")
            time.sleep(2)

    def __exit__(self, *exc):
        if self.path:
            try:
                os.rmdir(self.path)
            except OSError:
                pass


def log(line):
    try:
        with open(LOG, "a") as lf:
            lf.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')} {line}\n")
    except OSError:
        pass


def click_turnstile(page):
    """Cloudflare's managed challenge shows a checkbox in an iframe; one click on it is what a person does."""
    try:
        frame = page.locator(TURNSTILE).first
        if frame.count() == 0:
            return False
        box = frame.bounding_box()
        if not box:
            return False
        page.mouse.click(box["x"] + 30, box["y"] + box["height"] / 2)
        return True
    except PlaywrightError:
        return False


def dismiss_consent(page):
    """Click the first cookie-consent button found, so the visible text is the page and not the banner."""
    for sel in CONSENT_BUTTONS:
        try:
            btn = page.locator(sel).first
            if btn.count() and btn.is_visible():
                btn.click(timeout=3000)
                time.sleep(1)
                return sel
        except PlaywrightError:
            continue
    return None


def wait_wall(page):
    """Return 'ok' once the page is no longer a challenge page, else a 'STILL WALLED' note."""
    deadline = time.time() + WALL_WAIT
    clicked = False
    while True:
        title = page.title() or ""
        body = ""
        try:
            body = page.inner_text("body")[:3000]
        except PlaywrightError:
            pass
        walled = bool(WALL.search(title)) or (len(body) < 1500 and bool(WALL.search(body)))
        if not walled:
            return "ok"
        if time.time() > deadline:
            return f"STILL WALLED after {WALL_WAIT} s"
        if not clicked and time.time() > deadline - WALL_WAIT + 8:
            clicked = click_turnstile(page)
        time.sleep(3)


def save_download(ctx, url, out, reason):
    r = ctx.request.get(url, timeout=120000)
    body = r.body()
    with open(out, "wb") as f:
        f.write(body)
    print(f"fetch: saved {len(body)} bytes ({r.headers.get('content-type', '?')}; {reason}) -> {out}")


def fetch(url, out):
    with sync_playwright() as p:
        try:
            browser = p.chromium.connect_over_cdp(CDP)
        except PlaywrightError as e:
            print(f"fetch: the research browser is not listening on {CDP} ({str(e).splitlines()[0][:100]})", file=sys.stderr)
            return Outcome.NO_BROWSER
        ctx = browser.contexts[0] if browser.contexts else browser.new_context()
        page = ctx.new_page()
        log(f"{url.split('/')[2] if '//' in url else url} -> {os.path.basename(out)}")
        try:
            try:
                resp = page.goto(url, wait_until="domcontentloaded", timeout=60000)
            except PlaywrightError as e:
                msg = str(e)
                if "Download is starting" in msg or "ERR_ABORTED" in msg:
                    save_download(ctx, url, out, "download")
                    return Outcome.READ
                print(f"fetch: navigation failed: {msg.splitlines()[0][:160]}", file=sys.stderr)
                return Outcome.NAV_FAILED
            ctype = resp.headers.get("content-type", "") if resp else ""
            is_html = ctype.startswith("text/html") or ctype == ""
            want_binary = any(ctype.startswith(b) for b in BINARY_TYPES) or url.lower().split("?")[0].endswith(".pdf")
            if want_binary:
                if is_html or (resp and resp.status in (403, 429, 503)):
                    wait_wall(page)
                save_download(ctx, url, out, ctype or "pdf by name")
                return Outcome.READ
            status = wait_wall(page)
            try:
                page.wait_for_load_state("networkidle", timeout=15000)
            except PlaywrightError:
                pass
            consent = dismiss_consent(page)
            time.sleep(1.5)
            html = page.content()
            text = ""
            try:
                text = page.inner_text("body")
            except PlaywrightError:
                pass
            with open(out, "w") as f:
                f.write(html)
            with open(out + ".txt", "w") as f:
                f.write(text)
            code = resp.status if resp else "?"
            print(
                f"fetch: {status}; HTTP {code}; title={page.title()!r}; "
                f"{'consent dismissed; ' if consent else ''}"
                f"html {len(html)} chars -> {out}; text {len(text)} chars -> {out}.txt"
            )
            return Outcome.READ if status == "ok" else Outcome.WALLED
        finally:
            page.close()


def main():
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 64
    url, out = sys.argv[1], sys.argv[2]
    try:
        with Slot():
            return int(fetch(url, out))
    except TimeoutError as e:
        print(f"fetch: {e}", file=sys.stderr)
        return int(Outcome.NO_SLOT)


if __name__ == "__main__":
    sys.exit(main())
