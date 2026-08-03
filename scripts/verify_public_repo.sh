#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO_ROOT"

for script in scripts/*.sh; do
  bash -n "$script"
done

python3 -m compileall -q scripts
python3 - <<'PY'
import json
from pathlib import Path
for path in sorted(Path("configs").glob("*.json")) + sorted(Path("evidence").glob("*.json")):
    json.loads(path.read_text(encoding="utf-8"))
    print("JSON_OK", path)
PY

if command -v sha256sum >/dev/null; then
  sha256sum -c SHA256SUMS >/dev/null
else
  shasum -a 256 -c SHA256SUMS >/dev/null
fi

if rg -n --hidden \
  'BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY|gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_|AKIA[0-9A-Z]{16}|root@[0-9]+\.|36\.150\.116\.206' \
  --glob '!.git/**' --glob '!.gitignore' --glob '!scripts/verify_public_repo.sh' .; then
  printf 'Potential credential or private endpoint found.\n' >&2
  exit 2
fi

if find . -type f -size +10M -not -path './.git/*' | grep -q .; then
  printf 'Unexpected file larger than 10 MiB:\n' >&2
  find . -type f -size +10M -not -path './.git/*' >&2
  exit 2
fi

printf 'PUBLIC_REPO_CHECK_OK\n'
