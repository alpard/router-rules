#!/bin/sh
# Additive, fail-closed Notion domain sync for RouteRich ZeroBlock.
# Usage: sh sync_zeroblock_notion.sh [--check|--apply]
set -eu

MODE="${1:---check}"
case "$MODE" in --check|--apply) ;; *) echo "Usage: $0 [--check|--apply]" >&2; exit 2 ;; esac

SECTION="zeroblock.theforceful.user_domains_text"
URL="https://raw.githubusercontent.com/alpard/router-rules/main/rules/notion.txt"
TMP="$(mktemp /tmp/zeroblock-notion.XXXXXX)"
BACKUP=""
cleanup() { rm -f "$TMP"; }
trap cleanup EXIT HUP INT TERM

command -v uci >/dev/null || { echo "ERROR: uci missing" >&2; exit 1; }
command -v sing-box >/dev/null || { echo "ERROR: sing-box missing" >&2; exit 1; }
[ -f /etc/config/zeroblock ] || { echo "ERROR: ZeroBlock config missing" >&2; exit 1; }
[ "$(uci -q get zeroblock.theforceful.enabled 2>/dev/null || echo 1)" != 0 ] || { echo "ERROR: theforceful disabled" >&2; exit 1; }
uci -q get zeroblock.theforceful >/dev/null 2>&1 || { echo "ERROR: theforceful section missing" >&2; exit 1; }
[ "$(uci -q get zeroblock.theforceful.user_domain_list_type 2>/dev/null || echo text)" = text ] || {
  echo "ERROR: unexpected theforceful user_domain_list_type" >&2; exit 1;
}

# Fetch without running downloaded code; require a nonempty, well-formed domain-only list.
wget -q -T 15 -O "$TMP" "$URL" || { echo "ERROR: download failed" >&2; exit 1; }
[ -s "$TMP" ] || { echo "ERROR: empty download" >&2; exit 1; }
COUNT="$(awk 'NF && $0 !~ /^#/ {n++} END {print n+0}' "$TMP")"
[ "$COUNT" -ge 15 ] && [ "$COUNT" -le 100 ] || { echo "ERROR: unexpected domain count $COUNT" >&2; exit 1; }
LC_ALL=C awk '
  /^[[:space:]]*#/ || /^[[:space:]]*$/ {next}
  /^[a-z0-9][a-z0-9.-]*[a-z0-9]$/ && index($0,".") > 0 && length($0) <= 253 {next}
  {bad=1; print "ERROR: invalid line: " $0 > "/dev/stderr"}
  END {exit bad}
' "$TMP" || exit 1
grep -qx 'notion-emojis.s3-us-west-2.amazonaws.com' "$TMP" || {
  echo "ERROR: required known-good hostname missing" >&2; exit 1;
}

# ZeroBlock maps this UCI list to sing-box domain_suffix rules.
# A parent suffix (notion.com) covers subdomains (api.notion.com).
# Unrelated asset hosts still require explicit entries.
CURRENT="$(uci -q get "$SECTION" 2>/dev/null || true)"
MISSING="$(awk 'NF && $0 !~ /^#/ {print}' "$TMP" | sort -u | while IFS= read -r domain; do
  covered=0
  for existing in $CURRENT; do
    case "$existing" in
      full:*) [ "${existing#full:}" = "$domain" ] && covered=1 ;;
      *)
        case "$domain" in
          "$existing"|*."$existing") covered=1 ;;
        esac
        ;;
    esac
    [ "$covered" -eq 1 ] && break
  done
  [ "$covered" -eq 1 ] || printf '%s\\n' "$domain"
done)"
if [ -z "$MISSING" ]; then echo "OK: Notion domains already present; no restart"; exit 0; fi
echo "Missing domains to ADD (existing entries remain untouched):"
printf '%s\n' "$MISSING"
if [ "$MODE" = --check ]; then
  echo "DRY RUN: no changes. Use --apply after reviewing the list."
  exit 0
fi

BACKUP="/root/zeroblock-before-notion-sync-$(date +%Y%m%d-%H%M%S).conf"
cp -p /etc/config/zeroblock "$BACKUP"
echo "Backup: $BACKUP"
printf '%s\n' "$MISSING" | while IFS= read -r domain; do
  [ -n "$domain" ] && uci add_list "$SECTION=$domain"
done
uci commit zeroblock

# Restart can interrupt SSH. The backup remains available for manual recovery.
if ! /etc/init.d/zeroblock restart; then
  echo "ERROR: restart failed. Backup: $BACKUP" >&2
  exit 1
fi
sleep 5
if ! sing-box check -C /tmp/zeroblock/sing-box.d -D /tmp/zeroblock; then
  echo "ERROR: generated sing-box config invalid. Backup: $BACKUP" >&2
  exit 1
fi
echo "OK: applied and validated. Backup: $BACKUP"
