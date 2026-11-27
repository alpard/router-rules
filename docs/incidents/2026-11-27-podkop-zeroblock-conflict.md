# RouteRich: Podkop / ZeroBlock routing conflict (2026-11-27)

## Incident

ChatGPT did not open from a desktop browser through the RouteRich router, while it worked when a separate VPN subscription/client was enabled. Notion and Miro were also included in the affected routing checks.

## Findings

- ZeroBlock was running; sing-box was running and its configuration passed `sing-box check`.
- The active ZeroBlock selector `theforceful` selected `theforceful__auto`; URLTest selected a working server (Germany/Poland during the checks).
- The DNS resolver returned synthetic addresses in `198.18.0.0/15` for ChatGPT and other routed domains, as expected for the configured sing-box DNS/routing design.
- The Podkop service was not running, no Podkop process was present, its port 1602 was not listening, and no Podkop autostart symlink was found.
- Despite the stopped service, an old `inet PodkopTable` nftables table remained loaded. It contained prerouting/output interception chains at the same mangle priority as ZeroBlock and rules for synthetic `198.18.0.0/15` destinations. ZeroBlock's own `inet zeroblock` table and TProxy listener on `127.0.0.1:2154` were active.
- This leftover nftables table was a plausible routing conflict. The available checks do not prove it was the sole cause.

## Remediation performed

Before changing runtime firewall state, a backup was created on the router:

```
/root/backup-podkop-20261127-181337/
  zeroblock
  nftables.txt
  PodkopTable.nft
  ip-rules.txt
  ip-routes.txt
```

Then only the stale nftables table was removed:

```sh
nft delete table inet PodkopTable
```

No ZeroBlock configuration was changed, no service was restarted, and the router was not rebooted. After removal, the loaded nftables tables were:

```
table inet fw4
table inet zeroblock
```

## Verification

With the separate desktop VPN client disabled, Windows PowerShell tests returned:

| URL | HTTP result | Time |
|---|---:|---:|
| https://chatgpt.com | 200 | 0.400 s |
| https://notion.so | 301 (redirect) | 0.291 s |
| https://miro.com | 200 | 0.743 s |

A separate ChatGPT request also returned HTTP 200 in 0.503 s.

The DNS flush command on Windows was denied because PowerShell was not elevated; it was not required for the successful HTTP tests.

## Current status and follow-up

- ChatGPT, Notion, and Miro passed command-line HTTPS checks through the router without the separate VPN client.
- Browser-level confirmation and persistence after a router reboot have not yet been recorded.
- The `ip rule` output still showed a policy rule for fwmark `0x105` using table `podkop`. Do not remove policy rules or make further routing changes until their ownership and impact are checked.
- Do not delete the Podkop package/configuration or alter ZeroBlock, subscription, WARP/AmneziaWG, or MHC SSTP settings as part of this incident record.

## Operational lesson

When a routing service is stopped or uninstalled, inspect its nftables tables and policy-routing rules separately. A stopped process does not guarantee that kernel firewall state has been removed. Back up the live firewall/routing state before cleanup, remove only the confirmed stale component, then verify each affected destination without changing the working proxy configuration.
