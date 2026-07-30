> 이 파일은 2026년 7월 30일 새 README를 작성하기 전의 문서를 보존한 사본입니다.

# AI/SW 개발 워크스테이션 구축 하기

NGINX 정적 웹 서버를 커스텀 Docker 이미지로 빌드하고, 포트 매핑·바인드 마운트·Docker 볼륨을 검증하는 프로젝트입니다.

## 프로젝트 개요
이 프로젝트의 목적은 docker, git, terminal에 대한 이해와 개발 환경 구축이다.

- 터미널로 cli사용과 파일과 폴더의 권한들 이해
- git, github란 무엇인지 이해하고 설정하기
- Docker에 대해 이애하고 Dockerfile로 재현 가능한 웹 서버 이미지를 만들기
- Docker 사용시 포트, 마운트, 볼륨에 대해 이해하고 적용하기

## 실행 환경

| 항목 | 검증 환경 |
|---|---|
| OS | macOS 26.5.2 |
| Shell | zsh (`/bin/zsh`) |
| Docker CLI / Engine | 29.4.1 / 29.4.1 |
| Git | 2.50.1 |
| 컨테이너 베이스 | `nginx:1.27.5-alpine` |
| 컨테이너 포트 | `80` |
| 기본 호스트 포트 | `8080` |

- 확인 명령어 실행 결과
```

```

## 수행 체크리스트

- [x] 터미널 기본 조작과 파일 생성·복사·이동·삭제
- [x] 파일과 디렉터리 권한 변경
- [x] Docker CLI와 데몬 점검
- [x] `hello-world` 및 도커 세팅
- [x] NGINX 기반 커스텀 이미지 작성
- [x] 이미지 빌드와 컨테이너 실행
- [x] 포트 매핑 및 HTTP 응답 확인
- [x] 바인드 마운트 변경 전후 비교
- [x] Docker 볼륨의 데이터 영속성 검증
- [x] 컨테이너 로그와 리소스 확인 자동화
- [x] Git 원격 저장소 연동 확인
- [x] VS Code의 GitHub 로그인 화면 캡처 후 저장소에 추가


## 프로젝트 구조

```text
01/                     
├── .dockerignore               # Docker 빌드 제외 설정
├── .gitignore                  # Git 추적 제외 설정
├── Dockerfile                  # NGINX 이미지 정의
├── README.md                   # 프로젝트 설명 문서
├── compose.yaml                # 컨테이너 서비스 구성
├── backend/                    # 백엔드 API 소스
│   ├── Dockerfile              # 백엔드 이미지 정의
│   └── server.py               # Python HTTP 서버
├── nginx/                      # NGINX 설정 디렉터리
│   └── default.conf            # 경로 및 프록시 설정
├── site/                       # 정적 웹 콘텐츠
│   ├── index.html              # 웹 화면 구조
│   ├── styles.css              # 웹 화면 스타일
│   └── data/                   # 볼륨 데이터 디렉터리
│       └── welcome.txt         # 초기 데이터 파일
└── trouble.md                  # 문제 해결 기록
```

# 4. 터미널 조작 로그
---
터미널에서 디렉터리 이동, 파일 생성, 복사, 이동, 삭제 명령을 실습했습니다.

#### 현재 경로 확인

```bash
$ pwd
/Users/myu/Documents/codyssey/ex/01
```

#### 파일과 디렉터리 확인

```bash
$ ls -al
total 8
drwxr-xr-x@  3 myu  staff   96  7월 28 16:04 .
drwxr-xr-x@ 13 myu  staff  416  7월 28 16:16 ..
-rw-r--r--@  1 myu  staff  391  7월 28 16:10 default.conf
```

#### 디렉터리, 파일 생성

```bash
mkdir terminal-practice
touch terminal-practice/original.txt
```

#### 파일 내용 작성 및 확인

```bash
$ echo "Hello world" > terminal-practice/original.txt
$ cat terminal-practice/original.txt

Hello world
```

#### 파일 복사

```bash
$ cp terminal-practice/original.txt terminal-practice/copy.txt
$ ls terminal-practice

copy.txt
original.txt
```

#### 파일 이름 변경

```bash
$ mv terminal-practice/copy.txt terminal-practice/moved.txt
$ ls terminal-practice

moved.txt
original.txt
```

### 파일 삭제

```bash
$ rm terminal-practice/moved.txt
$ ls terminal-practice

original.txt
```


# 6. 파일 권한 확인 
#### 파일 권한 확인

`chmod`는 **change mode**의 약자로, 파일이나 디렉터리의 접근 권한을 변경하는 명령어입니다.

## 6.1 현재 권한 확인

```bash
$ ls -l terminal-practice/original.txt
-rw-r--r--@ 1 myu  wheel  0 Jul 28 16:49 terminal-practice/original.txt
```

권한 문자열 `-rw-r--r--`는 다음과 같이 구분합니다.

```text
-  rw-  r--  r--
│   │    │    └─ 기타 사용자 권한
│   │    └────── 그룹 권한
│   └─────────── 소유자 권한
└─────────────── 파일 종류
```



```bash
$ ls -l terminal-practice/original.txt
-rw-r--r--  1 user  staff  18 Jul 28 16:00 original.txt
```
- `-`: 일반 파일
- `d`: 디렉터리
- `l`: 심볼릭 링크
- `r`: 읽기 권한
- `w`: 쓰기 권한
- `x`: 실행 권한
- `-`: 해당 권한 없음


## 6.3 `chmod` 기호 방식

기호 방식은 변경할 대상, 연산자, 권한을 조합합니다.

```text
chmod [대상][연산자][권한] 파일명
```

### 대상

| 기호 | 대상 |
|---|---|
| `u` | 파일 소유자(user) |
| `g` | 파일 소유 그룹(group) |
| `o` | 기타 사용자(others) |
| `a` | 모든 사용자(all) |


## 6.4 실행 권한 추가

소유자에게 실행 권한을 추가합니다.

```bash
$ chmod u+x terminal-practice/original.txt
$ ls -l terminal-practice/original.txt
-rwxr--r--@ 1 myu  wheel  0 Jul 28 16:49 terminal-practice/original.txt
```

## 6.5 숫자 방식으로 권한 변경

숫자 방식에서는 각 권한에 다음 값을 사용합니다.

| 권한 | 값 |
|---|---:|
| 읽기 `r` | 4 |
| 쓰기 `w` | 2 |
| 실행 `x` | 1 |
| 권한 없음 `-` | 0 |

실행 명령 결과

```bash
$ chmod 640 terminal-practice/original.txt
$ ls -l terminal-practice/original.txt
-rw-r-----@ 1 myu  wheel  0 Jul 28 16:49 terminal-practice/original.txt
```

### 실행 권한 추가

```bash
chmod +x terminal-practice/original.txt
ls -l terminal-practice/original.txt

-rwxr-xr-x  1 user  staff  18 Jul 28 16:00 original.txt
```




## Docker 운영/검증 로그



## Docker compose 운영/검증 로그




## 포트 매핑 접속 증거


## 바인드 마운트 반영 + 볼륨 영속성 증거


## 트러블슈팅 


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


## 보안 확인

- `.env`, 토큰, 비밀번호, 개인키를 커밋하지 않습니다.
- `git config --list`를 공유하기 전에 이메일, 자격 증명 저장소 경로, 토큰을 마스킹합니다.
- 브라우저와 VS Code 캡처에서 계정 이메일과 알림을 확인합니다.
- 민감정보를 커밋했다면 파일만 지우지 말고 해당 토큰을 즉시 폐기하고 Git 기록도 정리합니다.
