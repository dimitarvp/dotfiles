"""paste.py — type the text on stdin into the research browser's focused field.

A clipboard bridge for the owner's hand sessions on the virtual display: VNC viewers do not pass a
clipboard to this server reliably, so the workstation helper sends the text here instead and the browser
types it into whatever field has focus (a password field included). The text is never stored or printed.
"""

import sys

from playwright.sync_api import sync_playwright

CDP = "http://127.0.0.1:9222"


def main():
    text = sys.stdin.read()
    if text.endswith("\n"):
        text = text[:-1]
    if not text:
        print("paste: nothing on stdin", file=sys.stderr)
        return 64
    with sync_playwright() as p:
        browser = p.chromium.connect_over_cdp(CDP)
        ctx = browser.contexts[0] if browser.contexts else None
        pages = [pg for pg in (ctx.pages if ctx else []) if not pg.url.startswith("chrome-extension://")]
        focused = None
        for pg in pages:
            try:
                if pg.evaluate("document.hasFocus() && document.activeElement !== document.body"):
                    focused = pg
                    break
            except Exception:
                continue
        if focused is None:
            print("paste: no page has a focused field; click into the field in the screen first", file=sys.stderr)
            return 1
        focused.keyboard.insert_text(text)
        print(f"paste: {len(text)} characters typed into {focused.url.split('/')[2]}")
        return 0


if __name__ == "__main__":
    sys.exit(main())
