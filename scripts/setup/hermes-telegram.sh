#!/usr/bin/env bash
# Connect Hermes to a Telegram bot that answers only Sid, as HumanLoop's phone channel.
#
#   1. Telegram: @BotFather -> /newbot -> copy the token it gives you (Cmd+C)
#   2. Telegram: @userinfobot -> it replies with your numeric user id
#   3. ./scripts/setup/hermes-telegram.sh <your user id>
#
# The token is read from the clipboard, so it never shows on screen or in shell history,
# and the clipboard is cleared afterwards. It is stored in Hermes's own .env in its data
# volume (mode 600), not in this repo. Only the given user id may talk to the bot
# (TELEGRAM_ALLOWED_USERS); Hermes refuses everyone else.
set -euo pipefail

USER_ID="${1:-}"
if ! [[ "${USER_ID}" =~ ^[0-9]+$ ]]; then
  echo "usage: hermes-telegram.sh <your numeric Telegram user id (from @userinfobot)>" >&2
  exit 2
fi
TOKEN="$(pbpaste | tr -d '[:space:]')"
if ! [[ "${TOKEN}" =~ ^[0-9]+:[A-Za-z0-9_-]{30,}$ ]]; then
  echo "The clipboard does not hold a bot token; copy it from @BotFather and run this again." >&2
  exit 1
fi

# check the token with Telegram; the URL goes through stdin so the token stays out of `ps`
bot="$(printf 'url = "https://api.telegram.org/bot%s/getMe"\n' "${TOKEN}" | curl -fsS -K - |
  python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["username"])')" || {
  echo "Telegram did not accept the token; copy it again from @BotFather." >&2; exit 1; }
echo "Bot: @${bot}"

printf 'TELEGRAM_BOT_TOKEN=%s\nTELEGRAM_ALLOWED_USERS=%s\n' "${TOKEN}" "${USER_ID}" |
  docker exec -i -u hermes hermes sh -c 'set -e; umask 077; f=/opt/data/.env
    grep -vE "^(TELEGRAM_BOT_TOKEN|TELEGRAM_ALLOWED_USERS)=" "$f" >"$f.new" || true
    cat >>"$f.new"; mv "$f.new" "$f"; chmod 600 "$f"'
pbcopy </dev/null
unset TOKEN
echo "Token saved in Hermes's .env; clipboard cleared. Allowed user: ${USER_ID}"

H() { docker exec hermes hermes config set "$@" >/dev/null; }
# messages sent while the Mac was off are delivered when Hermes starts (Telegram keeps ~24 h)
H platforms.telegram.extra.drop_pending_on_cold_boot false
# a Telegram DM's chat id is the user's id: this chat is HumanLoop
H "platforms.telegram.channel_prompts.${USER_ID}" "This chat is HumanLoop on Sid's iPhone. \
Load the humanloop skill (and google-accounts for calendars or mail) before answering anything \
about Sid's goals, projects, plans, schedule, tasks or check-ins. Phone replies: a few short \
lines, the next action first. Quick captures (remember, todo, idea, a forwarded message) go to \
inbox.md as described in the skill; confirm in one line. Questions about lectures, modules or \
anything Sid is studying (\"I don't get...\", \"explain...\", \"card 3\", \"brief\"): load the \
study-coach skill and follow it."
# send lecture cards (study-coach) from the mounted ~/brain/study
H gateway.media_delivery_allow_dirs '["/opt/data/study"]'

docker restart hermes >/dev/null
echo "Hermes restarted. Open Telegram, message @${bot} and say hi."
