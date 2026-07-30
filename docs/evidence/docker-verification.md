# Docker 통합 검증

2026년 7월 30일에 최종 소스와 [`scripts/verify.sh`](../../scripts/verify.sh)를 사용했습니다. 사용자 서비스와 겹치지 않도록 `38080`, `38081` 포트와 `codex-ex01-*-docs-20260730` 이름을 지정했습니다.

## 실행 명령

```console
$ VERIFY_RUN_ID=docs-20260730 \
    HOST_PORT=38080 \
    BIND_PORT=38081 \
    ./scripts/verify.sh
```

스크립트는 실행 전 포트·컨테이너·볼륨·이미지 충돌을 검사합니다. 스크립트가 만든 자원만 `trap`으로 정리합니다.

## Docker Engine

```console
$ docker --version
Docker version 29.4.1, build 055a478

$ docker info --format \
    'ServerVersion={{.ServerVersion}} Driver={{.Driver}} OperatingSystem={{.OperatingSystem}} OSType={{.OSType}} Architecture={{.Architecture}}'
ServerVersion=29.4.1 Driver=overlayfs OperatingSystem=Docker Desktop OSType=linux Architecture=aarch64

ports available: 127.0.0.1:38080, 127.0.0.1:38081
```

## 이미지 빌드

```console
$ docker build --file Dockerfile --tag codex-ex01-web:docs-20260730 .
...
#9 naming to docker.io/library/codex-ex01-web:docs-20260730 done
#9 DONE 0.0s

$ docker images codex-ex01-web:docs-20260730
IMAGE                          ID             DISK USAGE   CONTENT SIZE
codex-ex01-web:docs-20260730   ff16653c753e         76MB         21.8MB
```

빌드 과정에서 최종 `Dockerfile`, `nginx/default.conf`, `site/`를 사용했습니다.

## 포트·헬스체크·운영 명령

```console
$ docker create \
    --name codex-ex01-web-docs-20260730 \
    --publish 127.0.0.1:38080:80 \
    codex-ex01-web:docs-20260730
2bb11f562df76efb2ab4943dc6a9b48c9b1e1e15f94dc8fcbc3598f64fb6f28c

$ docker start codex-ex01-web-docs-20260730
codex-ex01-web-docs-20260730
health=healthy container=codex-ex01-web-docs-20260730
HTTP 200 body=ok url=http://127.0.0.1:38080/healthz

$ curl --fail http://127.0.0.1:38080/
HTTP 200 root page contains: Docker Workstation Lab
```

실행 중 목록과 전체 목록에서 같은 컨테이너와 포트 매핑을 확인했습니다.

```console
$ docker ps --filter name=^/codex-ex01-web-docs-20260730$
NAMES                          STATUS                   PORTS
codex-ex01-web-docs-20260730   Up 5 seconds (healthy)   127.0.0.1:38080->80/tcp

$ docker ps -a --filter name=^/codex-ex01-web-docs-20260730$
NAMES                          STATUS                   PORTS
codex-ex01-web-docs-20260730   Up 5 seconds (healthy)   127.0.0.1:38080->80/tcp
```

NGINX 로그에는 실제 루트 요청이 남았습니다.

```console
$ docker logs --tail 20 codex-ex01-web-docs-20260730
...
/docker-entrypoint.sh: Configuration complete; ready for start up
172.17.0.1 - - [30/Jul/2026:06:51:42 +0000] "GET / HTTP/1.1" 200 3719 "-" "curl/8.7.1" "-"

$ docker stats --no-stream codex-ex01-web-docs-20260730
NAME                           CPU %     MEM USAGE / LIMIT
codex-ex01-web-docs-20260730   0.00%     9.742MiB / 7.75GiB
```

중지한 컨테이너는 전체 목록에 남고, 다시 시작하면 같은 포트에서 응답합니다.

```console
$ docker stop --timeout 5 codex-ex01-web-docs-20260730
codex-ex01-web-docs-20260730
after-stop name=codex-ex01-web-docs-20260730 status=Exited (0) Less than a second ago

$ docker start codex-ex01-web-docs-20260730
codex-ex01-web-docs-20260730
health=healthy container=codex-ex01-web-docs-20260730
HTTP 200 body=ok url=http://127.0.0.1:38080/healthz
```

## 바인드 마운트 변경 전·후

호스트의 임시 디렉터리를 NGINX 문서 루트에 읽기 전용으로 연결했습니다. 개인 임시 경로는 `<temporary-directory>`로 가렸습니다.

```console
$ docker create \
    --name codex-ex01-bind-docs-20260730 \
    --publish 127.0.0.1:38081:80 \
    --mount type=bind,source=<temporary-directory>,target=/usr/share/nginx/html,readonly \
    codex-ex01-web:docs-20260730
6a3fff3bfe672c4a74504accbbf3a74023ff2bf488f6452d8d310fe3e14563be

health=healthy container=codex-ex01-bind-docs-20260730
HTTP 200 body=bind-before-docs-20260730 url=http://127.0.0.1:38081/

$ printf 'bind-after-docs-20260730\n' > <temporary-directory>/index.html
HTTP 200 body=bind-after-docs-20260730 url=http://127.0.0.1:38081/
```

이미지를 다시 빌드하지 않았지만 호스트 파일 변경이 다음 HTTP 요청에 반영됐습니다.

## 볼륨 영속성

```console
$ docker volume create codex-ex01-data-docs-20260730
codex-ex01-data-docs-20260730

$ docker create \
    --name codex-ex01-volume-one-docs-20260730 \
    --mount type=volume,source=codex-ex01-data-docs-20260730,target=/usr/share/nginx/html/data \
    codex-ex01-web:docs-20260730
d583f98a20e02b1c010d57d90d5acb75d15551c79f80ddecdf43368ee99ccb42

$ docker exec codex-ex01-volume-one-docs-20260730 sh -c "write and read persist.txt"
before-delete=volume-persists-docs-20260730

$ docker rm -f codex-ex01-volume-one-docs-20260730
codex-ex01-volume-one-docs-20260730

$ docker create \
    --name codex-ex01-volume-two-docs-20260730 \
    --mount type=volume,source=codex-ex01-data-docs-20260730,target=/usr/share/nginx/html/data \
    codex-ex01-web:docs-20260730
44f83d6d3c2d52dbc16c33799b62df099be5217740c878ca9631a62cf0b564f0

$ docker exec codex-ex01-volume-two-docs-20260730 \
    cat /usr/share/nginx/html/data/persist.txt
after-delete-and-recreate=volume-persists-docs-20260730
```

첫 번째 컨테이너를 실제로 삭제한 뒤 두 번째 컨테이너가 같은 값을 읽었습니다. 파일은 컨테이너 쓰기 레이어가 아니라 이름 있는 볼륨에 저장됐습니다.

## 최종 결과와 정리

```text
PASS: build, health, localhost port mapping, operations, stop/start, bind mount, and volume persistence

== Cleanup (script-created resources only) ==
cleanup complete
```

종료 후 `docs-20260730` 접미사가 붙은 컨테이너·볼륨·이미지가 남지 않은 것을 별도로 확인합니다. 기존 `workstation-web`, `workstation-backend`, 사용자 볼륨은 변경하지 않았습니다.

