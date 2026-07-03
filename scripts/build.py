from pathlib import Path

BASE = Path(__file__).resolve().parent.parent

domains_dir = BASE / "domains"
generated = BASE / "generated"

generated.mkdir(exist_ok=True)

all_domains = set()

for f in sorted(domains_dir.glob("*.txt")):
    domains = []

    for line in f.read_text().splitlines():
        line = line.strip()

        if not line:
            continue

        if line.startswith("#"):
            continue

        domains.append(line)

    domains = sorted(set(domains))

    (generated / f.name).write_text(
        "\n".join(domains) + "\n"
    )

    all_domains.update(domains)

proxy = sorted(all_domains)

(generated / "proxy.txt").write_text(
    "\n".join(proxy) + "\n"
)

print(f"Generated {len(proxy)} domains.")
