# ex01 과제 보완 TODO

`purpose.md`와 현재 저장소를 대조한 감사 결과입니다. 2026년 7월 30일에 정적 검사와 격리된 실행 검증을 진행했습니다.

현재 구현은 핵심 Docker 실행 경로가 동작하지만, 제출물에 필요한 로그·이미지·재현 증거가 부족합니다. 따라서 `README.md` 작성 게이트를 통과하지 못했습니다. 기존 `README.md`는 이번 감사에서 수정하지 않았습니다.

## 감사 결과

필수 요구사항 19개를 기준으로 판정했습니다.

```text
PASS: 1
PARTIAL: 10
FAIL: 8
BLOCKED: 0
```

- `PASS`: 산출물과 검증 증거가 모두 있습니다.
- `PARTIAL`: 일부 산출물이나 설명은 있지만 검증 조건을 모두 증명하지 못했습니다.
- `FAIL`: 필수 산출물 또는 실행 증거가 없습니다.
- `BLOCKED`: 계정, 권한, 장비처럼 현재 환경 밖의 조건 때문에 판정할 수 없습니다.

이 집계는 `TODO.md`를 만들기 전의 제출 산출물을 기준으로 합니다. 아래 실행 결과는 코드의 동작 여부를 감사하기 위해 수집한 임시 증거입니다. 최종 제출 문서에는 재현 가능한 명령, 필요한 전체 출력, 이미지 경로를 다시 정리해야 합니다.

## 직접 확인한 실행 결과

### 실행 환경

```console
$ sw_vers
ProductName:        macOS
ProductVersion:     26.5.2
BuildVersion:       25F84

$ printf '%s\n' "$SHELL"
/bin/zsh

$ docker --version
Docker version 29.4.1, build 055a478

$ docker info --format 'Server={{.ServerVersion}} Driver={{.Driver}} OS={{.OperatingSystem}}'
Server=29.4.1 Driver=overlayfs OS=Docker Desktop

$ docker compose version
Docker Compose version v5.1.3

$ git --version
git version 2.50.1 (Apple Git-155)
```

`docker compose config`도 성공했습니다. 현재 구성은 `web` 단일 서비스, `8080:80` 포트 매핑, `workstation-data` 이름 있는 볼륨을 정의합니다.

### 터미널과 권한

`/private/tmp/codex-ex01-cli-audit-20260730`에서 임시 파일만 사용했습니다. 확인 후 임시 디렉터리를 삭제했습니다.

```console
$ pwd
/Users/myu/Documents/codyssey/ex/01

$ cd /private/tmp/codex-ex01-cli-audit-20260730
$ pwd
/private/tmp/codex-ex01-cli-audit-20260730

$ touch practice/empty.txt practice/original.txt
$ printf '%s\n' 'terminal-audit-content' > practice/original.txt
$ cat practice/original.txt
terminal-audit-content

$ cp practice/original.txt practice/copy.txt
$ mv practice/copy.txt practice/moved.txt
$ rm practice/moved.txt

$ stat -f '%Sp %N' practice/original.txt
-rw-r--r-- practice/original.txt
$ chmod 640 practice/original.txt
$ stat -f '%Sp %N' practice/original.txt
-rw-r----- practice/original.txt

$ stat -f '%Sp %N' practice
drwxr-xr-x practice
$ chmod 750 practice
$ stat -f '%Sp %N' practice
drwxr-x--- practice

$ wc -c practice/empty.txt
       0 practice/empty.txt
```

### Docker 기본 실행

감사용 컨테이너·이미지·볼륨에는 `codex-ex01-*` 이름을 사용했습니다.

```console
$ docker run --rm --name codex-ex01-hello-20260730 hello-world
Hello from Docker!
This message shows that your installation appears to be working correctly.

$ docker run --rm --name codex-ex01-ubuntu-attached-20260730 \
    ubuntu:24.04 sh -lc 'echo attached-run-ok; pwd; ls -1 / | head -n 5'
attached-run-ok
/
bin
boot
dev
etc
home

$ docker run -d --name codex-ex01-ubuntu-exec-20260730 \
    ubuntu:24.04 sleep infinity
$ docker exec codex-ex01-ubuntu-exec-20260730 \
    sh -lc 'echo exec-ok; pwd; ls -1 / | head -n 5'
exec-ok
/
bin
boot
dev
etc
home
```

전경의 `docker run`은 주 프로세스의 입출력과 터미널을 바로 연결했습니다. `-d`로 시작한 컨테이너는 백그라운드에서 계속 실행됐고, `docker exec`는 실행 중인 컨테이너에 새 명령을 추가했습니다.

### 커스텀 이미지와 포트 매핑

```console
$ docker build --progress=plain -t codex-ex01-web:20260730 .
...
#9 naming to docker.io/library/codex-ex01-web:20260730 done
#9 DONE 0.1s

$ docker run -d --name codex-ex01-web-20260730 \
    -p 127.0.0.1:28080:80 codex-ex01-web:20260730

$ curl -fsS http://127.0.0.1:28080/healthz
ok

$ docker inspect --format \
    'health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} ports={{json .NetworkSettings.Ports}}' \
    codex-ex01-web-20260730
health=starting ports={"80/tcp":[{"HostIp":"127.0.0.1","HostPort":"28080"}]}
```

컨테이너를 시작한 직후라 Docker의 헬스 상태는 `starting`이었지만, 같은 시점의 실제 HTTP 요청은 `ok`를 반환했습니다. 최종 증거를 수집할 때는 헬스 상태가 `healthy`로 바뀔 때까지 기다린 뒤 함께 기록해야 합니다.

`docker images`, `docker ps -a`, `docker logs`, `docker stats --no-stream`, `docker stop`, `docker start`도 직접 실행했습니다. NGINX 로그에서 설정 로드와 워커 시작을 확인했고, 중지한 컨테이너는 `Exited (0)`으로 표시됐습니다. 다시 시작한 뒤 `/healthz`는 `ok`를 반환했습니다.

### 바인드 마운트

임시 호스트 디렉터리를 NGINX 문서 루트에 읽기 전용으로 연결했습니다.

```console
$ curl -fsS http://127.0.0.1:28081/
bind-before

$ mv /private/tmp/codex-ex01-bind-audit-20260730/after.html \
    /private/tmp/codex-ex01-bind-audit-20260730/index.html

$ curl -fsS http://127.0.0.1:28081/
bind-after
```

호스트 파일을 바꾸자 새 이미지를 빌드하지 않아도 컨테이너 응답이 바뀌었습니다.

### Docker 볼륨 영속성

```console
$ docker volume create codex-ex01-data-20260730
codex-ex01-data-20260730

$ docker run -d --name codex-ex01-vol1-20260730 \
    -v codex-ex01-data-20260730:/data ubuntu:24.04 sleep infinity
$ docker exec codex-ex01-vol1-20260730 \
    sh -lc 'echo persisted-from-first-container > /data/proof.txt; cat /data/proof.txt'
persisted-from-first-container

$ docker rm -f codex-ex01-vol1-20260730
codex-ex01-vol1-20260730

$ docker run -d --name codex-ex01-vol2-20260730 \
    -v codex-ex01-data-20260730:/data ubuntu:24.04 sleep infinity
$ docker exec codex-ex01-vol2-20260730 cat /data/proof.txt
persisted-from-first-container
```

첫 번째 컨테이너를 삭제한 뒤 새 컨테이너에서 같은 파일을 읽었습니다. 이름 있는 볼륨에 데이터가 남는 것을 확인했습니다.

### 임시 자원 정리

검증에 사용한 `codex-ex01-*` 컨테이너, `codex-ex01-web:20260730` 이미지, `codex-ex01-data-20260730` 볼륨, `/private/tmp`의 테스트 파일을 검증 종료 시 삭제했습니다. `hello-world`와 `ubuntu:24.04` 베이스 이미지는 기존 사용자 자원일 수 있으므로 삭제하지 않았습니다.

## 요구사항 추적표

| ID | 필수 요구사항 | 상태 | 현재 증거 | 완료하려면 필요한 작업 |
|---|---|---|---|---|
| R1 | GitHub 저장소 링크로 전체 산출물 확인 | PARTIAL | `origin`은 공개 저장소 `Minkyu01/codyssey_01`이며 기본 브랜치는 `main`입니다. 로컬에는 수정·삭제·미추적 파일이 있습니다. | 최종 산출물을 커밋·푸시한 뒤 GitHub에서 파일과 링크를 다시 확인합니다. |
| R2 | README의 개요·환경·체크리스트 | PARTIAL | `README.md:1-43`에 기본 구조가 있습니다. 환경 출력 블록은 비어 있고 완료 표시는 실제 증거보다 앞서 있습니다. | 실제 환경 로그를 넣고, 증거가 있는 항목만 `[x]`로 표시합니다. 터미널 애플리케이션도 기록합니다. |
| R3 | 검증 방법·결과 위치·재현성 | FAIL | `README.md:305-332`는 존재하지 않는 `tests/static_check.sh`와 `scripts/verify.sh`를 안내합니다. | 존재하지 않는 명령을 제거하거나 실제 검증 스크립트를 마련합니다. 모든 명령에는 실제 결과 또는 증거 링크를 붙입니다. |
| R4 | 트러블슈팅 2건 이상 | PARTIAL | `trouble.md:1-16`에 이미지 삭제 충돌 사례 1건이 있습니다. | 실제 사례 2건 이상을 `문제 → 원인 가설 → 확인 → 해결/대안` 순서로 다시 작성하고 README에서 링크합니다. |
| R5 | 터미널 기본 조작 로그 | PARTIAL | `README.md:68-132`에 일부 명령이 있습니다. `pwd` 결과와 `ls` 대상이 서로 맞지 않고 `cd` 로그가 없습니다. | 한 임시 디렉터리에서 `pwd`, `ls -la`, `cd`, `mkdir`, `touch`, 내용 확인, `cp`, `mv`, `rm`을 연속 실행하고 명령과 출력을 함께 기록합니다. |
| R6 | 파일·디렉터리 권한 전후 비교 | PARTIAL | `README.md:135-225`에는 파일 예시만 있고 사용자·그룹·파일 크기가 서로 다른 로그가 섞여 있습니다. | 파일 1개와 디렉터리 1개를 같은 세션에서 변경하고, 각 대상의 변경 전·후 `ls -ld` 또는 `stat` 결과를 기록합니다. |
| R7 | Docker 버전·데몬 점검 로그 | FAIL | 기존 README의 실행 결과 블록이 비어 있습니다. | `docker --version`과 민감정보를 제외한 `docker info` 핵심 출력을 최종 증거에 넣습니다. |
| R8 | 이미지·컨테이너·로그·리소스 운영 명령 | FAIL | 일부 `docker ps`와 `docker rmi` 기록 외에 일관된 운영 로그가 없습니다. | `pull` 또는 `run`, `images`, `ps`, `ps -a`, `stop`, `start`, `logs`, `stats --no-stream`을 같은 테스트 이름으로 실행해 기록합니다. |
| R9 | `hello-world` 성공 | FAIL | `README.md:35`의 체크와 `trouble.md:18-20`의 메모만 있습니다. | 실제 `Hello from Docker!` 출력이 포함된 명령 블록을 최종 증거에 넣습니다. |
| R10 | Ubuntu 내부 명령과 attach/exec 차이 | FAIL | 실행 결과가 없습니다. | 전경 실행과 분리 실행을 각각 기록하고, `exec`로 `pwd`, `ls`, `echo`를 실행합니다. 컨테이너 종료·유지 차이를 관찰해 설명합니다. |
| R11 | 직접 작성한 커스텀 이미지 | PASS | `Dockerfile`은 `nginx:1.27.5-alpine`을 기반으로 설정·사이트 복사, 포트, 헬스체크, 실행 명령을 정의합니다. | 추가 작업이 없습니다. |
| R12 | 커스텀 이미지 빌드·실행 성공 증거 | FAIL | `README.md:249-264`에는 명령만 있고 출력이 없습니다. | 최종 태그로 다시 빌드하고 빌드 완료, 컨테이너 ID, 실행 상태를 기록합니다. |
| R13 | 포트 매핑과 접속 증거 | PARTIAL | `compose.yaml:7-8`에 포트 설정이 있고 감사 중 `curl` 성공을 확인했습니다. 저장소에는 주소창을 포함한 이미지가 없습니다. | 실제 `curl` 출력과 `docker ps`의 포트 열을 기록합니다. 주소창과 응답 화면이 함께 보이는 브라우저 캡처를 추가합니다. |
| R14 | 바인드 마운트 변경 전·후 | FAIL | 기존 README의 해당 절은 비어 있고 Compose에는 이름 있는 볼륨만 있습니다. | 호스트 변경 전 응답, 호스트 파일 변경 명령, 변경 후 응답을 한 흐름으로 기록합니다. |
| R15 | 컨테이너 삭제 전·후 볼륨 영속성 | PARTIAL | `compose.yaml:9-14`에 볼륨은 정의돼 있고 감사 실행도 성공했습니다. 제출 문서에는 삭제 전·후 로그가 없습니다. | 첫 컨테이너 쓰기·확인, 첫 컨테이너 삭제, 두 번째 컨테이너 재연결·확인 순서를 최종 증거에 넣습니다. |
| R16 | Git 사용자·기본 브랜치 설정 기록 | PARTIAL | 로컬에서 `user.name`과 `init.defaultBranch=main` 설정을 확인했습니다. | `git config --list` 또는 필요한 키만 출력하고 이메일·자격 증명 경로 등 개인 정보를 마스킹합니다. |
| R17 | GitHub·VS Code 연동 증거 | FAIL | `README.md:42-43`은 완료로 표시하지만 이미지 파일이 없습니다. | 사용자가 VS Code의 GitHub 로그인과 현재 저장소 연동 화면을 캡처합니다. 토큰, 이메일, 알림, 인증 코드는 가립니다. |
| R18 | 보안·개인정보 보호 | PARTIAL | 토큰·비밀번호·개인키 패턴은 발견되지 않았습니다. 로컬 절대 경로와 호스트 프롬프트는 남아 있습니다. | 제출 로그에서 사용자명·호스트명·개인 절대 경로를 일반화하고 모든 이미지를 확대 확인합니다. |
| R19 | 과제 학습 목표 설명 | PARTIAL | `study/todo.md`에 경로, 권한, Docker 이미지·컨테이너·포트·스토리지 설명이 있습니다. | Git과 GitHub의 역할 차이를 실제 로컬·원격 흐름에 연결해 설명합니다. |

## 우선순위별 작업

### P0. 문서의 잘못된 완료 표시 정리

- [ ] `README.md:32-43`의 체크리스트를 실제 증거와 다시 연결합니다.
- [ ] 비어 있는 환경, Docker, Compose, 포트, 마운트, 볼륨, 트러블슈팅 절을 실제 결과로 채웁니다.
- [ ] 존재하지 않는 `tests/static_check.sh`와 `scripts/verify.sh` 안내를 제거하거나 실제 파일을 만든 뒤 검증합니다.
- [ ] `README.md:273-277`의 예상 출력과 실제 실행 출력을 명확히 구분합니다.
- [ ] README의 모든 명령을 프로젝트 루트에서 다시 실행합니다.

### P0. 터미널·권한 증거 재수집

- [ ] 하나의 임시 디렉터리에서 기본 조작을 연속 실행합니다.
- [ ] 명령 프롬프트 또는 명령 자체와 출력 결과를 같은 코드 블록에 둡니다.
- [ ] 파일 권한과 디렉터리 권한을 각각 변경 전·후로 비교합니다.
- [ ] 실습 후 임시 파일을 정리하고 정리 명령도 기록합니다.

완료 조건:

```text
pwd, ls -la, cd, mkdir, touch, cat, cp, mv, rm가 모두 보인다.
파일 1개와 디렉터리 1개의 권한이 전·후 값으로 비교된다.
서로 다른 사용자명·그룹·파일 크기의 예시가 한 로그처럼 섞이지 않는다.
```

### P0. Docker 기본 운영 증거 수집

- [ ] `docker --version`과 `docker info`를 기록합니다.
- [ ] `hello-world`의 성공 메시지를 기록합니다.
- [ ] Ubuntu 전경 실행과 분리 실행을 비교합니다.
- [ ] `docker exec`로 컨테이너 내부의 `pwd`, `ls`, `echo`를 실행합니다.
- [ ] `docker images`, `docker ps`, `docker ps -a`, `docker logs`, `docker stats --no-stream`을 기록합니다.
- [ ] 컨테이너 중지·재시작·삭제 결과를 기록합니다.

### P0. 이미지·포트·스토리지 증거 수집

- [ ] 최종 이미지 태그를 정하고 `docker build` 전체 흐름을 기록합니다.
- [ ] `docker run -p <host_port>:80`의 컨테이너 ID와 `docker ps` 포트 열을 기록합니다.
- [ ] `/`와 `/healthz`의 실제 응답을 기록합니다.
- [ ] 주소창의 포트와 웹 화면이 함께 보이도록 브라우저를 캡처합니다.
- [ ] 바인드 마운트의 변경 전 응답과 변경 후 응답을 비교합니다.
- [ ] 이름 있는 볼륨에 파일을 쓴 첫 컨테이너를 실제로 삭제합니다.
- [ ] 새 컨테이너에서 같은 볼륨을 연결해 파일 내용을 다시 확인합니다.
- [ ] 테스트 컨테이너와 볼륨의 정리 여부를 마지막에 확인합니다.

### P0. Git·GitHub·VS Code 증거 보완

- [ ] Git 설정은 필요한 키만 출력하거나 개인 정보를 마스킹합니다.
- [ ] 공개 저장소의 기본 브랜치와 실제 최종 커밋을 확인합니다.
- [ ] VS Code의 GitHub 로그인과 현재 저장소 연동 상태를 사용자가 직접 캡처합니다.
- [ ] 캡처에 토큰, 이메일, 인증 코드, 개인 알림이 없는지 확인합니다.
- [ ] 로컬 변경을 정리한 뒤 커밋·푸시하고 GitHub 파일 트리를 다시 확인합니다.

현재 Git 상태에는 다음 변경이 있습니다. 기존 사용자 변경이므로 자동으로 되돌리면 안 됩니다.

```text
M  README.md
M  compose.yaml
D  test
?? purpose.md
?? site/data/
?? TODO.md
```

### P0. 트러블슈팅 2건 작성

- [ ] `trouble.md:1-16`의 이미지 삭제 충돌 사례를 정해진 형식으로 다시 씁니다.
- [ ] 실제로 관찰한 두 번째 사례를 추가합니다.
- [ ] 각 사례에 실행 환경, 오류 원문, 확인 명령, 해결 결과를 넣습니다.
- [ ] README에서 `trouble.md`의 각 사례로 이동할 수 있게 링크합니다.

사용할 수 있는 실제 사례 후보:

1. 중지된 컨테이너가 이미지를 참조해 `docker rmi`가 실패한 사례
2. NGINX 시작 직후 첫 `curl`에서 빈 응답이 발생해 준비 상태 확인과 재시도가 필요했던 사례

### P1. 파일과 설명의 일관성 정리

- [ ] `backend/`를 Compose에서 사용할지, 보너스 범위 밖의 미사용 예제로 둘지 결정합니다.
- [ ] 현재 Compose에는 `backend` 서비스가 없으므로 `trouble.md:40`의 `http://backend:8000/` 명령을 그대로 두지 않습니다.
- [ ] `site/index.html:27-33`의 고정 `8080` 설명과 `HOST_PORT` 변경 기능이 모순되지 않도록 정리합니다.
- [ ] 프로젝트 구조 표가 실제 파일 트리와 일치하는지 다시 생성합니다.
- [ ] `study/todo.md`에 Git과 GitHub의 역할 차이를 보완합니다.

## 예시 저장소 활용 기준

[whitecy01/codyssey1](https://github.com/whitecy01/codyssey1)은 섹션 구성과 이미지 배치만 참고합니다.

참고할 점:

- 요구사항 순서대로 README 절을 구성합니다.
- 명령과 출력을 같은 코드 블록에 둡니다.
- 브라우저 주소창과 응답 화면을 한 이미지에 담습니다.
- 볼륨 검증은 첫 컨테이너 생성부터 두 번째 컨테이너의 데이터 확인까지 시간순으로 보여 줍니다.

복사하면 안 되는 점:

- 예시 저장소의 사용자명, 이메일, 경로, 이미지 ID, 컨테이너 ID를 가져오지 않습니다.
- 예시에도 `unhealthy` 상태와 성공 설명의 불일치, 바인드 마운트 전·후 비교 누락, 오래된 Git 증거가 있습니다.
- 예시의 체크 표시를 과제 충족 근거로 사용하지 않습니다. 현재 프로젝트에서 직접 실행한 결과만 기록합니다.

## README 작성 재개 조건

다음 조건을 모두 만족한 뒤에만 `README.md`를 최종 작성합니다.

- [ ] R1~R19가 모두 `PASS`입니다.
- [ ] 체크리스트의 모든 완료 표시에 실제 명령, 출력 또는 이미지가 연결됩니다.
- [ ] 문서의 명령과 현재 파일명·포트·서비스명이 일치합니다.
- [ ] 주소창을 포함한 브라우저 캡처와 VS Code/GitHub 연동 증거가 있습니다.
- [ ] 트러블슈팅이 실제 사례 2건 이상입니다.
- [ ] 내부 링크와 이미지 경로가 모두 열립니다.
- [ ] 민감정보 검사와 육안 검토를 통과합니다.
- [ ] 임시 컨테이너·네트워크·볼륨·프로세스가 남아 있지 않습니다.
- [ ] 최종 변경을 커밋·푸시한 뒤 공개 GitHub 저장소에서 다시 확인합니다.

