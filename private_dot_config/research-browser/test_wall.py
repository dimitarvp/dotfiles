"""test_wall.py: run fetch.py's human-check rule on page texts with `python3 test_wall.py`.

Needs no browser and no Playwright: the two Playwright names fetch.py imports are stubbed here.
"""

import sys
import types

stub = types.ModuleType("playwright.sync_api")
stub.Error = Exception
stub.sync_playwright = None
sys.modules["playwright"] = types.ModuleType("playwright")
sys.modules["playwright.sync_api"] = stub

import fetch  # noqa: E402

NOTICE = "This site is protected by reCAPTCHA and the Google Privacy Policy and Terms of Service apply."
DUCK = (
    "Unfortunately, bots use DuckDuckGo too.\n"
    "Please complete the following challenge to confirm this search was made by a human.\n"
    "Select all squares containing a duck:"
)

# name, page title, visible text, whether the page is a human check
CASES = [
    ("an empty shop search that carries the reCAPTCHA notice", "Търсене SN8100", "Резултати за “SN8100”\nНамерени: 0\n" + NOTICE, False),
    ("a short product page that carries the notice", "Product Change Notification (PCN)", "KSM56R46BD4-64MD\n" + NOTICE, False),
    ("a long page that mentions a captcha in passing", "A forum thread", "x" * 2000 + " the captcha was annoying", False),
    ("a shop's captcha page, named in its title", "eMAG Captcha", "", True),
    ("a waiting page before the site", "Just a moment...", "Verifying you are human. This may take a few seconds.", True),
    ("a site's own check", "", "Verify you are human", True),
    ("a first-visit block", "", "You've been blocked by network security. Prove your humanity", True),
    ("a short page that asks for a captcha", "", "Please complete the CAPTCHA below to continue.", True),
    ("a captcha page that also carries the notice", "", "Solve the captcha to continue.\n" + NOTICE, True),
    ("a search engine's own check", "DuckDuckGo", DUCK, True),
]

failed = 0
for name, title, body, want in CASES:
    got = fetch.is_wall(title, body)
    failed += got != want
    print(f"{'ok  ' if got == want else 'FAIL'} {name}: human check = {got}, expected {want}")
print(f"{len(CASES) - failed} of {len(CASES)} cases pass")
sys.exit(1 if failed else 0)
