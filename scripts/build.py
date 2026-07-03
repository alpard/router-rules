from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOMAINS = ROOT / "domains"
GENERATED = ROOT / "generated"

GENERATED.mkdir(exist_ok=True)

exclude = {"direct.txt"}
proxy_domains = []

for file in sorted(DOMAINS.glob("*.txt")):
    if file.name in exclude:
        continue

    for line in file.read_text(encoding="utf-8").splitlines():
        line = line.strip()

        if not line or line.startswith("#"):
            continue

        proxy_domains.append(line)

proxy_domains = sorted(set(proxy_domains))

(GENERATED / "proxy.txt").write_text(
    "\n".join(proxy_domains) + "\n",
    encoding="utf-8"
)

print(f"Generated {len(proxy_domains)} domains -> generated/proxy.txt")
