# ex01 · 재현 가능한 Docker 개발 워크스테이션

`nginx:1.27.5-alpine`을 기반으로 정적 웹 서버 이미지를 만들고, 터미널·파일 권한·Docker 운영·포트 매핑·바인드 마운트·볼륨 영속성·Git/GitHub 연결을 **실제 명령과 결과로 검증한 과제**입니다.

과제 명세는 [`purpose.md`](purpose.md), 보완 전 감사 결과는 [`TODO.md`](TODO.md), 이전 README 원문은 [`README.previous.md`](README.previous.md)에 보존했습니다.

> 현재 상태: 필수 요구사항 19개 중 `PASS 17`, `PARTIAL 2`, `FAIL 0`입니다. 로컬 구현과 자동 검증은 완료했습니다. 제출 전 사용자가 VS Code의 GitHub 로그인 화면을 개인정보 없이 캡처하고, 최종 변경을 검토·커밋·푸시해야 합니다. 상세 판정은 [요구사항 추적표](docs/evidence/requirements.md)를 참고합니다.

## 1. 프로젝트 목표

이 프로젝트는 “컨테이너가 실행된다”는 설명에서 끝나지 않고 다음 사실을 재현 가능한 증거로 확인합니다.

- 터미널에서 파일과 디렉터리를 만들고 이동·복사·삭제할 수 있습니다.
- `r`, `w`, `x`와 `644`, `755` 같은 권한 표기를 설명하고 변경할 수 있습니다.
- Dockerfile에서 커스텀 이미지를 만들고 이미지와 컨테이너를 구분할 수 있습니다.
- 호스트 포트와 컨테이너 포트를 연결해야 브라우저에서 접속할 수 있음을 확인합니다.
- 바인드 마운트는 호스트 변경을 즉시 반영하고, 이름 있는 볼륨은 컨테이너 삭제 후에도 데이터를 유지함을 확인합니다.
- Git은 로컬 버전 관리 도구이고 GitHub은 원격 저장소·협업 플랫폼이라는 차이를 설명합니다.

## 2. 최종 판정과 체크리스트

| 영역 | 상태 | 검증 결과 |
|---|---:|---|
| 터미널 기본 조작 | ✅ | `pwd`, `ls -la`, `cd`, `mkdir`, `touch`, `cat`, `cp`, `mv`, `rm` 실행 |
| 파일·디렉터리 권한 | ✅ | 파일 `644 → 640`, 디렉터리 `755 → 750` 비교 |
| Docker 설치·Engine | ✅ | CLI와 Engine 29.4.1 응답 확인 |
| 이미지·컨테이너 운영 | ✅ | build/images/run/ps/ps-a/logs/stats/stop/start 실행 |
| 기본 컨테이너 | ✅ | `hello-world`, Ubuntu 전경·분리 실행과 `exec` 확인 |
| 커스텀 Dockerfile | ✅ | NGINX 설정·정적 화면·헬스체크를 포함한 이미지 빌드 |
| 포트 매핑 | ✅ | `127.0.0.1:38080 → 80`, HTTP 200과 브라우저 화면 확인 |
| 바인드 마운트 | ✅ | `bind-before → bind-after` 즉시 반영 |
| Docker 볼륨 | ✅ | 첫 컨테이너 삭제 후 두 번째 컨테이너에서 동일 데이터 확인 |
| Git 로컬 설정 | ✅ | 사용자 설정 존재, 기본 브랜치 `main` 확인 |
| GitHub 원격 연결 | ✅ | 공개 저장소와 SSH 읽기 연결 확인 |
| 민감정보 보호 | ✅ | 이메일 값 마스킹, 계정 없는 브라우저 프로필로 캡처 |
| VS Code GitHub 로그인 캡처 | ⬜ | 사용자가 개인정보를 가린 화면을 추가해야 함 |
| 최종 커밋·푸시 | ⬜ | 변경 파일 검토 후 `origin/main` 반영 필요 |

미완료 두 항목의 안전한 수행 순서는 [사용자 확인이 필요한 마지막 증거](docs/evidence/manual-evidence.md)에 정리했습니다.

## 3. 검증 환경

2026년 7월 30일에 아래 환경에서 직접 실행했습니다.

| 항목 | 확인 값 |
|---|---|
| OS | macOS 26.5.2, build 25F84 |
| Shell | zsh (`/bin/zsh`) |
| Terminal | iTerm2 (`iTerm.app`, `xterm-256color`) |
| Docker CLI / Engine | 29.4.1 / 29.4.1 |
| Docker Engine OS | Docker Desktop, Linux, arm64 |
| Docker Compose | v5.1.3 |
| Git | 2.50.1 (Apple Git-155) |
| Git 기본 브랜치 | `main` |
| 웹 베이스 이미지 | `nginx:1.27.5-alpine` |

전체 원문은 [환경 검증 로그](docs/evidence/environment.md)에 있습니다.

```console
$ docker --version
Docker version 29.4.1, build 055a478

$ docker info --format \
    'ServerVersion={{.ServerVersion}} Driver={{.Driver}} OperatingSystem={{.OperatingSystem}} OSType={{.OSType}} Architecture={{.Architecture}}'
ServerVersion=29.4.1 Driver=overlayfs OperatingSystem=Docker Desktop OSType=linux Architecture=aarch64

$ docker compose version
Docker Compose version v5.1.3

$ git --version
git version 2.50.1 (Apple Git-155)
```

## 4. 프로젝트 구조

```text
.
├── Dockerfile                    # NGINX 커스텀 이미지
├── compose.yaml                  # 선택 과제: 단일 web 서비스와 이름 있는 볼륨
├── nginx/default.conf            # 정적 라우팅, /healthz, 보안 헤더
├── site/
│   ├── index.html                # Docker Workstation Lab 화면
│   ├── styles.css                # 데스크톱·모바일 반응형 스타일
│   └── data/welcome.txt          # 볼륨 연결 대상의 초기 파일
├── scripts/
│   ├── terminal_permissions.sh   # CLI와 파일·디렉터리 권한 실습
│   └── verify.sh                 # Docker 전체 통합 검증과 자동 정리
├── tests/static_check.sh         # 파일·구문·Compose·문서 링크 정적 검사
├── docs/
│   ├── evidence/                 # 실제 명령, 출력, 요구사항 추적표
│   ├── images/                   # 주소창·데스크톱·모바일 검증 화면
│   ├── getting-started.md        # 빈 디렉터리부터 재구성하는 방법
│   ├── study-guide.md            # 핵심 개념 학습 자료
│   ├── troubleshooting.md        # 실제 문제 해결 기록 2건
│   └── peer-review.md            # 동료 평가 시연 가이드
├── purpose.md                    # 과제 명세
├── TODO.md                       # 보완 전 감사 기록
└── README.previous.md            # 기존 README 보존본
```

`backend/`, `study/todo.md`, `trouble.md` 등 기존 파일도 삭제하지 않고 유지했습니다. 현재 필수 실행 경로와 `compose.yaml`은 NGINX `web` 서비스 하나를 사용하며, `backend/`는 실행 경로에 포함하지 않습니다.

## 5. 커스텀 이미지 설계

| 구성 | 적용 내용 | 목적 |
|---|---|---|
| 베이스 | `nginx:1.27.5-alpine` | 검증된 웹 서버를 작은 Linux 이미지에서 사용 |
| 메타데이터 | OCI 라벨, `APP_ENV=learning` | 이미지 목적과 학습 환경 표시 |
| NGINX 설정 | `nginx/default.conf` 복사 | 정적 파일 fallback과 `/healthz` 제공 |
| 웹 콘텐츠 | `site/` 복사 | 기본 NGINX 화면을 프로젝트 화면으로 교체 |
| 데이터 경로 | `/usr/share/nginx/html/data` | 이름 있는 볼륨을 연결할 위치 제공 |
| 권한 | 정적 루트를 `nginx:nginx`로 설정 | NGINX 사용자의 파일 접근을 명시 |
| 포트 | `EXPOSE 80` | 이미지가 사용하는 컨테이너 포트 문서화 |
| 상태 점검 | `HEALTHCHECK`에서 `/healthz` 호출 | 프로세스 실행과 HTTP 준비 상태를 구분 |
| 보안 헤더 | `nosniff`, `SAMEORIGIN` | MIME 스니핑과 불필요한 iframe 삽입 완화 |

`EXPOSE 80`은 포트 사용 의도를 기록할 뿐입니다. 호스트에서 접속하려면 실행 시 `-p <host-port>:80`으로 포트를 실제 게시해야 합니다.

## 6. 빠른 실행

프로젝트 루트에서 실행합니다. 기존 서비스와 충돌을 피하려고 예시는 호스트 포트 `18080`을 사용합니다.

```bash
docker build -t ex01-workstation:1.0 .

docker run -d \
  --name ex01-workstation-local \
  -p 127.0.0.1:18080:80 \
  -v ex01-workstation-data:/usr/share/nginx/html/data \
  ex01-workstation:1.0
```

컨테이너가 `healthy`가 될 때까지 상태를 확인한 뒤 웹과 헬스체크를 호출합니다.

```bash
docker ps --filter name=ex01-workstation-local
curl -fsS http://127.0.0.1:18080/healthz
curl -fsS http://127.0.0.1:18080/ | grep -F 'Docker Workstation Lab'
```

예상 핵심 결과:

```text
STATUS: Up ... (healthy)
PORTS: 127.0.0.1:18080->80/tcp
ok
Docker Workstation Lab
```

브라우저에서 `http://127.0.0.1:18080`을 엽니다. 실습이 끝나면 이 예시가 만든 자원만 정리합니다.

```bash
docker rm -f ex01-workstation-local
docker volume rm ex01-workstation-data
docker image rm ex01-workstation:1.0
```

빈 디렉터리에서 파일 작성부터 다시 수행하려면 [재구성 가이드](docs/getting-started.md)를 사용합니다.

### Docker Compose

`compose.yaml`은 단일 `web` 서비스와 `workstation-data` 볼륨을 선언합니다. 기본 포트는 `8080`이며 `HOST_PORT`로 바꿀 수 있습니다.

```bash
HOST_PORT=18080 docker compose config
HOST_PORT=18080 docker compose up -d --build
HOST_PORT=18080 docker compose ps
HOST_PORT=18080 docker compose logs --tail 20 web
HOST_PORT=18080 docker compose down
```

같은 이름의 `workstation-web` 컨테이너가 이미 있다면 먼저 그 컨테이너의 용도를 확인합니다. 다른 사용자의 자원이나 필요한 데이터를 확인하지 않고 삭제하지 않습니다.

## 7. 자동 검증

### 정적 검사

필수 파일, 실행 권한, Bash·zsh 구문, Dockerfile·NGINX 패턴, Compose 해석, Python 구문, 모든 Markdown 링크를 검사합니다.

```bash
./tests/static_check.sh
```

최종 실행 결과:

```text
PASS: bash syntax
PASS: zsh syntax
PASS: docker compose config
PASS: backend/server.py AST parse
PASS: all local Markdown links and referenced scripts resolve
PASS: static verification completed (36 checks)
```

### 터미널·권한 검사

고유한 임시 디렉터리에서만 파일을 만들고 종료 시 삭제합니다.

```bash
./scripts/terminal_permissions.sh
```

실제 핵심 출력:

```text
$ chmod 644 permission-file.txt
-rw-r--r--  ... permission-file.txt
$ chmod 640 permission-file.txt
-rw-r-----  ... permission-file.txt

$ chmod 755 permission-dir
drwxr-xr-x  ... permission-dir
$ chmod 750 permission-dir
drwxr-x---  ... permission-dir

PASS: terminal operations and file/directory permission changes completed
cleanup: temporary terminal practice removed
```

### Docker 통합 검사

아래 스크립트는 포트와 자원 이름의 충돌을 먼저 검사합니다. 새 이미지 빌드, 포트·헬스체크, 운영 명령, 중지·재시작, 바인드 마운트, 볼륨 영속성을 확인한 뒤 **자신이 만든 자원만** 자동 정리합니다.

```bash
VERIFY_RUN_ID=local \
HOST_PORT=38080 \
BIND_PORT=38081 \
./scripts/verify.sh
```

2026년 7월 30일의 실제 핵심 결과:

```text
health=healthy container=codex-ex01-web-docs-20260730
HTTP 200 body=ok url=http://127.0.0.1:38080/healthz
HTTP 200 root page contains: Docker Workstation Lab
after-stop name=codex-ex01-web-docs-20260730 status=Exited (0) ...
HTTP 200 body=bind-before-docs-20260730 url=http://127.0.0.1:38081/
HTTP 200 body=bind-after-docs-20260730 url=http://127.0.0.1:38081/
before-delete=volume-persists-docs-20260730
after-delete-and-recreate=volume-persists-docs-20260730
PASS: build, health, localhost port mapping, operations, stop/start, bind mount, and volume persistence
cleanup complete
```

전체 명령과 출력은 [Docker 통합 검증 로그](docs/evidence/docker-verification.md)에 있습니다.

## 8. 실행 증거

### 주소창을 포함한 포트 매핑

호스트의 `127.0.0.1:38082`를 컨테이너의 `80` 포트에 매핑해 최종 화면을 확인했습니다.

![127.0.0.1:38082 주소창과 Docker Workstation Lab 화면](docs/images/browser-address-bar.png)

```console
$ docker inspect --format \
    'status={{.State.Status}} health={{.State.Health.Status}} ports={{json .NetworkSettings.Ports}}' \
    codex-ex01-browser-20260730
status=running health=healthy ports={"80/tcp":[{"HostIp":"127.0.0.1","HostPort":"38082"}]}

$ curl -fsS http://127.0.0.1:38082/healthz
ok
```

[데스크톱 화면](docs/images/web-desktop.png)과 [390px 모바일 화면](docs/images/web-mobile.png)에서도 페이지 가로 넘침이나 긴 명령 잘림이 없는지 확인했습니다. 자세한 측정값은 [UI 검증 기록](docs/evidence/ui-verification.md)에 있습니다.

### 터미널과 권한

[`scripts/terminal_permissions.sh`](scripts/terminal_permissions.sh)를 실행해 기본 조작과 권한 변경 전·후를 확인했습니다. 명령·출력 원문은 [터미널·권한 로그](docs/evidence/terminal-permissions.md)에 있습니다.

### `hello-world`, Ubuntu와 실행 방식

```console
$ docker run --rm hello-world
Hello from Docker!
This message shows that your installation appears to be working correctly.

$ docker run --rm ubuntu:24.04 \
    sh -lc 'echo foreground-ok; pwd; ls -1 / | head -n 5'
foreground-ok
/
bin
boot
dev
etc
home
```

전경 `docker run`은 현재 터미널을 컨테이너의 주 프로세스에 연결합니다. `-d`는 주 프로세스를 백그라운드에서 유지하고, `docker exec`는 실행 중인 컨테이너 안에 **새 명령**을 실행합니다. `docker attach`는 새 명령을 만드는 대신 기존 주 프로세스의 입출력에 연결합니다. 전체 로그는 [기본 컨테이너 검증](docs/evidence/container-basics.md)에 있습니다.

### 바인드 마운트와 볼륨

```text
bind mount:
  호스트 파일 변경 전  -> bind-before-docs-20260730
  호스트 파일 변경 후  -> bind-after-docs-20260730

named volume:
  첫 컨테이너 삭제 전  -> volume-persists-docs-20260730
  새 컨테이너 생성 후  -> volume-persists-docs-20260730
```

바인드 마운트는 지정한 호스트 경로를 컨테이너에 직접 연결하므로 소스 변경 확인에 적합합니다. Docker 볼륨은 Docker가 관리하며 컨테이너의 생명주기와 분리되므로 영속 데이터에 적합합니다.

## 9. 증거 문서 색인

| 확인 대상 | 상세 기록 |
|---|---|
| 필수 19개 최종 판정 | [요구사항 추적표](docs/evidence/requirements.md) |
| OS·터미널·Docker·Git 버전 | [실행 환경](docs/evidence/environment.md) |
| CLI와 파일·디렉터리 권한 | [터미널·권한](docs/evidence/terminal-permissions.md) |
| `hello-world`, Ubuntu, 전경·분리 실행 | [기본 컨테이너](docs/evidence/container-basics.md) |
| 빌드·포트·로그·stats·바인드·볼륨 | [Docker 통합 검증](docs/evidence/docker-verification.md) |
| 주소창·데스크톱·모바일 화면 | [웹 UI 검증](docs/evidence/ui-verification.md) |
| Git 설정과 공개 GitHub 원격 | [Git·GitHub](docs/evidence/git-github.md) |
| 사용자만 완료할 수 있는 증거 | [VS Code 캡처와 최종 푸시](docs/evidence/manual-evidence.md) |

## 10. 트러블슈팅

실제 관찰한 두 사례를 [트러블슈팅 기록](docs/troubleshooting.md)에 문제 → 원인 가설 → 확인 → 해결 → 재검증 순서로 남겼습니다.

1. `docker ps`에는 보이지 않는 중지 컨테이너가 이미지를 참조해 이미지 삭제가 실패했습니다. `docker ps -a`로 대상을 확인하고 해당 컨테이너만 삭제한 뒤 해결했습니다.
2. 컨테이너 ID가 반환된 직후 `curl`이 종료 코드 52를 반환했습니다. 프로세스 시작과 서비스 준비 완료가 다름을 확인하고 `/healthz`에 제한 시간이 있는 재시도를 적용했습니다.

## 11. 보안과 재현성

- 포트는 과제 검증에 필요한 로컬 인터페이스 `127.0.0.1`에만 게시했습니다.
- Git 이메일은 값 대신 설정 여부만 기록했습니다.
- 브라우저 화면은 계정 정보가 없는 별도 프로필에서 캡처했습니다.
- 토큰, 비밀번호, 개인키, 인증 코드는 문서와 이미지에 넣지 않습니다.
- 검증 스크립트는 실행 전 포트·이름 충돌을 검사하고, 자신이 만든 자원만 정리합니다.
- 개인 절대 경로는 로그에서 `<project-root>`, `<temporary-directory>`처럼 일반화했습니다.
- 사용자 계정이 필요한 VS Code 로그인과 외부 상태를 바꾸는 최종 푸시는 자동으로 수행하지 않았습니다.

## 12. 학습·평가 자료

- [빈 디렉터리에서 재구성하기](docs/getting-started.md)
- [핵심 개념 학습 가이드](docs/study-guide.md)
- [평가 대비 학습 계획](docs/evaluation-study-plan.md)
- [동료 평가 시연 가이드](docs/peer-review.md)
- [문제 해결 기록](docs/troubleshooting.md)

공개 원격 저장소는 [Minkyu01/codyssey_01](https://github.com/Minkyu01/codyssey_01)입니다. 새 README와 증거 문서는 사용자가 최종 검토 후 `origin/main`에 푸시해야 원격에서도 보입니다.
