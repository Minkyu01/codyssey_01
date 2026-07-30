# Docker 트러블슈팅 기록

두 사례는 2026년 7월 30일 macOS와 Docker Desktop 환경에서 실제로 관찰했습니다. 각 사례는 오류 문구만 기록하지 않고 원인 가설, 확인 명령, 해결 절차, 재검증 순서로 정리했습니다.

## 사례 1. 중지된 컨테이너 때문에 이미지 삭제 실패

### 증상

`docker ps`에는 실행 중인 컨테이너가 없었지만 이미지 삭제가 실패했습니다. 최초 기록은 [trouble.md](../trouble.md)에 남아 있습니다.

```console
$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES

$ docker rmi workstation-web:1.0
Error response from daemon: conflict: unable to delete workstation-web:1.0 (must be forced) - container a90cfe6e9f26 is using its referenced image 5836ce31c3c4
```

### 원인 가설

`docker ps`는 기본적으로 실행 중인 컨테이너만 표시합니다. 중지된 컨테이너 `a90cfe6e9f26`이 `workstation-web:1.0` 이미지 ID를 계속 참조한다고 판단했습니다.

### 확인

중지된 컨테이너까지 조회합니다.

```bash
docker ps -a --filter ancestor=workstation-web:1.0
docker inspect \
  --format 'name={{.Name}} status={{.State.Status}} image={{.Image}}' \
  a90cfe6e9f26
```

확인 기준:

- `docker ps -a`에는 해당 컨테이너가 나타납니다.
- 상태는 `exited`입니다.
- `.Image`는 오류에 표시된 이미지 ID를 가리킵니다.

### 해결

필요한 데이터가 컨테이너 쓰기 레이어에 없는지 먼저 확인합니다. 삭제해도 되는 중지 컨테이너라면 해당 컨테이너만 제거한 뒤 이미지를 삭제합니다.

```bash
docker rm a90cfe6e9f26
docker rmi workstation-web:1.0
```

`docker container prune`은 다른 중지 컨테이너도 한꺼번에 삭제합니다. 이 사례에서는 대상 ID를 확인한 뒤 `docker rm`으로 하나만 지우는 편이 안전합니다. `docker rmi -f`도 원인을 확인하기 전에 사용하지 않습니다.

### 검증

```bash
docker ps -a --filter ancestor=workstation-web:1.0
docker image ls workstation-web:1.0
```

두 명령에서 대상 컨테이너와 이미지 행이 더 이상 나타나지 않으면 정리가 끝난 것입니다.

### 재발 방지

- 실행 중인 컨테이너는 `docker ps`, 전체 컨테이너는 `docker ps -a`로 구분합니다.
- 실습 종료 순서를 `docker stop` → `docker rm` → `docker rmi`로 정합니다.
- 영속 데이터는 컨테이너 쓰기 레이어가 아니라 이름 있는 볼륨에 저장합니다.

## 사례 2. NGINX 시작 직후 curl 종료 코드 52

### 증상

컨테이너 ID가 반환된 직후 `/healthz`를 호출했을 때 첫 요청이 빈 응답으로 끝났습니다.

```console
$ curl -fsS http://127.0.0.1:28080/healthz
curl: (52) Empty reply from server

$ printf '%s\n' "$?"
52
```

같은 컨테이너에 준비 상태 확인과 재시도를 적용하자 이후 요청은 `ok`를 반환했습니다.

### 원인 가설

다음 세 원인을 구분해야 했습니다.

1. 포트 매핑이 잘못됐습니다.
2. 컨테이너 주 프로세스가 종료됐습니다.
3. 컨테이너는 실행 중이지만 NGINX가 아직 설정 로드와 리스닝을 끝내지 못했습니다.

실제 사례에서는 컨테이너가 실행 중이었고 포트도 게시되어 있었습니다. 시작 직후 Docker 헬스 상태가 `starting`이었으므로 세 번째 가설과 일치했습니다.

### 확인

```bash
docker ps --filter name=codex-ex01-web-20260730
docker logs --tail 50 codex-ex01-web-20260730
docker inspect \
  --format 'status={{.State.Status}} health={{.State.Health.Status}} ports={{json .NetworkSettings.Ports}}' \
  codex-ex01-web-20260730
```

확인 기준:

- 컨테이너 상태는 `running`입니다.
- `80/tcp`에 호스트 포트가 연결되어 있습니다.
- 헬스 상태는 시작 직후 `starting`일 수 있습니다.
- NGINX 로그에는 설정 처리와 워커 프로세스 시작 흐름이 나타납니다.

### 해결

컨테이너 ID 반환을 서비스 준비 완료로 간주하지 않습니다. 제한 시간이 있는 HTTP 재시도를 사용합니다.

```bash
attempt=1
ready=0

while [ "$attempt" -le 30 ]; do
  if body=$(curl -fsS http://127.0.0.1:28080/healthz); then
    printf '%s\n' "$body"
    ready=1
    break
  fi

  attempt=$((attempt + 1))
  sleep 1
done

test "$ready" -eq 1
```

무한 재시도 대신 횟수를 30회로 제한했습니다. 30초 안에 준비되지 않으면 스크립트가 실패하고 로그와 포트 설정을 다시 확인할 수 있습니다.

### 검증

준비 상태 확인이 성공한 뒤 HTTP 응답과 Docker 헬스 상태를 각각 확인합니다.

```bash
curl -fsS http://127.0.0.1:28080/healthz
docker inspect \
  --format '{{.State.Health.Status}}' \
  codex-ex01-web-20260730
```

HTTP 예상 결과:

```text
ok
```

Docker의 헬스체크는 [Dockerfile](../Dockerfile)에 정의된 주기로 실행됩니다. 직접 `curl`이 먼저 성공해도 상태가 잠시 `starting`일 수 있으며, 다음 헬스체크가 성공하면 `healthy`로 바뀝니다.

### 재발 방지

- 실행 자동화에서 `docker run -d` 다음에 즉시 한 번만 `curl`하지 않습니다.
- [nginx/default.conf](../nginx/default.conf)의 `/healthz`처럼 가벼운 준비 상태 엔드포인트를 사용합니다.
- 재시도에는 최대 횟수와 실패 종료 조건을 둡니다.
- 실패할 때 `docker ps`, `docker logs`, `docker inspect`를 함께 수집합니다.

처음부터 실행 흐름을 다시 확인하려면 [빈 디렉터리 재구성 가이드](./getting-started.md)를 사용합니다.
