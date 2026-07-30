# Docker 기본 컨테이너 검증

2026년 7월 30일에 `hello-world`와 `ubuntu:24.04`를 실행했습니다. `codex-ex01-*-doc-20260730` 이름만 사용했고 종료 후 모두 삭제했습니다.

## hello-world

```console
$ docker run --rm hello-world

Hello from Docker!
This message shows that your installation appears to be working correctly.
```

클라이언트가 Docker Engine에 요청하고, Engine이 이미지를 사용해 컨테이너를 만들고 출력을 돌려주는 기본 흐름이 성공했습니다.

## Ubuntu 전경 실행

```console
$ docker run --rm \
    --name codex-ex01-ubuntu-attached-doc-20260730 \
    ubuntu:24.04 \
    sh -lc 'echo foreground-ok; pwd; ls -1 / | head -n 5'
foreground-ok
/
bin
boot
dev
etc
home
```

이 명령은 컨테이너의 주 프로세스를 현재 터미널에 연결합니다. 명령이 끝나면 컨테이너도 종료되며 `--rm`이 컨테이너를 삭제합니다.

## Ubuntu 분리 실행과 exec

```console
$ docker run -d \
    --name codex-ex01-ubuntu-exec-doc-20260730 \
    ubuntu:24.04 sleep infinity
6311e35b905284adaec54fab94be3020541595ba05ab1fee71c7cff2d47bccfa

$ docker exec codex-ex01-ubuntu-exec-doc-20260730 \
    sh -lc 'echo exec-ok; pwd; ls -1 / | head -n 5'
exec-ok
/
bin
boot
dev
etc
home

$ docker ps \
    --filter name=codex-ex01-ubuntu-exec-doc-20260730 \
    --format 'name={{.Names}} status={{.Status}}'
name=codex-ex01-ubuntu-exec-doc-20260730 status=Up Less than a second
```

`-d`는 주 프로세스를 백그라운드에서 유지합니다. `docker exec`는 실행 중인 컨테이너에 별도의 새 명령을 추가합니다. `docker attach`는 기존 주 프로세스의 입출력에 연결한다는 점이 다릅니다.

## 중지·전체 목록·삭제

```console
$ docker stop --timeout 3 codex-ex01-ubuntu-exec-doc-20260730
codex-ex01-ubuntu-exec-doc-20260730

$ docker ps -a \
    --filter name=codex-ex01-ubuntu-exec-doc-20260730 \
    --format 'name={{.Names}} status={{.Status}}'
name=codex-ex01-ubuntu-exec-doc-20260730 status=Exited (137) Less than a second ago

$ docker rm codex-ex01-ubuntu-exec-doc-20260730
codex-ex01-ubuntu-exec-doc-20260730
```

`sleep infinity`는 종료 신호를 처리하지 않아 제한 시간이 지난 뒤 강제 종료되어 상태 코드 `137`이 기록됐습니다. `docker ps`에는 실행 중인 컨테이너만 나타나지만 `docker ps -a`에는 중지된 컨테이너도 나타납니다.
