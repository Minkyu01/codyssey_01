#!/usr/bin/env bash

set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
cd "$PROJECT_ROOT"

PASS_COUNT=0

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "required command not found: $1"
  fi
  pass "command available: $1"
}

require_file() {
  if [ ! -f "$1" ]; then
    fail "required file missing: $1"
  fi
  pass "required file exists: $1"
}

require_executable() {
  if [ ! -x "$1" ]; then
    fail "script is not executable: $1"
  fi
  pass "script is executable: $1"
}

require_pattern() {
  file_path=$1
  pattern=$2
  description=$3

  if ! grep -Eq "$pattern" "$file_path"; then
    fail "$description ($file_path)"
  fi
  pass "$description"
}

printf '== Required commands ==\n'
require_command bash
require_command docker
require_command grep
require_command python3

printf '\n== Required project files ==\n'
for required_path in \
  purpose.md \
  README.md \
  Dockerfile \
  compose.yaml \
  nginx/default.conf \
  site/index.html \
  site/styles.css \
  site/data/welcome.txt \
  backend/Dockerfile \
  backend/server.py \
  trouble.md \
  study/todo.md \
  scripts/verify.sh \
  scripts/terminal_permissions.sh \
  tests/static_check.sh
do
  require_file "$required_path"
done

printf '\n== Executable scripts ==\n'
require_executable scripts/verify.sh
require_executable scripts/terminal_permissions.sh
require_executable tests/static_check.sh

printf '\n== Shell syntax ==\n'
bash -n scripts/verify.sh scripts/terminal_permissions.sh tests/static_check.sh
pass "bash syntax"

if command -v zsh >/dev/null 2>&1; then
  zsh -n scripts/verify.sh scripts/terminal_permissions.sh tests/static_check.sh
  pass "zsh syntax"
else
  printf 'SKIP: zsh is not installed; bash syntax was checked\n'
fi

printf '\n== Dockerfile and NGINX configuration ==\n'
require_pattern Dockerfile \
  '^FROM[[:space:]]+nginx:[^[:space:]]+' \
  "Dockerfile uses an NGINX base image"
require_pattern Dockerfile \
  '^COPY[[:space:]]+nginx/default\.conf[[:space:]]+/etc/nginx/conf\.d/default\.conf' \
  "Dockerfile copies the NGINX configuration"
require_pattern Dockerfile \
  '^COPY[[:space:]]+site/[[:space:]]+/usr/share/nginx/html/' \
  "Dockerfile copies the static site"
require_pattern Dockerfile \
  '^EXPOSE[[:space:]]+80([[:space:]]|$)' \
  "Dockerfile documents container port 80"
require_pattern Dockerfile \
  '^HEALTHCHECK[[:space:]]' \
  "Dockerfile defines a health check"
require_pattern nginx/default.conf \
  'listen[[:space:]]+80;' \
  "NGINX listens on port 80"
require_pattern nginx/default.conf \
  'location[[:space:]]*=[[:space:]]*/healthz' \
  "NGINX defines /healthz"

printf '\n== Compose configuration ==\n'
docker compose config --quiet
pass "docker compose config"
require_pattern compose.yaml \
  '\$\{HOST_PORT:-8080\}:80|8080:80' \
  "Compose publishes host port 8080 to container port 80"
require_pattern compose.yaml \
  'workstation-data:/usr/share/nginx/html/data' \
  "Compose mounts the named data volume"

printf '\n== Python syntax without bytecode output ==\n'
python3 -c 'import ast, pathlib; path = pathlib.Path("backend/server.py"); ast.parse(path.read_text(encoding="utf-8"), filename=str(path))'
pass "backend/server.py AST parse"

printf '\n== Local Markdown links and referenced scripts ==\n'
python3 - "$PROJECT_ROOT" <<'PY'
from pathlib import Path
import re
import sys
from urllib.parse import unquote

root = Path(sys.argv[1]).resolve()
missing = []

markdown_link = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
script_reference = re.compile(r"(?<![A-Za-z0-9_.])(\./(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+\.sh)")

for document in sorted(path for path in root.rglob("*.md") if ".git" not in path.parts):
    text = document.read_text(encoding="utf-8")

    for raw_target in markdown_link.findall(text):
        target = raw_target.strip().strip("<>")
        if not target or target.startswith(("#", "/", "http://", "https://", "mailto:")):
            continue
        target = unquote(target.split("#", 1)[0].split("?", 1)[0])
        if not (document.parent / target).exists():
            missing.append(f"{document.relative_to(root)} -> {raw_target}")

    for raw_target in script_reference.findall(text):
        target = raw_target[2:]
        if not (root / target).is_file():
            missing.append(f"{document.relative_to(root)} -> {raw_target}")

if missing:
    print("FAIL: stale or missing local references:", file=sys.stderr)
    for item in missing:
        print(f"  {item}", file=sys.stderr)
    raise SystemExit(1)

print("PASS: all local Markdown links and referenced scripts resolve")
PY
PASS_COUNT=$((PASS_COUNT + 1))

printf '\nPASS: static verification completed (%s checks)\n' "$PASS_COUNT"
