# 빈 디렉터리에서 웹 서버 재구성하기

이 과정을 마치면 빈 디렉터리에서 현재 프로젝트와 같은 NGINX 이미지를 만들고, 포트 매핑·바인드 마운트·Docker 볼륨을 직접 검증할 수 있습니다.

## 준비 사항

- Docker CLI와 Docker Engine이 실행 중이어야 합니다.
- macOS에서는 Docker Desktop 또는 OrbStack을 사용할 수 있습니다.
- `8080`, `8081` 포트를 다른 프로세스가 사용하지 않아야 합니다.
- 명령은 프로젝트 루트에서 실행합니다.

먼저 환경을 확인합니다.

```console
$ docker --version
Docker version 29.4.1, build 055a478

$ docker info --format 'Server={{.ServerVersion}} OS={{.OperatingSystem}}'
Server=29.4.1 OS=Docker Desktop
```

버전 문자열은 환경마다 달라도 됩니다. 두 명령이 오류 없이 Docker 클라이언트와 서버 정보를 출력해야 합니다.

## 1. 빈 작업 디렉터리를 준비합니다

```bash
mkdir -p workstation-lab/nginx workstation-lab/site/data
cd workstation-lab
pwd
```

예상 결과는 현재 경로가 `workstation-lab`으로 끝나는 것입니다.

현재 프로젝트의 필수 파일을 같은 상대 경로로 작성합니다.

| 작성 경로 | 현재 구현 | 역할 |
|---|---|---|
| `Dockerfile` | [Dockerfile](../Dockerfile) | `nginx:1.27.5-alpine` 기반 이미지 정의 |
| `nginx/default.conf` | [nginx/default.conf](../nginx/default.conf) | 정적 파일 경로와 `/healthz` 정의 |
| `site/index.html` | [site/index.html](../site/index.html) | 실습 웹 화면 |
| `site/styles.css` | [site/styles.css](../site/styles.css) | 반응형 화면 스타일 |
| `site/data/welcome.txt` | [site/data/welcome.txt](../site/data/welcome.txt) | 볼륨 연결 대상의 초기 파일 |
| `.dockerignore` | [.dockerignore](../.dockerignore) | 불필요한 빌드 컨텍스트 제외 |

선택 과제인 Docker Compose까지 재현하려면 [compose.yaml](../compose.yaml)도 작성합니다. 현재 Compose 구성은 `web` 서비스 하나와 이름 있는 볼륨 하나를 정의합니다.

필수 파일이 있는지 확인합니다.

```bash
for file in \
  Dockerfile \
  nginx/default.conf \
  site/index.html \
  site/styles.css \
  site/data/welcome.txt
do
  test -f "$file" || exit 1
done
printf 'artifact-check=ok\n'
```

예상 결과:

```text
artifact-check=ok
```

## 2. 커스텀 이미지를 빌드합니다

```bash
docker build -t workstation-web:1.0 .
docker image ls workstation-web:1.0
```

빌드 마지막 부분에 다음 이름이 표시되어야 합니다.

```text
workstation-web:1.0
```

이 이미지는 다음 항목을 기본 NGINX 이미지에 추가합니다.

- 프로젝트용 라벨과 `APP_ENV=learning`
- `nginx/default.conf`
- `site/` 정적 파일
- `/usr/share/nginx/html/data` 디렉터리와 소유권
- 컨테이너 포트 `80`
- `/healthz`를 호출하는 `HEALTHCHECK`

## 3. 포트를 연결하고 준비 상태를 확인합니다

호스트의 `127.0.0.1:8080`을 컨테이너의 `80` 포트에 연결합니다.

```bash
docker run -d \
  --name ex01-rebuild-web \
  -p 127.0.0.1:8080:80 \
  -v ex01-rebuild-data:/usr/share/nginx/html/data \
  workstation-web:1.0
```

`docker run -d`가 컨테이너 ID를 반환해도 NGINX가 즉시 요청을 받을 수 있다는 뜻은 아닙니다. 다음과 같이 최대 30초 동안 준비 상태를 확인합니다.

```bash
attempt=1
ready=0

while [ "$attempt" -le 30 ]; do
  if body=$(curl -fsS http://127.0.0.1:8080/healthz); then
    printf '%s\n' "$body"
    ready=1
    break
  fi

  attempt=$((attempt + 1))
  sleep 1
done

test "$ready" -eq 1
```

예상 결과:

```text
ok
```

페이지와 포트 매핑도 확인합니다.

```bash
curl -fsS http://127.0.0.1:8080/ | grep -F 'Docker Workstation Lab'
docker ps \
  --filter name=ex01-rebuild-web \
  --format 'name={{.Names}} ports={{.Ports}}'
```

출력에는 `Docker Workstation Lab`과 `127.0.0.1:8080->80/tcp`가 포함되어야 합니다.

## 4. 바인드 마운트의 즉시 반영을 확인합니다

바인드 마운트는 호스트의 실제 디렉터리를 컨테이너 경로에 연결합니다. 이미지 재빌드 없이 호스트 파일 변경이 반영됩니다.

```bash
printf 'bind-before\n' > site/bind-proof.txt

docker run -d \
  --name ex01-rebuild-bind \
  -p 127.0.0.1:8081:80 \
  -v "$PWD/site:/usr/share/nginx/html:ro" \
  workstation-web:1.0
```

준비 상태가 된 뒤 변경 전 값을 확인합니다.

```bash
curl -fsS http://127.0.0.1:8081/bind-proof.txt
```

예상 결과:

```text
bind-before
```

호스트 파일을 바꾸고 다시 요청합니다.

```bash
printf 'bind-after\n' > site/bind-proof.txt
curl -fsS http://127.0.0.1:8081/bind-proof.txt
```

예상 결과:

```text
bind-after
```

## 5. Docker 볼륨의 영속성을 확인합니다

이 실습은 첫 번째 컨테이너를 삭제한 뒤 두 번째 컨테이너가 같은 파일을 읽는지 확인합니다.

```bash
docker volume create ex01-persistence-data

docker run \
  --name ex01-volume-first \
  -v ex01-persistence-data:/data \
  --entrypoint sh \
  workstation-web:1.0 \
  -c 'printf "persisted-from-first-container\n" > /data/proof.txt; cat /data/proof.txt'
```

첫 번째 확인 결과:

```text
persisted-from-first-container
```

첫 컨테이너를 삭제하고 새 컨테이너에서 같은 볼륨을 읽습니다.

```bash
docker rm ex01-volume-first

docker run --rm \
  --name ex01-volume-second \
  -v ex01-persistence-data:/data \
  --entrypoint cat \
  workstation-web:1.0 \
  /data/proof.txt
```

두 번째 확인 결과도 같아야 합니다.

```text
persisted-from-first-container
```

컨테이너가 아니라 `ex01-persistence-data` 볼륨에 파일이 저장됐기 때문에 데이터가 유지됩니다.

## 6. Compose 구성을 선택적으로 실행합니다

[compose.yaml](../compose.yaml)을 작성했다면 먼저 구문과 최종 설정을 확인합니다.

```bash
docker compose config
docker compose up -d --build
docker compose ps
```

현재 구성의 기본 포트는 `8080:80`입니다. 다른 포트를 사용하려면 다음과 같이 실행합니다.

```bash
HOST_PORT=8082 docker compose up -d --build
curl -fsS http://127.0.0.1:8082/healthz
docker compose down
```

예상 HTTP 결과는 `ok`입니다. `docker compose down`은 컨테이너와 기본 네트워크를 삭제하지만 이름 있는 볼륨은 유지합니다.

## 7. 실습 자원을 정리합니다

다음 명령은 이 문서에서 만든 이름의 자원만 정리합니다.

```bash
docker rm -f ex01-rebuild-web ex01-rebuild-bind 2>/dev/null || true
docker volume rm ex01-rebuild-data ex01-persistence-data
rm -f site/bind-proof.txt
```

Compose를 실행했다면 별도로 종료합니다.

```bash
docker compose down
```

볼륨까지 삭제하는 `docker compose down -v`는 저장 데이터를 지웁니다. 데이터가 필요 없는지 확인한 뒤 사용합니다.

이미지가 더 필요 없고 해당 이미지를 참조하는 컨테이너도 없을 때만 삭제합니다.

```bash
docker image rm workstation-web:1.0
```

중지된 컨테이너가 이미지 삭제를 막는 경우는 [트러블슈팅](./troubleshooting.md)을 참고합니다.

## 완료 기준

- `docker build`가 `workstation-web:1.0`을 만듭니다.
- `/healthz`가 `ok`를 반환합니다.
- `docker ps`가 호스트 포트와 컨테이너 포트의 연결을 보여 줍니다.
- 바인드 마운트의 응답이 `bind-before`에서 `bind-after`로 바뀝니다.
- 첫 컨테이너를 삭제한 뒤에도 볼륨의 `proof.txt`가 유지됩니다.
- 실습용 컨테이너와 볼륨을 정리했습니다.

개념을 함께 복습하려면 [학습 가이드](./study-guide.md)를 확인합니다.
