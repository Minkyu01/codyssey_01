# 평가 대비 학습 계획

평가 전에는 명령을 암기하기보다 요구사항, 산출물, 증거를 연결해서 연습합니다. 완료 기준은 여섯 학습 목표를 자신의 말로 설명하고, 빈 디렉터리에서 핵심 Docker 흐름을 재현하는 것입니다.

## 완료 기준

- 여섯 학습 목표를 각각 30초 안에 설명합니다.
- `Dockerfile`, `nginx/default.conf`, `site/`의 역할을 설명합니다.
- 이미지 빌드부터 `/healthz` 응답까지 직접 시연합니다.
- 바인드 마운트의 전·후 응답을 비교합니다.
- 첫 컨테이너 삭제 뒤 새 컨테이너에서 볼륨 데이터를 읽습니다.
- Git 로컬 상태, GitHub 원격 상태, VS Code 로그인 증거를 구분합니다.
- 실제 트러블슈팅 두 건을 증상부터 검증까지 설명합니다.

## 학습 범위

필수 범위는 터미널, 권한, Docker 기본 운영, 커스텀 NGINX 이미지, 포트, 마운트, 볼륨, Git/GitHub입니다.

현재 [compose.yaml](../compose.yaml)은 `web` 서비스 하나만 실행합니다. `backend/`는 Compose에 연결되지 않았으므로 멀티 컨테이너 구현으로 설명하지 않습니다. Compose와 백엔드는 필수 항목을 모두 연습한 뒤 선택 범위로 다룹니다.

## 1순위: 경로와 권한

목표:

- 절대 경로와 상대 경로를 같은 파일에 적용합니다.
- 파일과 디렉터리 권한을 변경 전·후로 비교합니다.

연습:

```bash
pwd
ls -la
mkdir -p /private/tmp/ex01-eval/practice
touch /private/tmp/ex01-eval/practice/file.txt
cp /private/tmp/ex01-eval/practice/file.txt /private/tmp/ex01-eval/practice/copy.txt
mv /private/tmp/ex01-eval/practice/copy.txt /private/tmp/ex01-eval/practice/moved.txt
chmod 640 /private/tmp/ex01-eval/practice/file.txt
chmod 750 /private/tmp/ex01-eval/practice
```

성공 기준은 파일과 디렉터리의 권한을 각각 읽고, `rm`으로 임시 파일을 정리하는 것입니다.

## 2순위: 이미지와 컨테이너

목표:

- Dockerfile, 이미지, 컨테이너의 관계를 설명합니다.
- 이미지 빌드와 컨테이너 운영 명령을 실행합니다.

연습:

```bash
docker build -t workstation-web:1.0 .
docker image ls workstation-web:1.0
docker run -d --name ex01-eval-web -p 127.0.0.1:8080:80 workstation-web:1.0
docker ps
docker ps -a
docker logs ex01-eval-web
docker stats --no-stream ex01-eval-web
```

컨테이너를 시작한 직후에는 HTTP 서버가 아직 준비 중일 수 있습니다. [트러블슈팅](./troubleshooting.md)의 준비 상태 확인 절차를 함께 연습합니다.

## 3순위: 포트와 HTTP 검증

목표:

- `127.0.0.1:8080:80`의 세 값을 구분합니다.
- 프로세스 실행과 서비스 준비 완료를 구분합니다.

연습:

```bash
docker ps --filter name=ex01-eval-web
curl -fsS http://127.0.0.1:8080/healthz
curl -fsS http://127.0.0.1:8080/ | grep -F 'Docker Workstation Lab'
```

성공 기준은 포트 열에 `8080->80/tcp`가 보이고 `/healthz`가 `ok`를 반환하는 것입니다.

## 4순위: 바인드 마운트와 볼륨

목표:

- 바인드 마운트는 호스트 변경 반영, 볼륨은 데이터 영속성이라는 차이를 증명합니다.
- “볼륨이 존재한다”와 “데이터가 유지된다”를 구분합니다.

필수 시나리오:

1. 바인드 마운트의 호스트 파일을 `before`에서 `after`로 바꿉니다.
2. 첫 컨테이너가 볼륨에 파일을 씁니다.
3. 첫 컨테이너를 삭제합니다.
4. 두 번째 컨테이너가 같은 파일을 읽습니다.

전체 명령은 [빈 디렉터리 재구성 가이드](./getting-started.md)를 사용합니다.

## 5순위: Git과 GitHub

목표:

- 로컬 변경, 커밋, 원격 주소, 원격 업로드를 별도 상태로 확인합니다.
- 계정 화면에 민감정보를 남기지 않습니다.

연습:

```bash
git status --short
git branch --show-current
git log --oneline -5
git remote -v
```

`git config --list`를 제출할 때는 이메일, 자격 증명 저장소 경로, 토큰이 포함되는지 먼저 확인합니다. VS Code 로그인과 GitHub 저장소 화면은 사용자가 직접 확인해야 합니다.

## 6순위: 요구사항을 증거로 바꾸기

요구사항을 읽을 때 다음 세 칸을 채웁니다.

| 요구사항 | 산출물 | 통과 증거 |
|---|---|---|
| 커스텀 이미지 | `Dockerfile`, `nginx/`, `site/` | 실제 `docker build` 성공 |
| 포트 매핑 | 실행 중인 컨테이너 | `docker ps` 포트 열과 `curl` 응답 |
| 바인드 마운트 | 호스트 파일과 마운트 명령 | 변경 전·후 HTTP 응답 |
| 볼륨 영속성 | 이름 있는 볼륨 | 첫 컨테이너 삭제 전·후 같은 데이터 |
| Git 설정 | 로컬 Git 저장소 | 마스킹한 설정·브랜치·로그 |
| GitHub/VS Code 연동 | 원격 저장소와 로그인 화면 | 실제 원격 파일 및 사용자가 수집한 화면 |

체크 표시나 설명만으로는 실행 요구사항을 증명할 수 없습니다. 명령, 출력, 파일, 이미지 중 무엇이 통과 조건인지 먼저 정합니다.

## 빈 디렉터리 재구성 순서

1. `purpose.md`에서 필수 요구사항과 선택 과제를 나눕니다.
2. `nginx/`, `site/data/` 디렉터리를 만듭니다.
3. `Dockerfile`, NGINX 설정, 정적 사이트를 작성합니다.
4. 빌드 컨텍스트와 `COPY` 상대 경로를 확인합니다.
5. 이미지를 빌드합니다.
6. 로컬 포트에 컨테이너를 실행합니다.
7. 준비 상태를 기다리고 `/healthz`와 `/`를 확인합니다.
8. 바인드 마운트의 변경 전·후를 비교합니다.
9. 컨테이너 삭제 전·후 볼륨 데이터를 비교합니다.
10. 실습 자원을 정리하고 결과를 문서화합니다.

## 셀프 테스트 질문

1. 상대 경로가 같은 문자열인데 다른 파일을 가리키는 경우는 언제입니까?
2. 디렉터리에서 `x` 권한이 없으면 어떤 일이 생깁니까?
3. `644`와 `755`를 기호 표기로 바꾸면 무엇입니까?
4. Dockerfile과 이미지, 컨테이너는 각각 무엇입니까?
5. `EXPOSE 80`만으로 브라우저 접속이 가능하지 않은 이유는 무엇입니까?
6. `127.0.0.1:8080:80`의 왼쪽과 오른쪽 포트는 무엇입니까?
7. `docker run -d` 성공 직후 `curl`이 실패할 수 있는 이유는 무엇입니까?
8. 바인드 마운트와 이름 있는 볼륨은 언제 각각 사용합니까?
9. 컨테이너 삭제 뒤 데이터가 유지됐음을 어떻게 증명합니까?
10. 중지된 컨테이너가 이미지 삭제를 막는 이유는 무엇입니까?
11. `git remote -v`가 무엇을 증명하고 무엇을 증명하지 못합니까?
12. VS Code GitHub 로그인 증거를 자동으로 만들면 안 되는 이유는 무엇입니까?

## 모의 평가 순서

1. 2분: 프로젝트 목적과 파일 구조를 설명합니다.
2. 3분: 이미지 빌드, 컨테이너 실행, `/healthz`를 시연합니다.
3. 3분: 바인드 마운트와 볼륨의 차이를 결과로 보여 줍니다.
4. 2분: Git과 GitHub의 역할을 현재 저장소에 연결합니다.
5. 2분: 실제 장애 두 건의 원인과 해결을 설명합니다.
6. 1분: 실습 컨테이너와 볼륨을 정리합니다.

실제 명령 순서는 [동료 평가 가이드](./peer-review.md)를 참고합니다.
