#!/bin/sh

set -e

BASE="https://raw.githubusercontent.com/alpard/router-rules/main/rules"
TMP="/tmp/router-rules-sync"
STATE="/root/router-rules-state"
LOG="/tmp/router-rules.log"

RULES="openai claude google-ai notion meta youtube zoom cloudflare mhc utility telegram apple microsoft direct"

mkdir -p "$TMP" "$STATE"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"
}

download() {
  name="$1"
  url="$BASE/$name.txt?cache=$(date +%s)"

  wget -q -O "$TMP/$name.txt" "$url"

  if [ ! -f "$TMP/$name.txt" ]; then
    log "ERROR: failed to download $name.txt"
    exit 1
  fi

  if [ ! -s "$TMP/$name.txt" ]; then
    log "WARN: $name.txt is empty"
  fi
}

merge() {
  output="$1"
  shift

  : > "$TMP/$output.txt"

  for name in "$@"; do
    [ -f "$TMP/$name.txt" ] && cat "$TMP/$name.txt" >> "$TMP/$output.txt"
    echo >> "$TMP/$output.txt"
  done

  sed -i '/^[[:space:]]*$/d' "$TMP/$output.txt"
  sort -u "$TMP/$output.txt" -o "$TMP/$output.txt"
}

changed() {
  name="$1"

  if [ ! -f "$STATE/$name.txt" ]; then
    return 0
  fi

  ! cmp -s "$TMP/$name.txt" "$STATE/$name.txt"
}

log "Starting router rules sync"

for f in $RULES; do
  download "$f"
done

merge main meta youtube zoom cloudflare mhc utility
merge OpenAI openai claude google-ai notion

NEED_RESTART=0

if changed main; then
  log "main rules changed"
  NEED_RESTART=1
fi

if changed OpenAI; then
  log "OpenAI rules changed"
  NEED_RESTART=1
fi

if [ "$NEED_RESTART" = "0" ]; then
  log "No changes. Podkop restart skipped."
  exit 0
fi

uci set podkop.main.user_domain_list_type='text'
uci set podkop.main.user_domains_text="$(cat "$TMP/main.txt")"

uci set podkop.OpenAI.user_domain_list_type='text'
uci set podkop.OpenAI.user_domains_text="$(cat "$TMP/OpenAI.txt")"

uci commit podkop

cp "$TMP/main.txt" "$STATE/main.txt"
cp "$TMP/OpenAI.txt" "$STATE/OpenAI.txt"

log "Restarting Podkop"
/etc/init.d/podkop restart

log "Done"
