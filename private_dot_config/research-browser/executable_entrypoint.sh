#!/bin/sh
# Starts the virtual display, a VNC view of it on the container's port 5900 (reached only through ssh to the
# server: the owner signs in to sites by hand there, the profile keeps the session), and a headful Chromium
# whose remote-debugging port stays on the container's loopback; fetch.py connects to it from inside.
set -eu
mkdir -p /profile /out
# the previous container's Chromium left its profile lock behind; only this container ever uses the profile
rm -f /profile/SingletonLock /profile/SingletonSocket /profile/SingletonCookie
Xvfb :99 -screen 0 1920x1080x24 -nolisten tcp &
export DISPLAY=:99
for _ in $(seq 1 50); do [ -S /tmp/.X11-unix/X99 ] && break; sleep 0.1; done
# the Screen Sharing app insists on a VNC password: a fresh one per container start, kept in the output dir
# for the workstation helper (classic VNC auth uses the first 8 characters)
vncpw=$(head -c 64 /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
umask 077
printf '%s\n' "$vncpw" > /out/.vnc-password
x11vnc -storepasswd "$vncpw" /tmp/vncpass >/dev/null 2>&1
umask 022
x11vnc -display :99 -forever -shared -rfbauth /tmp/vncpass -quiet -rfbport 5900 >/dev/null 2>&1 &
exec chromium \
	--user-data-dir=/profile \
	--remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 \
	--no-first-run --no-default-browser-check --password-store=basic \
	--disable-features=TranslateUI --disable-session-crashed-bubble --hide-crash-restore-bubble \
	--window-size=1920,1080 --window-position=0,0 --lang=en-US --disk-cache-size=268435456 \
	about:blank
