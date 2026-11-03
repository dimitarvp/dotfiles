# zellij: attach to a session or create it (screen -DR style), remote and local.
# zr HOST [NAME]        attach-or-create NAME (default main) on HOST over ssh
# zl [NAME]             the same on this machine
# zs [HOST]             list sessions here or on HOST
# zd [HOST] NAME|--all  delete an exited session, or every exited one
zr() {
	ssh -t "${1:?host}" "zellij attach --create ${2:-main}"
}

zl() {
	zellij attach --create "${1:-main}"
}

zs() {
	if [[ -n $1 ]]; then
		ssh "$1" "zellij list-sessions"
	else
		zellij list-sessions
	fi
}

zd() {
	local run=(zellij)
	if (($# == 2)); then
		run=(ssh "$1" zellij)
		shift
	fi
	if [[ $1 == --all ]]; then
		"${run[@]}" delete-all-sessions
	else
		"${run[@]}" delete-session "${1:?session name or --all}"
	fi
}
