# RouteRich: Notion routing fix

Date: 2026-11-19

## Result

Notion was restored on the affected device after adding the Notion emoji asset host to the ZeroBlock `theforceful` user-domain list.

## Root cause observed

The sing-box connection log showed that the main Notion hosts were routed through `theforceful`, but the asset host below did not match a proxy rule and fell through to the final route:

- `notion-emojis.s3-us-west-2.amazonaws.com`

Observed before the fix:

- Main Notion traffic: `theforceful` (automatic selector, currently choosing Germany).
- `notion-emojis.s3-us-west-2.amazonaws.com`: `mhc_za__failover`, rule `final`, 0 bytes downloaded.

## Applied change

Added this exact hostname to:

- UCI option: `zeroblock.theforceful.user_domains_text`
- Generated sing-box rule set: `user-domains-text-theforceful` in `/tmp/zeroblock/sing-box.d/40-route.json`

Hostname:

```text
notion-emojis.s3-us-west-2.amazonaws.com
```

Applied with:

```sh
uci -q del_list zeroblock.theforceful.user_domains_text="notion-emojis.s3-us-west-2.amazonaws.com"
uci add_list zeroblock.theforceful.user_domains_text="notion-emojis.s3-us-west-2.amazonaws.com"
uci commit zeroblock
/etc/init.d/zeroblock restart
```

## Verification

After restart:

- ZeroBlock status: `running`
- Hostname present in UCI.
- Hostname present in generated `40-route.json` under `domain_suffix`.
- `sing-box check -C /tmp/zeroblock/sing-box.d -D /tmp/zeroblock` completed without errors.
- User confirmed that Notion works.

## Operational notes

- The live UCI configuration at `/etc/config/zeroblock` is the active source for this RouteRich setup; files under `/tmp/zeroblock/sing-box.d/` are generated and must not be edited directly.
- The fix was applied on the router and documented here. This repository's existing README describes a Podkop rules-list workflow; no automatic deployment of this ZeroBlock UCI option from this repository is assumed.
- Backup created before the change: `/root/zeroblock-before-notion-s3-YYYYMMDD-HHMMSS.conf` (actual timestamp on router: 2026-11-19).
