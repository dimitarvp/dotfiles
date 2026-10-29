---
name: runs
description: List or fetch finished runs of the fleet's task queue (pueue) on any machine, with their verdicts and log tails. Use when asked whether a queued suite, build or check passed, what a past task printed, or which runs failed.
---

# Fleet runs

Every workstation runs long jobs through pueue. When a task finishes, pueue's callback
(`pueue_ledger_record`) writes one record for it, keeps it on that machine in
`~/.local/state/pueue_ledger/records.jsonl` and publishes it to the hub. The hub keeps
every record of every machine, so you can read any machine's runs from anywhere.

## A record

One JSON object per finished task:
`{v, machine, id, group, label, command, path, created_at, start, end, duration_s, result, exit_code, tail, recorded_at}`.
`machine` is the short host name; `id` is pueue's task number on that machine; `path` is the
working directory; `result` is `Success`, `Failed`, `Killed` or another pueue verdict;
`exit_code` is 0 for Success, the code for Failed, null otherwise; `tail` is the last 50
lines of output. Times are the machine's own, with an offset; `recorded_at` is UTC.

## Commands

```
fleet <me> runs [--machine M] [--group G] [--label TEXT] [--since DURATION] [--failed] [--json] [N]
fleet <me> run <machine> <id> [--json]
```

`runs` prints the newest N runs (default 20) of the last 30 days, or of `--since`
(`2h`, `7d`, `90d`), one line each: end time, machine, id, group, result and exit code,
duration, label. `--label` matches a part of the label, in any case. `--failed` keeps
everything that is not Success. `run` prints one record, field by field, then its tail.
`--json` prints the records as JSON lines instead.

```
fleet <me> runs --failed --since 7d
fleet <me> runs --machine <machine> --label "#1003" --json
fleet <me> run <machine> 42
```

## The full log

The tail is all the hub keeps. Its last lines name the runner's own log file on that
machine. While the task still exists there, `pueue log <id>` on that machine prints its
whole output. A shell whose `PUEUE_WORKER_ID` is set runs inside a pueue task.

## Retention

The ledger is kept for good: on the hub and in each machine's `records.jsonl`. Raw logs
stay on the machine until the task's owner removes the task (`pueue remove`); after that,
only the record and its tail remain.

## Labels

A label is free text given at `pueue add --label`. It is the filter key, so put in it what
you will search for later: the pull request and the purpose, as in `suite #1003 round 1`.
