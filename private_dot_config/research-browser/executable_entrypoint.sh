#!/bin/sh
# Starts the virtual display and a headful Chromium whose remote-debugging port stays on the
# container's loopback; fetch.py connects to it from inside the same container.
set -eu
mkdir -p /profile /out
# the previous container's Chromium left its profile lock behind; only this container ever uses the profile
rm -f /profile/SingletonLock /profile/SingletonSocket /profile/SingletonCookie
exec xvfb-run -a -s "-screen 0 1920x1080x24 -nolisten tcp" chromium \
	--user-data-dir=/profile \
	--remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 \
	--no-first-run --no-default-browser-check --password-store=basic \
	--disable-features=TranslateUI --disable-session-crashed-bubble --hide-crash-restore-bubble \
	--window-size=1920,1080 --lang=en-US \
	about:blank
