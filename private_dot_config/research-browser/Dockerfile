# The research browser image: Debian's Chromium, a virtual display, and the Playwright client that
# fetch.py uses to drive it over CDP from inside the container. Built on the server by
# `research_browser up`; the browser runs as the unprivileged user that owns the mounted dirs.
FROM debian:stable-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		chromium xvfb x11vnc novnc websockify ca-certificates curl python3 python3-venv \
		fonts-liberation fonts-dejavu-core fonts-noto-core \
	&& rm -rf /var/lib/apt/lists/*
# Two extensions, force-installed from the Chrome Web Store by a managed policy (his go 2026-11-04): uBlock
# Origin Lite (ddkj...) keeps ads and trackers out of the pages the researchers read, "I still don't care about
# cookies" (edib...) answers the consent banners. The store keeps them current; an unpacked --load-extension
# made Chromium 156 hang before opening its debugging port.
COPY policies.json /etc/chromium/policies/managed/research.json
RUN groupadd -g 1001 browser && useradd -m -u 1000 -g 1001 browser
RUN python3 -m venv /app/venv && /app/venv/bin/pip install --no-cache-dir playwright==1.63.0
COPY fetch.py paste.py shot.py entrypoint.sh /app/
RUN chmod 0755 /app/entrypoint.sh
USER browser
ENTRYPOINT ["/app/entrypoint.sh"]
