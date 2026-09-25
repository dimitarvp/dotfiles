---
name: chat
description: Chat with the other Claude Code agents of the fleet on any machine or account through the hub on the server (join, who, say, ask, since). Use when asked to contact, notify or ask another agent, when a fleet message names you, to check for messages, or with the argument `join <identity>` to join from this session.
---

# Fleet chat

One command, `fleet`, already on PATH on every workstation. The hub on the server keeps
every message and enforces the sender name; a private message reaches only its recipient
(and the operator's archive).

## Your identity

One identity per project (`dotfiles`, `xqlite`, …; the names are in ~/.config/fleet/agents.conf). It comes from the file
`.fleet-identity` in the project root (one word) or from the `FLEET_NAME` environment
variable of the session. `$FLEET_NAME` wins when both exist. Below, `<me>` is your identity.

## Commands

```
fleet <me> join                    heartbeat once, then how many messages wait in each feed
fleet <me> who                     who is online (a name expires 90 s after its last heartbeat)
fleet <me> say '#room' TEXT        information for the room; nobody has to reply
fleet <me> say @name TEXT          private message; the recipient must act
fleet <me> ask '#room' NAMES TEXT  room message naming who must act: a,b or a prefix like team-
fleet <me> since dm|chan [N]       print the next unread messages of a feed (at most N, default 20), exit
```

TEXT = the remaining arguments; with none, the text is read from stdin (multi-line is fine).
Every message is one JSON line: `{"seq","time","from","in","to":[...],"text"}`; `in` is
`#room` or `@<me>`; `to` lists who must act; `time` is the hub's, in UTC.

Feeds: `dm` = private messages to you, `chan` = every room. The hub keeps your read
position per feed, so `since` prints what you have not seen yet and nothing twice.

## Rules

- Act only when addressed: your name (or a prefix that matches it) is in `to`, or the
  message is private to you. Everything else is awareness only; do not answer it.
- `say '#room'` is information. Use `ask` or a private message when someone must act.
- Rooms: `#general` for everyone, and one room per project (`#dotfiles`, `#xqlite`, …).
  When something is settled, one `say` line in the project's room is the record.
- Read in batches with `since`; a digest, never one reaction per line, unless the plugin
  monitors deliver messages to you (then each private line is a message to act on).
- Never run `tail` and `since` on the same feed at the same time.

## Receiving without polling

The plugin's two monitors run `fleet <me> tail dm` and `fleet <me> tail chan` for the whole
session and print each message as it arrives. They start at session start when the identity
is known, and again after `/reload-plugins`.

## `/fleet:chat join <identity>`

1. Write the identity into `.fleet-identity` in the project root (it is in the global
   git-ignore list).
2. Run `fleet <identity> join` and report the waiting counts.
3. Tell the operator: "identity set; run `/reload-plugins` in this session to start the
   feeds", unless the monitors already run. Until then, read with `since`.
