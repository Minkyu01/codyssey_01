#!/usr/bin/env bash

set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
TEMP_BASE=${TMPDIR:-/tmp}
WORK_DIR=""

cleanup() {
  cleanup_status=$?
  trap - EXIT
  set +e

  if [ -n "$WORK_DIR" ]; then
    chmod u+rwx "$WORK_DIR" "$WORK_DIR/terminal-practice" \
      "$WORK_DIR/terminal-practice/permission-dir" >/dev/null 2>&1
    chmod u+rw "$WORK_DIR/terminal-practice/original.txt" \
      "$WORK_DIR/terminal-practice/permission-file.txt" >/dev/null 2>&1
    rm -f \
      "$WORK_DIR/terminal-practice/original.txt" \
      "$WORK_DIR/terminal-practice/copy.txt" \
      "$WORK_DIR/terminal-practice/moved.txt" \
      "$WORK_DIR/terminal-practice/permission-file.txt"
    rmdir "$WORK_DIR/terminal-practice/permission-dir" >/dev/null 2>&1
    rmdir "$WORK_DIR/terminal-practice" >/dev/null 2>&1
    rmdir "$WORK_DIR" >/dev/null 2>&1
  fi

  printf '\ncleanup: temporary terminal practice removed\n'
  exit "$cleanup_status"
}

trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP
trap cleanup EXIT

printf '== Current location and hidden-file listing ==\n'
printf '$ cd %s\n' "$PROJECT_ROOT"
cd "$PROJECT_ROOT"
printf '$ pwd\n'
pwd
printf '$ ls -la\n'
ls -la

printf '\n== Temporary workspace and directory movement ==\n'
WORK_DIR=$(mktemp -d "${TEMP_BASE%/}/codex-ex01-terminal.XXXXXX")
printf '$ cd %s\n' "$WORK_DIR"
cd "$WORK_DIR"
printf '$ pwd\n'
pwd
printf '$ ls -la\n'
ls -la

printf '\n== Create directory and empty file ==\n'
printf '$ mkdir terminal-practice\n'
mkdir terminal-practice
printf '$ cd terminal-practice\n'
cd terminal-practice
printf '$ touch original.txt\n'
touch original.txt
printf '$ ls -la\n'
ls -la

printf '\n== Write and read file content ==\n'
printf '$ printf \"Hello from terminal practice\\\\n\" > original.txt\n'
printf 'Hello from terminal practice\n' > original.txt
printf '$ cat original.txt\n'
cat original.txt

printf '\n== Copy and rename ==\n'
printf '$ cp original.txt copy.txt\n'
cp original.txt copy.txt
printf '$ ls -la\n'
ls -la
printf '$ mv copy.txt moved.txt\n'
mv copy.txt moved.txt
printf '$ ls -la\n'
ls -la

printf '\n== Delete and verify ==\n'
printf '$ rm moved.txt\n'
rm moved.txt
printf '$ ls -la\n'
ls -la

printf '\n== File permission before and after ==\n'
printf '$ touch permission-file.txt\n'
touch permission-file.txt
printf '$ chmod 644 permission-file.txt\n'
chmod 644 permission-file.txt
printf '$ ls -l permission-file.txt\n'
ls -l permission-file.txt
printf '$ chmod 640 permission-file.txt\n'
chmod 640 permission-file.txt
printf '$ ls -l permission-file.txt\n'
ls -l permission-file.txt

printf '\n== Directory permission before and after ==\n'
printf '$ mkdir permission-dir\n'
mkdir permission-dir
printf '$ chmod 755 permission-dir\n'
chmod 755 permission-dir
printf '$ ls -ld permission-dir\n'
ls -ld permission-dir
printf '$ chmod 750 permission-dir\n'
chmod 750 permission-dir
printf '$ ls -ld permission-dir\n'
ls -ld permission-dir

printf '\nPASS: terminal operations and file/directory permission changes completed\n'
