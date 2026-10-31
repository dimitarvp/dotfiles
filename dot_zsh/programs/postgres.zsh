# PostgreSQL 18 from MacPorts on the Mac, started at boot by its launchd item.
# pg18 start|stop|status|log [lines]: start = load the item (runs now and at
# every boot), stop = unload it (stays off across boots until the next start).
if is_macos && [[ -x /opt/local/lib/postgresql18/bin/pg_ctl ]]; then
	pg18() {
		local data=/opt/local/var/db/postgresql18/defaultdb
		local log=/opt/local/var/log/postgresql18/postgres.log
		case "$1" in
		start) sudo /opt/local/bin/port load postgresql18-server ;;
		stop) sudo /opt/local/bin/port unload postgresql18-server ;;
		status) sudo -u postgres /opt/local/lib/postgresql18/bin/pg_ctl -D "$data" status ;;
		log) sudo tail -n "${2:-50}" "$log" ;;
		*)
			print -u2 "usage: pg18 start|stop|status|log [lines]"
			return 2
			;;
		esac
	}
fi
