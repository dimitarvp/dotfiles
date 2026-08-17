export MIX_OS_DEPS_COMPILE_PARTITION_COUNT=$((available_cpu_cores / 2))

# probex (~/bin/probex, chezmoi external): opt-in usage log; the tool census reads it
export PROBEX_LOGFILE="$HOME/.probex/usage.jsonl"
