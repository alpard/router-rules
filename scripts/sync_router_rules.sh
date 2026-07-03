#!/bin/sh

set -e

BASE="https://raw.githubusercontent.com/alpard/router-rules/main/rules"
TMP="/tmp/router-rules-sync"

mkdir -p "$TMP"

download() {
  name="$1"
  wget -q -O "$TMP/$name.txt" "$BASE/$name.txt"

  if [ ! -s "$TMP/$name.txt" ]; then
    echo "ERROR: failed to download $name.txt"
    exit 1
  fi
}

merge() {
  output="$1"
  shift

  : > "$TMP/$output.txt"

  for name in "$@"; do
    cat "$TMP/$name.txt" >> "$TMP/$output.txt"
    echo >> "$TMP/$output.txt"
  done

  sed -i '/^[[:space:]]*$/d' "$TMP/$output.txt"
  sort -u "$TMP/$output.txt" -o "$TMP/$output.txt"
}

echo "Downloading router rules..."

for f in openai claude google-ai notion meta youtube zoom cloudflare mhc utility telegram apple microsoft direct; do
  download "$f"
done

echo "Building Podkop lists..."

merge main meta youtube zoom cloudflare mhc utility
merge OpenAI openai claude google-ai notion

echo "Updating UCI..."

uci set podkop.main.user_domain_list_type='text'
uci set podkop.main.user_domains_text="$(cat "$TMP/main.txt")"

uci set podkop.OpenAI.user_domain_list_type='text'
uci set podkop.OpenAI.user_domains_text="$(cat "$TMP/OpenAI.txt")"

uci commit podkop

echo "Restarting Podkop..."
/etc/init.d/podkop restart

echo "Done."
