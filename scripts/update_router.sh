#!/bin/sh

BASE="https://raw.githubusercontent.com/alpard/router-rules/main"

RULES="
openai
claude
notion
meta
youtube
telegram
google-ai
apple
microsoft
zoom
utility
mhc
direct
"

mkdir -p /tmp/router-rules

echo "Updating router rules..."

for r in $RULES
do
    echo "Downloading $r..."
    wget -q -O /tmp/router-rules/$r.txt \
        "$BASE/rules/$r.txt"
done

echo "Done."
