"""test_turns.py: run fetch.py's turn-taking rules with `python3 test_turns.py`.

A read takes its site's lock first and then one of SLOTS pool slots. So two reads of one site run
one after another, reads of different sites run side by side, and at most SLOTS reads run at a
time. Needs no browser and no Playwright: the two Playwright names fetch.py imports are stubbed
here. The lock folders live in a temporary folder and the waits are shortened.
"""

import os
import re
import sys
import tempfile
import threading
import types

stub = types.ModuleType("playwright.sync_api")
stub.Error = Exception
stub.sync_playwright = None
sys.modules["playwright"] = types.ModuleType("playwright")
sys.modules["playwright.sync_api"] = stub

import fetch  # noqa: E402

results = []


def check(name, ok, detail=""):
    results.append(bool(ok))
    print(f"{'ok  ' if ok else 'FAIL'} {name}{' (' + detail + ')' if detail and not ok else ''}")


def fresh(slots=2):
    """A new empty lock folder and short waits; returns the folder."""
    d = tempfile.mkdtemp(prefix="turns-")
    fetch.SLOT_DIR = d
    fetch.SLOTS = slots
    fetch.SLOT_WAIT = 1.0
    fetch.SLOT_STALE = 300
    fetch.SLOT_POLL = 0.02
    return d


class Reader(threading.Thread):
    """Takes a turn for url and holds it until done() is called; records how it went."""

    def __init__(self, url):
        super().__init__(daemon=True)
        self.url = url
        self.entered = threading.Event()
        self.release = threading.Event()
        self.error = None

    def run(self):
        try:
            with fetch.Turn(self.url):
                self.entered.set()
                self.release.wait(10)
        except Exception as e:  # noqa: BLE001
            self.error = e

    def done(self):
        self.release.set()
        self.join(5)


def started(url):
    r = Reader(url)
    r.start()
    return r


# the pool size that ships
check("the pool has 8 slots", fetch.SLOTS == 8, f"SLOTS is {fetch.SLOTS}")

# which addresses count as one site: url, expected site name
SITES = [
    ("https://www.emag.bg/laptopi/c", "emag.bg"),
    ("https://m.emag.bg/", "emag.bg"),
    ("https://EHUB.bg", "ehub.bg"),
    ("https://html.duckduckgo.com/html/?q=a+b", "duckduckgo.com"),
    ("https://www.bing.com/search?q=a", "bing.com"),
    ("https://git.kernel.org/pub/scm/x?h=v1", "kernel.org"),
    ("https://dl.dell.com/a.pdf", "dell.com"),
    ("https://www.amazon.co.uk/dp/1", "amazon.co.uk"),
    ("https://www.amazon.de/dp/1", "amazon.de"),
    ("https://shop.example.com.au/x", "example.com.au"),
    ("https://www.pcx.bg:8443/gtc", "pcx.bg"),
    ("https://user:pw@www.Example.ORG/p", "example.org"),
    ("http://192.0.2.7/status", "192.0.2.7"),
    ("http://localhost:8000/", "localhost"),
    ("https://xn--e1aybc.bg/", "xn--e1aybc.bg"),
    ("https://t.co/abc", "t.co"),
]
for url, want in SITES:
    got = fetch.site_key(url)
    check(f"site of {url} is {want}", got == want, f"got {got!r}")

# whatever the address, the site name must be usable as part of a folder name
for url in ("http://[::1]:8080/", "file:///etc/hosts", "not a url", "", "https://../x", "https://a_b.example.com/"):
    got = fetch.site_key(url)
    check(f"site name of {url!r} is safe in a folder name", bool(re.fullmatch(r"[a-z0-9._-]+", got or "")), f"got {got!r}")

# two reads of one site run one after another
d = fresh()
r1 = started("https://www.emag.bg/a")
check("the first read of a site gets its turn at once", r1.entered.wait(0.5))
r2 = started("https://m.emag.bg/b")
check("a second read of the same site waits while the first runs", not r2.entered.wait(0.3))
r1.done()
check("the second read gets its turn when the first is done", r2.entered.wait(0.5))
r2.done()
check("nothing is held after both reads", os.listdir(d) == [], f"left: {os.listdir(d)}")

# reads of different sites run side by side
d = fresh()
r1 = started("https://ehub.bg/")
r2 = started("https://www.pcx.bg/")
check("reads of two sites run side by side", r1.entered.wait(0.5) and r2.entered.wait(0.5))
r1.done()
r2.done()
check("nothing is held after them", os.listdir(d) == [], f"left: {os.listdir(d)}")

# the pool is the limit for different sites
d = fresh(slots=2)
r1 = started("https://a.example.bg/")
r2 = started("https://b.example.org/")
r1.entered.wait(0.5)
r2.entered.wait(0.5)
r3 = started("https://c.example.net/")
check("a read beyond the pool waits", not r3.entered.wait(0.3))
r3.join(2.5)
check("it gives up after SLOT_WAIT with a TimeoutError", isinstance(r3.error, TimeoutError), f"error: {r3.error!r}")
check("its message speaks of slots", "slot" in str(r3.error or "").lower(), f"message: {r3.error}")
r1.done()
r2.done()

# a read that waits for its site holds no pool slot meanwhile
d = fresh(slots=2)
r1 = started("https://www.emag.bg/a")
r1.entered.wait(0.5)
r2 = started("https://www.emag.bg/b")
r2.entered.wait(0.1)
r3 = started("https://ehub.bg/")
check("a read of another site gets the free slot while one waits for its site", r3.entered.wait(0.5))
r1.done()
check("the waiting read follows once its site is free", r2.entered.wait(0.5))
r2.done()
r3.done()
check("nothing is held after the three", os.listdir(d) == [], f"left: {os.listdir(d)}")

# the wait for a busy site also ends after SLOT_WAIT, and says which site
d = fresh()
r1 = started("https://www.emag.bg/a")
r1.entered.wait(0.5)
r2 = started("https://www.emag.bg/b")
r2.join(2.5)
check("a read gives up on a busy site after SLOT_WAIT", isinstance(r2.error, TimeoutError), f"error: {r2.error!r}")
check("its message names the site", "emag.bg" in str(r2.error or ""), f"message: {r2.error}")
r1.done()

# locks left by a reader that died are taken over once they are stale
d = fresh(slots=1)
fetch.SLOT_STALE = 5
r1 = started("https://www.emag.bg/a")
r1.entered.wait(0.5)
old = os.stat(d).st_mtime - 60
for name in os.listdir(d):
    os.utime(os.path.join(d, name), (old, old))
r2 = started("https://www.emag.bg/b")
check("a stale site lock and a stale slot are taken over", r2.entered.wait(0.5), f"error: {r2.error!r}")
r2.done()
r1.done()

# a read that fails still gives its turn back
d = fresh()
try:
    with fetch.Turn("https://ehub.bg/"):
        raise RuntimeError("the read failed")
except RuntimeError:
    pass
check("a failed read leaves nothing held", os.listdir(d) == [], f"left: {os.listdir(d)}")

failed = results.count(False)
print(f"{len(results) - failed} of {len(results)} checks pass")
sys.exit(1 if failed else 0)
