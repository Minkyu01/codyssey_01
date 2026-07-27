# AI/SW 개발 워크스테이션 구축

NGINX 정적 웹 서버를 커스텀 Docker 이미지로 빌드하고, 포트 매핑·바인드 마운트·Docker 볼륨을 검증하는 프로젝트입니다. `scripts/verify.sh`를 실행하면 명세의 핵심 Docker 요구사항을 자동으로 재현할 수 있습니다.

## 프로젝트 개요
이 프로젝트의 목적은 docker, git, terminal에 대한 이해와 개발 환경 구축이다.

- 터미널로 cli사용과 파일과 폴더의 권한들을 설정하기
- git, github란 무엇인지 이해하고 설정하기
- Docker에 대해 이애하고 Dockerfile로 재현 가능한 웹 서버 이미지를 만들기
- Docker 사용시 포트, 마운트, 볼륨에 대해 이해하고 적용하기

- GitHub 저장소: [Minkyu01/codeseey_p](https://github.com/Minkyu01/codeseey_p)
- 제출 경로: `study/piscine/00` — 현재 변경을 커밋하고 푸시한 뒤 GitHub에서 경로를 확인해야 합니다.

## 실행 환경

| 항목 | 검증 환경 |
|---|---|
| OS | macOS 26.5.2 |
| Shell | zsh (`/bin/zsh`) |
| Docker CLI / Engine | 29.4.1 / 29.4.1 |
| Docker Desktop | 동작 확인 |
| Git | 2.50.1 |
| 컨테이너 베이스 | `nginx:1.27.5-alpine` |
| 컨테이너 포트 | `80` |
| 기본 호스트 포트 | `8080` |


## 수행 체크리스트

- [x] 터미널 기본 조작과 파일 생성·복사·이동·삭제
- [x] 파일과 디렉터리 권한 변경
- [x] Docker CLI와 데몬 점검
- [x] `hello-world` 및 Ubuntu 컨테이너 실습
- [x] NGINX 기반 커스텀 이미지 작성
- [x] 이미지 빌드와 컨테이너 실행
- [x] 포트 매핑 및 HTTP 응답 확인
- [x] 바인드 마운트 변경 전후 비교
- [x] Docker 볼륨의 데이터 영속성 검증
- [x] 컨테이너 로그와 리소스 확인 자동화
- [x] Git 원격 저장소와 기본 브랜치 확인
- [ ] VS Code의 GitHub 로그인 화면 캡처 후 저장소에 추가

마지막 항목은 개인 계정이 표시되는 화면이므로 제출자가 직접 캡처해야 합니다. 토큰, 이메일, 인증 코드는 마스킹해야 합니다.

## 프로젝트 구조

```text
00/
├── Dockerfile                 # 커스텀 NGINX 이미지 정의
├── compose.yaml               # 단일 서비스와 이름 있는 볼륨 정의
├── nginx/default.conf         # 웹 경로와 /healthz 설정
├── site/
│   ├── index.html             # 컨테이너가 제공하는 웹 화면
│   ├── styles.css             # 반응형 화면 스타일
│   └── data/welcome.txt       # 볼륨 마운트 지점의 초기 파일
├── scripts/verify.sh          # 빌드·포트·마운트·볼륨 자동 검증
├── tests/static_check.sh      # 필수 파일과 설정 정적 검사
```

## 빠른 실행

프로젝트 디렉터리에서 이미지를 빌드합니다.

```bash
docker build -t workstation-web:1.0 .
```

호스트의 `8080` 포트를 컨테이너의 `80` 포트에 연결합니다.

```bash
docker run -d \
  --name workstation-web \
  -p 8080:80 \
  workstation-web:1.0
```

웹 페이지와 헬스체크를 확인합니다.

```bash
curl http://localhost:8080/
curl http://localhost:8080/healthz
```

두 번째 명령의 예상 결과는 다음과 같습니다.

```text
ok
```

실습을 마치면 컨테이너를 삭제합니다.

```bash
docker rm -f workstation-web
```

## Docker Compose 실행

`compose.yaml`은 웹 서비스, 포트 매핑, 이름 있는 볼륨을 하나의 설정으로 묶습니다.

```bash
docker compose up -d --build
docker compose ps
docker compose logs web
curl http://localhost:8080/healthz
docker compose down
```

호스트 포트를 바꾸려면 환경 변수를 사용합니다.

```bash
HOST_PORT=8081 docker compose up -d
```

`docker compose down`은 컨테이너를 삭제하지만 볼륨은 유지합니다. 볼륨까지 삭제하려면 데이터 손실을 확인한 후 `docker compose down -v`를 실행합니다.

## 자동 검증

정적 검사는 Docker를 실행하지 않습니다.

```bash
./tests/static_check.sh
```

통합 검사는 임시 컨테이너와 볼륨을 생성합니다. 검사가 끝나면 생성한 자원을 자동으로 정리합니다.

```bash
./scripts/verify.sh
```

검증 범위는 다음과 같습니다.

1. Docker 데몬 연결
2. 커스텀 이미지 빌드
3. 포트 매핑과 `/healthz` 응답
4. 바인드 마운트의 호스트 변경 반영
5. 컨테이너 삭제 후 볼륨 데이터 유지
6. 컨테이너 목록, 로그, 리소스 상태 출력

포트가 사용 중이면 검사 포트를 바꿀 수 있습니다.

```bash
HOST_PORT=28080 BIND_PORT=28081 ./scripts/verify.sh
```

## 커스텀 이미지 설계

| 커스텀 항목 | 목적 |
|---|---|
| `nginx:1.27.5-alpine` | 작은 Linux 기반의 검증 가능한 웹 서버 이미지 사용 |
| `nginx/default.conf` | `/healthz`와 정적 파일 fallback 정의 |
| `site/` 복사 | 기본 NGINX 화면을 프로젝트 화면으로 교체 |
| `EXPOSE 80` | 이미지가 사용하는 컨테이너 포트 문서화 |
| `HEALTHCHECK` | HTTP 서버가 실제로 응답하는지 상태 확인 |
| 보안 응답 헤더 | MIME 스니핑과 iframe 삽입 위험 완화 |
| `site/data/` | Docker 볼륨을 연결할 데이터 경로 제공 |

`EXPOSE 80`만으로 호스트에서 접속할 수 있는 것은 아닙니다. `docker run -p 8080:80`처럼 실행할 때 포트를 게시해야 합니다.

## 수행 결과와 증거

| 검증 항목 | 명령 및 결과 |
|---|---|
| 터미널·권한 | [터미널 및 권한 실습](docs/evidence/terminal-permissions.md) |
| Docker 빌드·포트·마운트·볼륨 | [Docker 자동 검증 결과](docs/evidence/docker-verification.md) |
| 데스크톱·모바일 화면 | [반응형 화면 검증](docs/evidence/ui-verification.md) |
| `hello-world`·Ubuntu | [기본 컨테이너 실습](docs/evidence/container-basics.md) |
| Git·GitHub | [Git 및 GitHub 확인](docs/evidence/git-github.md) |
| 장애 진단 | [트러블슈팅](docs/troubleshooting.md) |


## 보안 확인

- `.env`, 토큰, 비밀번호, 개인키를 커밋하지 않습니다.
- `git config --list`를 공유하기 전에 이메일, 자격 증명 저장소 경로, 토큰을 마스킹합니다.
- 브라우저와 VS Code 캡처에서 계정 이메일과 알림을 확인합니다.
- 민감정보를 커밋했다면 파일만 지우지 말고 해당 토큰을 즉시 폐기하고 Git 기록도 정리합니다.
