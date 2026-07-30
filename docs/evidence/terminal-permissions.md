# 터미널 조작과 권한 검증

2026년 7월 30일에 [`scripts/terminal_permissions.sh`](../../scripts/terminal_permissions.sh)를 직접 실행했습니다. 스크립트는 고유한 임시 디렉터리만 사용하고 종료 시 삭제합니다.

## 실행 명령

```console
$ ./scripts/terminal_permissions.sh
```

## 위치·목록·이동

개인 절대 경로와 사용자명은 `<project-root>`, `<temporary-directory>`, `<user>`로 가렸습니다.

```console
== Current location and hidden-file listing ==
$ cd <project-root>
$ pwd
<project-root>
$ ls -la
...
-rw-r--r--  1 <user>  staff   774 Jul 28 16:04 Dockerfile
-rw-r--r--  1 <user>  staff   ... Jul 30 ... README.md
drwxr-xr-x  ... docs
drwxr-xr-x  ... scripts
drwxr-xr-x  ... tests

== Temporary workspace and directory movement ==
$ cd <temporary-directory>
$ pwd
<temporary-directory>
$ ls -la
total 0
drwx------  ... .
drwx------  ... ..
```

`pwd`, 숨김 항목을 포함한 `ls -la`, `cd` 이동을 한 흐름에서 확인했습니다.

## 생성·내용 확인·복사·이름 변경·삭제

```console
== Create directory and empty file ==
$ mkdir terminal-practice
$ cd terminal-practice
$ touch original.txt
$ ls -la
-rw-r--r--  1 <user>  staff  0 Jul 30 15:49 original.txt

== Write and read file content ==
$ printf "Hello from terminal practice\n" > original.txt
$ cat original.txt
Hello from terminal practice

== Copy and rename ==
$ cp original.txt copy.txt
$ mv copy.txt moved.txt
$ ls -la
-rw-r--r--  1 <user>  staff  29 Jul 30 15:49 moved.txt
-rw-r--r--  1 <user>  staff  29 Jul 30 15:49 original.txt

== Delete and verify ==
$ rm moved.txt
$ ls -la
-rw-r--r--  1 <user>  staff  29 Jul 30 15:49 original.txt
```

`touch`로 빈 파일을 만든 뒤 내용을 쓰고 읽었습니다. `cp`, `mv`, `rm` 결과도 각 목록에서 확인했습니다.

## 파일 권한 전·후

```console
$ chmod 644 permission-file.txt
$ ls -l permission-file.txt
-rw-r--r--  1 <user>  staff  0 Jul 30 15:49 permission-file.txt

$ chmod 640 permission-file.txt
$ ls -l permission-file.txt
-rw-r-----  1 <user>  staff  0 Jul 30 15:49 permission-file.txt
```

`644`는 소유자에게 읽기·쓰기, 그룹과 기타 사용자에게 읽기 권한을 줍니다. `640`은 기타 사용자의 읽기 권한을 제거합니다.

## 디렉터리 권한 전·후

```console
$ chmod 755 permission-dir
$ ls -ld permission-dir
drwxr-xr-x  2 <user>  staff  64 Jul 30 15:49 permission-dir

$ chmod 750 permission-dir
$ ls -ld permission-dir
drwxr-x---  2 <user>  staff  64 Jul 30 15:49 permission-dir
```

디렉터리에서 `x`는 해당 경로로 진입하고 내부 항목에 접근할 수 있는 권한입니다. `750`은 기타 사용자의 모든 권한을 제거합니다.

## 결과와 정리

```text
PASS: terminal operations and file/directory permission changes completed
cleanup: temporary terminal practice removed
```

실행 종료 후 임시 디렉터리가 남지 않은 것을 확인했습니다.

