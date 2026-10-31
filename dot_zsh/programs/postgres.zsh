# PostgreSQL 18 from MacPorts on the Mac: never auto-started, run by hand as the
# postgres user. pg18 start|stop|restart|status|log [lines]
if is_macos && [[ -x /opt/local/lib/postgresql18/bin/pg_ctl ]]; then
	pg18() {
		local bin=/opt/local/lib/postgresql18/bin/pg_ctl
		local data=/opt/local/var/db/postgresql18/defaultdb
		local log=/opt/local/var/log/postgresql18/postgres.log
		case "$1" in
		start | stop | restart | status) sudo -u postgres "$bin" -D "$data" -l "$log" "$1" ;;
		log) sudo tail -n "${2:-50}" "$log" ;;
		*)
			print -u2 "usage: pg18 start|stop|restart|status|log [lines]"
			return 2
			;;
		esac
	}
fi
