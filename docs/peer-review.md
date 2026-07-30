# 동료 평가 시연 가이드

평가자는 설명보다 관찰 가능한 결과를 확인합니다. 이 가이드는 약 10분 안에 핵심 흐름을 시연하고, 질문에 현재 파일과 명령으로 답하도록 구성했습니다.

## 시연 전 확인

- Docker Engine이 실행 중입니다.
- 프로젝트 루트에서 명령을 실행합니다.
- `8080`, `8081` 포트가 비어 있습니다.
- 토큰, 이메일, 인증 코드가 터미널과 화면에 보이지 않습니다.
- 주소창을 포함한 브라우저 증거와 VS Code 로그인 증거는 사용자가 직접 준비합니다.
- 기존 사용자 컨테이너나 볼륨을 평가용 정리 명령에 포함하지 않습니다.

현재 Compose는 [compose.yaml](../compose.yaml)의 `web` 서비스 하나만 실행합니다. `backend/`를 멀티 컨테이너 기능으로 설명하지 않습니다.

## 1. 파일과 설계를 설명합니다

다음 파일을 차례로 보여 줍니다.

1. [Dockerfile](../Dockerfile): 베이스 이미지, 복사 경로, 포트, 헬스체크
2. [nginx/default.conf](../nginx/default.conf): 정적 파일과 `/healthz`
3. [site/index.html](../site/index.html): 커스텀 웹 화면
4. [compose.yaml](../compose.yaml): 단일 웹 서비스와 이름 있는 볼륨

짧은 설명:

> `nginx:1.27.5-alpine`에 프로젝트 NGINX 설정과 정적 사이트를 복사했습니다. 컨테이너는 80 포트를 사용하고 `/healthz`로 준비 상태를 확인합니다. 데이터 경로는 컨테이너와 분리할 수 있습니다.

## 2. 빌드와 포트 매핑을 시연합니다

```bash
docker build -t workstation-web:1.0 .

docker run -d \
  --name ex01-review-web \
  -p 127.0.0.1:8080:80 \
  -v ex01-review-data:/usr/share/nginx/html/data \
  workstation-web:1.0
```

한 번의 즉시 요청만으로 성공 여부를 판단하지 않습니다. 최대 30초 동안 확인합니다.

```bash
attempt=1
ready=0

while [ "$attempt" -le 30 ]; do
  if body=$(curl -fsS http://127.0.0.1:8080/healthz); then
    printf 'healthz=%s\n' "$body"
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
healthz=ok
```

운영 상태를 보여 줍니다.

```bash
docker image ls workstation-web:1.0
docker ps --filter name=ex01-review-web
docker logs --tail 20 ex01-review-web
docker stats --no-stream ex01-review-web
```

브라우저에서는 `http://localhost:8080`을 열고 주소창과 페이지를 함께 보여 줍니다.

## 3. 바인드 마운트를 시연합니다

```bash
printf 'review-before\n' > site/review-proof.txt

docker run -d \
  --name ex01-review-bind \
  -p 127.0.0.1:8081:80 \
  -v "$PWD/site:/usr/share/nginx/html:ro" \
  workstation-web:1.0
```

컨테이너가 준비된 뒤 전·후 응답을 비교합니다.

```bash
curl -fsS http://127.0.0.1:8081/review-proof.txt
printf 'review-after\n' > site/review-proof.txt
curl -fsS http://127.0.0.1:8081/review-proof.txt
```

예상 결과:

```text
review-before
review-after
```

핵심 답변:

> 호스트 파일을 바꾼 뒤 이미지를 다시 빌드하지 않았지만 HTTP 응답이 바뀌었습니다. 이것이 바인드 마운트의 즉시 반영 증거입니다.

## 4. 볼륨 영속성을 시연합니다

```bash
docker volume create ex01-review-persistence

docker run \
  --name ex01-review-volume-first \
  -v ex01-review-persistence:/data \
  --entrypoint sh \
  workstation-web:1.0 \
  -c 'printf "review-persisted\n" > /data/proof.txt; cat /data/proof.txt'

docker rm ex01-review-volume-first

docker run --rm \
  --name ex01-review-volume-second \
  -v ex01-review-persistence:/data \
  --entrypoint cat \
  workstation-web:1.0 \
  /data/proof.txt
```

첫 컨테이너 삭제 전과 새 컨테이너 실행 후 모두 `review-persisted`가 출력되어야 합니다.

핵심 답변:

> 컨테이너 이름이나 쓰기 레이어가 아니라 `ex01-review-persistence` 볼륨에 파일을 저장했습니다. 첫 컨테이너를 실제로 삭제한 뒤 새 컨테이너가 파일을 읽었으므로 영속성이 확인됩니다.

## 5. Git과 GitHub 상태를 구분합니다

```bash
git status --short
git branch --show-current
git log --oneline -5
git remote -v
```

설명할 때 다음 범위를 지킵니다.

- `git status`와 `git log`는 로컬 상태를 보여 줍니다.
- `git remote -v`는 원격 주소 설정만 보여 줍니다.
- 실제 GitHub 파일과 최종 커밋은 GitHub 저장소에서 따로 확인합니다.
- VS Code 로그인은 민감정보를 가린 사용자 화면으로 확인합니다.

## 기본 질문과 답변

### 절대 경로와 상대 경로의 차이는 무엇입니까?

절대 경로는 `/`부터 위치를 적고, 상대 경로는 `pwd`의 현재 디렉터리를 기준으로 계산합니다. Dockerfile의 `COPY site/ ...`는 빌드 컨텍스트 `.`을 기준으로 `site/`를 찾습니다.

### `644`와 `755`는 어떻게 읽습니까?

`r=4`, `w=2`, `x=1`을 사용자별로 더합니다. `644`는 `rw-r--r--`, `755`는 `rwxr-xr-x`입니다. 디렉터리의 `x`는 내부 경로 접근 권한입니다.

### Dockerfile, 이미지, 컨테이너의 차이는 무엇입니까?

Dockerfile은 빌드 지시서, 이미지는 빌드된 실행 템플릿, 컨테이너는 이미지에서 시작한 실행 인스턴스입니다.

### `EXPOSE 80`과 `-p 8080:80`은 무엇이 다릅니까?

`EXPOSE 80`은 이미지가 사용할 포트를 문서화합니다. `-p 8080:80`은 호스트 8080을 컨테이너 80에 실제로 게시합니다.

### 바인드 마운트와 볼륨은 어떻게 다릅니까?

바인드 마운트는 사용자가 지정한 호스트 경로를 연결하므로 소스와 설정의 즉시 반영에 적합합니다. 볼륨은 Docker가 관리하며 컨테이너 삭제 뒤에도 유지할 데이터에 적합합니다.

### Git과 GitHub는 어떻게 다릅니까?

Git은 로컬 변경 이력과 브랜치를 관리합니다. GitHub는 Git 저장소를 원격에 호스팅하고 협업 기능을 제공합니다.

## 심화 질문과 답변

### 컨테이너가 `Up`인데 첫 요청이 실패한 이유는 무엇입니까?

`docker run -d`는 컨테이너 프로세스가 시작되면 반환합니다. NGINX가 설정을 읽고 리스닝을 시작하기 전에는 `curl`이 실패할 수 있습니다. 이 프로젝트는 `/healthz`와 제한 시간이 있는 재시도로 준비 상태를 확인합니다.

### 중지한 컨테이너가 이미지 삭제를 막는 이유는 무엇입니까?

중지된 컨테이너도 생성 기준 이미지의 ID를 참조합니다. `docker ps`에는 보이지 않아도 `docker ps -a`에는 남습니다. 해당 컨테이너를 확인하고 삭제한 뒤 이미지를 삭제해야 합니다.

### `HEALTHCHECK`와 직접 `curl`은 무엇이 다릅니까?

`HEALTHCHECK`는 Docker가 설정된 주기로 컨테이너 상태를 갱신합니다. 직접 `curl`은 현재 시점의 HTTP 응답을 즉시 검사합니다. 정상 시작 직후에는 HTTP 요청이 성공해도 Docker 상태가 잠시 `starting`일 수 있습니다.

### 왜 `127.0.0.1`에 포트를 바인딩했습니까?

과제 검증은 같은 컴퓨터에서만 필요합니다. `127.0.0.1`을 사용하면 서비스를 모든 네트워크 인터페이스에 불필요하게 공개하지 않습니다.

### Compose가 멀티 컨테이너를 구현합니까?

현재는 아닙니다. `compose.yaml`에는 `web` 서비스 하나만 있습니다. Compose 기본 구조와 이름 있는 볼륨은 확인할 수 있지만 멀티 컨테이너 네트워크는 별도 구현과 증거가 필요합니다.

## 평가용 자원 정리

```bash
docker rm -f ex01-review-web ex01-review-bind 2>/dev/null || true
docker volume rm ex01-review-data ex01-review-persistence
rm -f site/review-proof.txt
```

정리 뒤 평가용 컨테이너가 남지 않았는지 확인합니다.

```bash
docker ps -a \
  --filter name=ex01-review- \
  --format '{{.Names}}'
```

출력이 없어야 합니다.

문제 해결의 전체 근거는 [트러블슈팅](./troubleshooting.md), 개념 복습은 [학습 가이드](./study-guide.md)를 참고합니다.
