#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO_ROOT"

for script in scripts/*.sh reconstruction/bin/*.sh reconstruction/reference/*.sh; do
  bash -n "$script"
done

python3 -m compileall -q scripts reconstruction/src
python3 - <<'PY'
import json
from pathlib import Path
paths = (
    sorted(Path("configs").glob("*.json"))
    + sorted(Path("evidence").glob("*.json"))
    + sorted(Path("data/manifests").glob("*.json"))
)
for path in paths:
    json.loads(path.read_text(encoding="utf-8"))
    print("JSON_OK", path)
PY

if command -v sha256sum >/dev/null; then
  sha256sum -c SHA256SUMS >/dev/null
else
  shasum -a 256 -c SHA256SUMS >/dev/null
fi

if rg -n --hidden \
  'BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY|gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_|AKIA[0-9A-Z]{16}|root@[0-9]+\.|36\.150\.116\.206|ccr-[A-Za-z0-9.-]+|poc\.config' \
  --glob '!.git/**' --glob '!.gitignore' --glob '!scripts/verify_public_repo.sh' .; then
  printf 'Potential credential or private endpoint found.\n' >&2
  exit 2
fi

if git ls-files | rg '\.(ply|pt|ckpt|zip|tar\.zst)$|^data/private/'; then
  printf 'Licensed source data, model assets, or checkpoints are tracked.\n' >&2
  exit 2
fi

python3 - <<'PY'
import json
from pathlib import Path

source = json.loads(Path("data/manifests/dl3dv-kitchen-source.public.json").read_text())
assert source["source"]["archive_bytes"] == 220332698
assert source["source"]["archive_sha256"] == "4a6f3eac1ff4d2545b655fdfe5c6edd7e08f92e847584fabf933a09e592be563"
assert source["redistribution"]["source_archive_in_repo"] is False
reconstruction = json.loads(Path("data/manifests/a800-reconstruction.public.json").read_text())
assert reconstruction["method"]["strategy"] == "mcmc"
assert reconstruction["method"]["steps"] == 30000
assert len(reconstruction["shell_assets"]) == 4
print("DATA_CONTRACT_OK")
PY

if find . -type f -size +10M -not -path './.git/*' | grep -q .; then
  printf 'Unexpected file larger than 10 MiB:\n' >&2
  find . -type f -size +10M -not -path './.git/*' >&2
  exit 2
fi

printf 'PUBLIC_REPO_CHECK_OK\n'
