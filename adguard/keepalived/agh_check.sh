#!/bin/sh
# Readiness probe: AGH's sanctioned healthcheck domain must yield a response
# (NODATA counts; dig exits nonzero only when no response arrives at all).
exec dig +time=1 +tries=1 @127.0.0.1 healthcheck.adguardhome.test A >/dev/null
