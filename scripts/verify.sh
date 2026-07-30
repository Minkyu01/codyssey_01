#!/usr/bin/env bash

set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
cd "$PROJECT_ROOT"

RUN_ID=${VERIFY_RUN_ID:-"$(date +%Y%m%d%H%M%S)-$$"}
RESOURCE_PREFIX=${VERIFY_RESOURCE_PREFIX:-codex-ex01}
IMAGE_NAME=${VERIFY_IMAGE:-"${RESOURCE_PREFIX}-web:${RUN_ID}"}
WEB_CONTAINER=${VERIFY_WEB_CONTAINER:-"${RESOURCE_PREFIX}-web-${RUN_ID}"}
BIND_CONTAINER=${VERIFY_BIND_CONTAINER:-"${RESOURCE_PREFIX}-bind-${RUN_ID}"}
VOLUME_CONTAINER_ONE=${VERIFY_VOLUME_CONTAINER_ONE:-"${RESOURCE_PREFIX}-volume-one-${RUN_ID}"}
VOLUME_CONTAINER_TWO=${VERIFY_VOLUME_CONTAINER_TWO:-"${RESOURCE_PREFIX}-volume-two-${RUN_ID}"}
VOLUME_NAME=${VERIFY_VOLUME_NAME:-"${RESOURCE_PREFIX}-data-${RUN_ID}"}
HOST_PORT=${HOST_PORT:-38080}
BIND_PORT=${BIND_PORT:-38081}
WAIT_SECONDS=${VERIFY_WAIT_SECONDS:-45}

WEB_CREATED=0
BIND_CREATED=0
VOLUME_ONE_CREATED=0
VOLUME_TWO_CREATED=0
VOLUME_CREATED=0
IMAGE_CREATED=0
BIND_DIR=""

section() {
  printf '\n== %s ==\n' "$1"
}

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

cleanup() {
  cleanup_status=$?
  trap - EXIT
  set +e

  printf '\n== Cleanup (script-created resources only) ==\n'

  if [ "$WEB_CREATED" -eq 1 ]; then
    docker rm -f "$WEB_CONTAINER" >/dev/null 2>&1
  fi
  if [ "$BIND_CREATED" -eq 1 ]; then
    docker rm -f "$BIND_CONTAINER" >/dev/null 2>&1
  fi
  if [ "$VOLUME_ONE_CREATED" -eq 1 ]; then
    docker rm -f "$VOLUME_CONTAINER_ONE" >/dev/null 2>&1
  fi
  if [ "$VOLUME_TWO_CREATED" -eq 1 ]; then
    docker rm -f "$VOLUME_CONTAINER_TWO" >/dev/null 2>&1
  fi
  if [ "$VOLUME_CREATED" -eq 1 ]; then
    docker volume rm "$VOLUME_NAME" >/dev/null 2>&1
  fi
  if [ "$IMAGE_CREATED" -eq 1 ]; then
    docker image rm "$IMAGE_NAME" >/dev/null 2>&1
  fi

  if [ -n "$BIND_DIR" ]; then
    rm -f "$BIND_DIR/index.html"
    rmdir "$BIND_DIR" >/dev/null 2>&1
  fi

  printf 'cleanup complete\n'
  exit "$cleanup_status"
}

trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP
trap cleanup EXIT

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "required command not found: $1"
  fi
}

validate_port() {
  port_name=$1
  port_value=$2

  case "$port_value" in
    ''|*[!0-9]*)
      fail "$port_name must be an integer: $port_value"
      ;;
  esac

  if [ "$port_value" -lt 1 ] || [ "$port_value" -gt 65535 ]; then
    fail "$port_name must be between 1 and 65535: $port_value"
  fi
}

validate_resource_name() {
  resource_label=$1
  resource_value=$2

  if ! printf '%s\n' "$resource_value" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9_.-]*$'; then
    fail "$resource_label contains unsupported characters: $resource_value"
  fi
}

assert_port_available() {
  port_value=$1

  if ! python3 - "$port_value" <<'PY'
import socket
import sys

port = int(sys.argv[1])
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    sock.bind(("127.0.0.1", port))
except OSError:
    raise SystemExit(1)
finally:
    sock.close()
PY
  then
    fail "127.0.0.1:$port_value is already in use"
  fi
}

assert_container_absent() {
  container_name=$1
  if docker container inspect "$container_name" >/dev/null 2>&1; then
    fail "container already exists; refusing to touch it: $container_name"
  fi
}

wait_for_health() {
  container_name=$1
  attempt=0

  while [ "$attempt" -lt "$WAIT_SECONDS" ]; do
    health_status=$(docker inspect \
      --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}missing{{end}}' \
      "$container_name" 2>/dev/null || true)

    if [ "$health_status" = "healthy" ]; then
      printf 'health=%s container=%s\n' "$health_status" "$container_name"
      return 0
    fi

    attempt=$((attempt + 1))
    sleep 1
  done

  docker inspect --format 'state={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}missing{{end}}' \
    "$container_name" >&2 || true
  docker logs --tail 50 "$container_name" >&2 || true
  fail "container did not become healthy within ${WAIT_SECONDS}s: $container_name"
}

wait_for_http_body() {
  url=$1
  expected_body=$2
  attempt=0

  while [ "$attempt" -lt "$WAIT_SECONDS" ]; do
    actual_body=$(curl --fail --silent --show-error --max-time 2 "$url" 2>/dev/null || true)
    if [ "$actual_body" = "$expected_body" ]; then
      printf 'HTTP 200 body=%s url=%s\n' "$actual_body" "$url"
      return 0
    fi

    attempt=$((attempt + 1))
    sleep 1
  done

  fail "HTTP response did not match within ${WAIT_SECONDS}s: $url"
}

section "Preflight"
require_command docker
require_command curl
require_command python3
require_command grep

validate_port HOST_PORT "$HOST_PORT"
validate_port BIND_PORT "$BIND_PORT"
validate_port VERIFY_WAIT_SECONDS "$WAIT_SECONDS"

if [ "$HOST_PORT" -eq "$BIND_PORT" ]; then
  fail "HOST_PORT and BIND_PORT must be different"
fi

validate_resource_name VERIFY_WEB_CONTAINER "$WEB_CONTAINER"
validate_resource_name VERIFY_BIND_CONTAINER "$BIND_CONTAINER"
validate_resource_name VERIFY_VOLUME_CONTAINER_ONE "$VOLUME_CONTAINER_ONE"
validate_resource_name VERIFY_VOLUME_CONTAINER_TWO "$VOLUME_CONTAINER_TWO"
validate_resource_name VERIFY_VOLUME_NAME "$VOLUME_NAME"

assert_port_available "$HOST_PORT"
assert_port_available "$BIND_PORT"

assert_container_absent "$WEB_CONTAINER"
assert_container_absent "$BIND_CONTAINER"
assert_container_absent "$VOLUME_CONTAINER_ONE"
assert_container_absent "$VOLUME_CONTAINER_TWO"

if docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
  fail "volume already exists; refusing to touch it: $VOLUME_NAME"
fi

if docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  fail "image already exists; refusing to overwrite it: $IMAGE_NAME"
fi

printf '$ docker --version\n'
docker --version
printf "$ docker info --format 'ServerVersion={{.ServerVersion}} Driver={{.Driver}} OperatingSystem={{.OperatingSystem}} OSType={{.OSType}} Architecture={{.Architecture}}'\n"
docker info --format \
  'ServerVersion={{.ServerVersion}} Driver={{.Driver}} OperatingSystem={{.OperatingSystem}} OSType={{.OSType}} Architecture={{.Architecture}}'
printf 'ports available: 127.0.0.1:%s, 127.0.0.1:%s\n' "$HOST_PORT" "$BIND_PORT"

section "Build current Dockerfile"
printf '$ docker build --file Dockerfile --tag %s .\n' "$IMAGE_NAME"
docker build --file Dockerfile --tag "$IMAGE_NAME" .
IMAGE_CREATED=1

printf '$ docker images %s\n' "$IMAGE_NAME"
docker images "$IMAGE_NAME"

section "Port mapping, health, operations, stop/start"
printf '$ docker create --name %s --publish 127.0.0.1:%s:80 %s\n' \
  "$WEB_CONTAINER" "$HOST_PORT" "$IMAGE_NAME"
docker create \
  --name "$WEB_CONTAINER" \
  --publish "127.0.0.1:${HOST_PORT}:80" \
  "$IMAGE_NAME"
WEB_CREATED=1

printf '$ docker start %s\n' "$WEB_CONTAINER"
docker start "$WEB_CONTAINER"
wait_for_health "$WEB_CONTAINER"
wait_for_http_body "http://127.0.0.1:${HOST_PORT}/healthz" "ok"

printf '$ curl --fail http://127.0.0.1:%s/\n' "$HOST_PORT"
root_body=$(curl --fail --silent --show-error --max-time 5 "http://127.0.0.1:${HOST_PORT}/")
case "$root_body" in
  *"Docker Workstation Lab"*)
    printf 'HTTP 200 root page contains: Docker Workstation Lab\n'
    ;;
  *)
    fail "root page did not contain the expected project title"
    ;;
esac

printf '$ docker ps --filter name=^/%s$\n' "$WEB_CONTAINER"
docker ps \
  --filter "name=^/${WEB_CONTAINER}$" \
  --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

printf '$ docker ps -a --filter name=^/%s$\n' "$WEB_CONTAINER"
docker ps -a \
  --filter "name=^/${WEB_CONTAINER}$" \
  --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

printf '$ docker logs --tail 20 %s\n' "$WEB_CONTAINER"
docker logs --tail 20 "$WEB_CONTAINER"

printf '$ docker stats --no-stream %s\n' "$WEB_CONTAINER"
docker stats --no-stream \
  --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}' \
  "$WEB_CONTAINER"

printf '$ docker stop --timeout 5 %s\n' "$WEB_CONTAINER"
docker stop --timeout 5 "$WEB_CONTAINER"
docker ps -a \
  --filter "name=^/${WEB_CONTAINER}$" \
  --format 'after-stop name={{.Names}} status={{.Status}}'

printf '$ docker start %s\n' "$WEB_CONTAINER"
docker start "$WEB_CONTAINER"
wait_for_health "$WEB_CONTAINER"
wait_for_http_body "http://127.0.0.1:${HOST_PORT}/healthz" "ok"

section "Bind mount before and after"
TEMP_BASE=${TMPDIR:-/tmp}
BIND_DIR=$(mktemp -d "${TEMP_BASE%/}/codex-ex01-bind.XXXXXX")
BIND_BEFORE="bind-before-${RUN_ID}"
BIND_AFTER="bind-after-${RUN_ID}"
printf '%s\n' "$BIND_BEFORE" > "$BIND_DIR/index.html"

printf '$ docker create --name %s --publish 127.0.0.1:%s:80 --mount type=bind,...,readonly %s\n' \
  "$BIND_CONTAINER" "$BIND_PORT" "$IMAGE_NAME"
docker create \
  --name "$BIND_CONTAINER" \
  --publish "127.0.0.1:${BIND_PORT}:80" \
  --mount "type=bind,source=${BIND_DIR},target=/usr/share/nginx/html,readonly" \
  "$IMAGE_NAME"
BIND_CREATED=1

docker start "$BIND_CONTAINER"
wait_for_health "$BIND_CONTAINER"
wait_for_http_body "http://127.0.0.1:${BIND_PORT}/" "$BIND_BEFORE"

printf '$ printf %s > %s/index.html\n' "$BIND_AFTER" "$BIND_DIR"
printf '%s\n' "$BIND_AFTER" > "$BIND_DIR/index.html"
wait_for_http_body "http://127.0.0.1:${BIND_PORT}/" "$BIND_AFTER"

printf '$ docker rm -f %s\n' "$BIND_CONTAINER"
docker rm -f "$BIND_CONTAINER"
BIND_CREATED=0

section "Named volume persistence across container deletion"
printf '$ docker volume create %s\n' "$VOLUME_NAME"
docker volume create "$VOLUME_NAME"
VOLUME_CREATED=1

printf '$ docker create --name %s --mount type=volume,source=%s,target=/usr/share/nginx/html/data %s\n' \
  "$VOLUME_CONTAINER_ONE" "$VOLUME_NAME" "$IMAGE_NAME"
docker create \
  --name "$VOLUME_CONTAINER_ONE" \
  --mount "type=volume,source=${VOLUME_NAME},target=/usr/share/nginx/html/data" \
  "$IMAGE_NAME"
VOLUME_ONE_CREATED=1
docker start "$VOLUME_CONTAINER_ONE"

PERSIST_VALUE="volume-persists-${RUN_ID}"
printf '$ docker exec %s sh -c \"write and read persist.txt\"\n' "$VOLUME_CONTAINER_ONE"
written_value=$(docker exec "$VOLUME_CONTAINER_ONE" \
  sh -c 'printf "%s\n" "$1" > /usr/share/nginx/html/data/persist.txt; cat /usr/share/nginx/html/data/persist.txt' \
  sh "$PERSIST_VALUE")
printf 'before-delete=%s\n' "$written_value"
if [ "$written_value" != "$PERSIST_VALUE" ]; then
  fail "first container did not write the expected volume data"
fi

printf '$ docker rm -f %s\n' "$VOLUME_CONTAINER_ONE"
docker rm -f "$VOLUME_CONTAINER_ONE"
VOLUME_ONE_CREATED=0

printf '$ docker create --name %s --mount type=volume,source=%s,target=/usr/share/nginx/html/data %s\n' \
  "$VOLUME_CONTAINER_TWO" "$VOLUME_NAME" "$IMAGE_NAME"
docker create \
  --name "$VOLUME_CONTAINER_TWO" \
  --mount "type=volume,source=${VOLUME_NAME},target=/usr/share/nginx/html/data" \
  "$IMAGE_NAME"
VOLUME_TWO_CREATED=1
docker start "$VOLUME_CONTAINER_TWO"

printf '$ docker exec %s cat /usr/share/nginx/html/data/persist.txt\n' "$VOLUME_CONTAINER_TWO"
persisted_value=$(docker exec "$VOLUME_CONTAINER_TWO" \
  cat /usr/share/nginx/html/data/persist.txt)
printf 'after-delete-and-recreate=%s\n' "$persisted_value"
if [ "$persisted_value" != "$PERSIST_VALUE" ]; then
  fail "named volume data did not survive container deletion"
fi

section "Verification result"
printf 'PASS: build, health, localhost port mapping, operations, stop/start, bind mount, and volume persistence\n'
