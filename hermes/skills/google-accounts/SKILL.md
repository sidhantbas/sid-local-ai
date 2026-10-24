---
name: google-accounts
description: "Sid's three Google accounts (Gmail, Calendar, Drive, Docs, Sheets): pick one or use all."
version: 1.0.0
author: sidhantbas
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [Google, Gmail, Calendar, Drive, Email, accounts]
    related_skills: [google-workspace]
---

# Google accounts

Sid has three Google accounts, each signed in separately:

- `sidhantbastola7` (sidhantbastola7@gmail.com, the main one)
- `sibastola6ucl`
- `disisidstudio`

Run every Google command through `gacct` with the terminal tool. It runs the
google-workspace skill's `google_api.py` as the chosen account:

```sh
G=/opt/data/skills/productivity/google-accounts/scripts/gacct
$G list                                        # which accounts are signed in
$G all gmail search "is:unread" --max 20       # every account, output under "=== <account>"
$G sibastola6ucl gmail search "is:unread newer_than:2d" --max 10
$G sidhantbastola7 gmail get <message_id>
$G all calendar list --start 2026-10-24T00:00:00Z --end 2026-10-25T00:00:00Z
$G disisidstudio drive search "budget" --max 10
```

Services and commands (same as google-workspace):

- `gmail search QUERY [--max N]`, `gmail get ID`, `gmail labels`,
  `gmail send --to --subject --body [--cc]`, `gmail reply ID --body`,
  `gmail modify ID [--add-labels] [--remove-labels]`
- `calendar list [--start] [--end] [--max] [--calendar]`,
  `calendar create --summary --start --end [--location] [--description]`, `calendar delete`
- `drive search QUERY [--max N]`, `docs get DOC_ID`, `sheets ...`, `contacts ...`
  (`$G <account> <service> --help` shows the rest)

Gmail search operators: `is:unread`, `from:`, `newer_than:2d`, `subject:`, `has:attachment`.

## Rules

- No account named: read from `all` and label every item with its account.
- Writing (send, reply, modify labels, create or delete events): only for the account Sid
  names, and confirm the account and content with Sid before running it.
- Keep summaries short: one line per email (account, sender, subject, what it needs).
- If an account is not signed in, say so; do not try to sign it in yourself.
