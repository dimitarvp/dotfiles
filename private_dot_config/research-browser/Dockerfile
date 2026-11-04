# The research browser image: Debian's Chromium, a virtual display, and the Playwright client that
# fetch.py uses to drive it over CDP from inside the container. Built on the server by
# `research_browser up`; the browser runs as the unprivileged user that owns the mounted dirs.
FROM debian:stable-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		chromium xvfb xauth ca-certificates curl python3 python3-venv \
		fonts-liberation fonts-dejavu-core fonts-noto-core \
	&& rm -rf /var/lib/apt/lists/*
RUN groupadd -g 1001 browser && useradd -m -u 1000 -g 1001 browser
RUN python3 -m venv /app/venv && /app/venv/bin/pip install --no-cache-dir playwright==1.63.0
COPY fetch.py entrypoint.sh /app/
RUN chmod 0755 /app/entrypoint.sh
USER browser
ENTRYPOINT ["/app/entrypoint.sh"]
