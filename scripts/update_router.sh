#!/bin/sh

BASE="https://raw.githubusercontent.com/alpard/router-rules/main/rules"
TARGET="/tmp/router-rules"

RULES="
openai
claude
google-ai
notion
meta
youtube
zoom
cloudflare
mhc
utility
telegram
apple
microsoft
direct
"

mkdir -p "$TARGET"

echo "Updating router rules..."

for rule in $RULES; do
  echo "Downloading $rule.txt"
  wget -q -O "$TARGET/$rule.txt.tmp" "$BASE/$rule.txt"

  if [ $? -ne 0 ] || [ ! -s "$TARGET/$rule.txt.tmp" ]; then
    echo "ERROR: failed to download $rule.txt"
    rm -f "$TARGET/$rule.txt.tmp"
    exit 1
  fi

  mv "$TARGET/$rule.txt.tmp" "$TARGET/$rule.txt"
done

echo "Router rules updated successfully."
