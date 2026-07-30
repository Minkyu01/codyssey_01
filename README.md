# ex01 · 재현 가능한 Docker 개발 워크스테이션

`nginx:1.27.5-alpine`을 기반으로 정적 웹 서버 이미지를 만들고, 터미널·파일 권한·Docker 운영·포트 매핑·바인드 마운트·볼륨 영속성·Git/GitHub 연결을 **실제 명령과 결과로 검증한 과제**입니다.

> 현재 상태: 필수 요구사항 19개 중 `PASS 17`, `PARTIAL 2`, `FAIL 0`입니다. 로컬 구현과 자동 검증은 완료했습니다. 제출 전 사용자가 VS Code의 GitHub 로그인 화면을 개인정보 없이 캡처하고, 최종 변경을 검토·커밋·푸시해야 합니다. 상세 판정은 [요구사항 추적표](docs/evidence/requirements.md)를 참고합니다.

## 1. 프로젝트 목표

- 터미널에서 파일과 디렉터리를 만들고 이동·복사·삭제할 수 있습니다.
- `r`, `w`, `x`와 `644`, `755` 같은 권한 표기를 설명하고 변경할 수 있습니다.
- Dockerfile에서 커스텀 이미지를 만들고 이미지와 컨테이너를 구분할 수 있습니다.
- 호스트 포트와 컨테이너 포트를 연결해야 브라우저에서 접속할 수 있음을 확인합니다.
- 바인드 마운트는 호스트 변경을 즉시 반영하고, 이름 있는 볼륨은 컨테이너 삭제 후에도 데이터를 유지함을 확인합니다.
- Git은 로컬 버전 관리 도구이고 GitHub은 원격 저장소·협업 플랫폼이라는 차이를 설명합니다.

## 2. 체크리스트

| 영역 | 상태 | 검증 결과 |
|---|---:|---|
| 터미널 기본 조작 | [ ] | `pwd`, `ls -la`, `cd`, `mkdir`, `touch`, `cat`, `cp`, `mv`, `rm` 실행 |
| 파일·디렉터리 권한 | [ ] | 파일 `644 → 640`, 디렉터리 `755 → 750` 비교 |
| Docker 설치·Engine | [ ] | CLI와 Engine 29.4.1 응답 확인 |
| 이미지·컨테이너 운영 | [ ] | build/images/run/ps/ps-a/logs/stats/stop/start 실행 |
| 기본 컨테이너 | [ ] | `hello-world`, Ubuntu 전경·분리 실행과 `exec` 확인 |
| 커스텀 Dockerfile | [ ] | NGINX 설정·정적 화면·헬스체크를 포함한 이미지 빌드 |
| 포트 매핑 | [ ] | `127.0.0.1:38080 → 80`, HTTP 200과 브라우저 화면 확인 |
| 바인드 마운트 | [ ] | `bind-before → bind-after` 즉시 반영 |
| Docker 볼륨 | [ ] | 첫 컨테이너 삭제 후 두 번째 컨테이너에서 동일 데이터 확인 |
| Git 로컬 설정 | [ ] | 사용자 설정 존재, 기본 브랜치 `main` 확인 |
| GitHub 원격 연결 | [ ] | 공개 저장소와 SSH 읽기 연결 확인 |
| 민감정보 보호 | [ ] | 이메일 값 마스킹, 계정 없는 브라우저 프로필로 캡처 |
| VS Code GitHub 로그인 캡처 | ⬜ | 사용자가 개인정보를 가린 화면을 추가해야 함 |
| 최종 커밋·푸시 | ⬜ | 변경 파일 검토 후 `origin/main` 반영 필요 |

미완료 두 항목의 안전한 수행 순서는 [사용자 확인이 필요한 마지막 증거](docs/evidence/manual-evidence.md)에 정리했습니다.

## 3. 검증 환경

| 항목                  | 내용                                     | 확인 명령어                                                                             |
| ------------------- | -------------------------------------- | ---------------------------------------------------------------------------------- |
| OS                  | macOS 26.5.2, build 25F84              | `sw_vers`                                                                          |
| Shell               | zsh (`/bin/zsh`)                       | `echo $SHELL`                                                                      |
| Docker CLI / Engine | 29.4.1 / 29.4.1                        | `docker version --format 'CLI: {{.Client.Version}} / Engine: {{.Server.Version}}'` |
| Docker Engine OS    | orbstack, OrbStack, x86_64           | `docker info --format '{{.Name}}, {{.OperatingSystem}}, {{.Architecture}}'`        |
| Docker Compose      | v5.1.3                                 | `docker compose version`                                                           |
| Git                 | 2.50.1 (Apple Git-155)                 | `git --version`                                                                    |
| Git 기본 브랜치          | `main`                                 | `git config --global init.defaultBranch`                                           |

전체 원문은 [환경 검증 로그](docs/evidence/environment.md)에 있습니다.

```bash
$ sw_vers
ProductName:            macOS
ProductVersion:         26.5.2
BuildVersion:           25F84

$ echo $SHELL
/bin/zsh

$ docker --version
Docker version 28.5.2, build ecc6942

$ docker version --format 'CLI: {{.Client.Version}} / Engine: {{.Server.Version}}'
CLI: 28.5.2 / Engine: 28.5.2

$  docker info --format '{{.Name}}, {{.OperatingSystem}}, {{.Architecture}}'
orbstack, OrbStack, x86_64

$ docker compose version
Docker Compose version v2.40.3

$ git --version
git version 2.53.0
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
└── README.md                     # 프로젝트 전체 워크플로우
``` 

## 5. 터미널 조작 로그

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

## 6. 파일 권환

`chmod`는 **change mode**의 약자로, 파일이나 디렉터리의 접근 권한을 변경하는 명령어입니다.

#### 6.1 현재 권한 확인

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

####  6.2 권한 변경

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

### 절대 경로화 상대경로 
| 구분 | 의미 | 예시 |
|---|---|---|
| **절대 경로** | 최상위 위치부터 시작하는 전체 주소 | `/Users/me/Documents/test.txt` |
| **상대 경로** | 현재 폴더를 기준으로 나타낸 주소 | `./test.txt`, `../images/photo.png` |
| `.` | 현재 폴더 | `./file.txt` |
| `..` | 상위 폴더 | `../file.txt` |



## 7. git, github 

| 구분 | 설명 |
|---|---|
| **Git** | 로컬 컴퓨터에서 소스 코드 변경 이력을 관리하는 도구 |
| **GitHub** | Git 저장소를 인터넷에 저장하고 공유하는 서비스 |
| **로컬 저장소** | 현재 컴퓨터에 존재하는 Git 저장소 |
| **원격 저장소** | GitHub에 존재하는 저장소 |
| `origin` | 원격 저장소에 일반적으로 사용하는 별칭 |

- git 설정

``` bash 
# Git 설치 확인
git --version

# 사용자 정보와 기본 브랜치 설정
git config --global user.name "GitHub 사용자명"
git config --global user.email "GitHub 이메일"

# Git 설정 확인
git config --list


# GitHub 로그인
gh auth login

# 로그인 상태 확인
gh auth status

# 프로젝트 저장소 초기화
cd 프로젝트경로
git init -b main

# 초기 커밋
git status
git add .
git commit -m "Initial commit"

# 기존 GitHub 저장소 연결
git remote add origin https://github.com/사용자명/저장소명.git

# 원격 저장소에 업로드
git push -u origin main

# 연동 검증
git remote -v
git branch -vv
git status
git ls-remote --heads origin
```

- git config 명령어 전체 확인

``` bash
git config --list

```


#### http, ssh 방식
| 구분 | HTTPS | SSH |
|---|---|---|
| 인증 수단 | 토큰·OAuth·자격 증명 관리자 | 공개키와 개인키 |
| 비밀정보 위치 | 자격 증명 관리자 등에 저장 | 개인키가 로컬에 저장 |
| 네트워크 포트 | 일반적으로 `443` | 일반적으로 `22` |
| 주요 장점 | 방화벽·프록시 환경에서 연결이 쉬움 | 키 등록 후 편리하게 인증 |
| 주의점 | 토큰 노출 방지 | 개인키와 암호 보호 |


## 8. 도커
도커란 맥, 리눅스, 윈도우처럼 각각 개발 환경이 제각각이기 때문에 가상의 환경을 만들어서 어떤 운영체제이든지 간에 같은 결과를 볼수 있게 해주는 기술 이다

#### 도커 파일, 이미지
| 개념 | 비유 |
|---|---|
| Dockerfile | 이미지 제작 설명서 |
| 이미지 | 프로그램 실행 설계도 |
| 컨테이너 | 이미지를 실제로 실행한 상태 |

하나의 이미지로 여러개의 컨테이너를 실행할 수 있습니다. 

#### 도커 컨테이너 
도커 이미지를 기반으로 실제 실행된 프로세스
``` text
nginx 이미지
 ├─ nginx-container-1
 ├─ nginx-container-2
 └─ nginx-container-3
```
하나의 이미지로 여러 컨테이너을 생성할 수 있습니다. 

#### 도커 전체 과정 
``` text 
소스 코드 + Dockerfile
          ↓
     docker build
          ↓
       Docker 이미지
          ↓
      docker run
          ↓
        컨테이너
          ↓
   stdout/stderr 로그
```

#### docker 운영 명령

``` bash
$ docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
4f55086f7dd0: Pull complete 
Digest: sha256:c3cbe1cc1aa588a64951ac6286e0df7b27fe2e6324b1001c619bb358770c0178
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started

$ docker images
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
nginx         latest    4e5db4761e0f   2 weeks ago    161MB
hello-world   latest    e2ac70e7319a   4 months ago   10.1kB
```

- 도커는 이미지를 로컬에 존재하지 않으면 도커 허브에서 검색후 존재한다면 가져온다 


``` bash 
# 실행 중인 컨테이너
$ docker ps
CONTAINER ID   IMAGE          COMMAND                   CREATED          STATUS                    PORTS                                     NAMES

# 전체 컨테이너
$ docker ps -a
CONTAINER ID   IMAGE          COMMAND                   CREATED              STATUS                          PORTS                                     NAMES
388e31eff3f4   hello-world    "/hello"                  About a minute ago   Exited (0) About a minute ago                                             hello-test

# nginx 컨테이너 실행
$ docker run nginx
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2026/07/30 09:34:29 [notice] 1#1: using the "epoll" event method
2026/07/30 09:34:29 [notice] 1#1: nginx/1.31.3
2026/07/30 09:34:29 [notice] 1#1: built by gcc 14.2.0 (Debian 14.2.0-19) 
2026/07/30 09:34:29 [notice] 1#1: OS: Linux 6.17.8-orbstack-00308-g8f9c941121b1
2026/07/30 09:34:29 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 20480:1048576
2026/07/30 09:34:29 [notice] 1#1: start worker processes
2026/07/30 09:34:29 [notice] 1#1: start worker process 30
2026/07/30 09:34:29 [notice] 1#1: start worker process 31
2026/07/30 09:34:29 [notice] 1#1: start worker process 32
2026/07/30 09:34:29 [notice] 1#1: start worker process 33
2026/07/30 09:34:29 [notice] 1#1: start worker process 34
2026/07/30 09:34:29 [notice] 1#1: start worker process 35
            nginx-running

# nginx 중지
$ docker stop nginx
nginx-running

# nginx 재시작
$ docker start nginx
nginx-running

# 확인
$ docker ps -a
CONTAINER ID   IMAGE          COMMAND                   CREATED             STATUS                       PORTS                                     NAMES
b5076ac1d50b   nginx:alpine   "/docker-entrypoint.…"   3 minutes ago       Up 8 seconds                 80/tcp                                    nginx-running
388e31eff3f4   hello-world    "/hello"   

```

####  attach와 exec 차이

| 구분 | 명령어 | 특징 |
|---|---|---|
| `attach` | `docker attach 컨테이너명` | 실행 중인 메인 프로세스의 입출력에 연결 |
| `exec` | `docker exec -it 컨테이너명 sh` | 컨테이너 내부에서 새로운 프로세스 실행 |

``` bash
$ docker exec -it nginx-running sh

$ docker attach nginx-running
```

####  Dockerfile로 커스텀 이미지 만들기

``` bash
FROM nginx:alpine

LABEL maintainer="whitecy01"
LABEL description="Dev Workstation - Custom Nginx Web Server"
LABEL version="1.0"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY app/index.html /usr/share/nginx/html/index.html

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```


| 명령어 | 설명 |
|---|---|
| `FROM nginx:alpine` | Nginx Alpine 이미지를 기반으로 사용 |
| `LABEL` | 이미지 제작자, 설명, 버전 등의 정보 저장 |
| `COPY nginx.conf ...` | Nginx 설정 파일을 이미지 내부에 복사 |
| `COPY app/index.html ...` | 웹페이지 파일을 Nginx 서비스 폴더에 복사 |
| `HEALTHCHECK` | 웹 서버의 응답 상태를 주기적으로 검사 |
| `EXPOSE 80` | 컨테이너가 80번 포트를 사용함을 명시 |
| `CMD` | 컨테이너 시작 시 Nginx 실행 |

#### 도커 운영 검증 로그

``` bash
docker --version
Docker version 28.5.2, build ecc6942

$ docker info
Client:
 Version:    28.5.2
 Context:    orbstack

Server:
 Containers: 2
  Running: 1
  Paused: 0
  Stopped: 1
 Images: 3
 Server Version: 28.5.2
 Storage Driver: overlay2
  Backing Filesystem: btrfs
 Operating System: OrbStack
 OSType: linux
 Architecture: aarch64
 CPUs: 8
 Total Memory: 7.808GiB
```

- Docker images 목록 확인 
``` bash
$ docker images
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
my-nginx      1.0       6caa9c1407eb   2 hours ago    61.6MB
nginx         alpine    e7b8033f1661   7 days ago     61.6MB
hello-world   latest    eb84fdc6f2a3   8 days ago     5.2kB
```

- 전체 컨테이너 목록 확인
``` bash 
$ docker ps -a
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS                     PORTS                  NAMES
b5076ac1d50b   nginx:alpine   "/docker-entrypoint.…"   4 minutes ago   Up 8 seconds               0.0.0.0:8080->80/tcp   nginx-running
388e31eff3f4   hello-world    "/hello"                 9 minutes ago   Exited (0) 9 minutes ago                          hello-test
```

- 실행 중인 컨테이너만 확인
``` bash
$ docker ps
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS         PORTS                  NAMES
b5076ac1d50b   nginx:alpine   "/docker-entrypoint.…"   4 minutes ago   Up 8 seconds   0.0.0.0:8080->80/tcp   nginx-running
```

- 컨테이너 로그 확인
``` bash
$ docker run -d --name test hello-world
9057f9231f2796ecccf31186570e9c11bc24094bf99937a9a4d2fe1a5e0d192c

$ Documents % docker logs test
Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
 ```

- docker 리소스 확인
``` bash 
$ docker stats --no-stream
CONTAINER ID   NAME            CPU %   MEM USAGE / LIMIT    MEM %   NET I/O       BLOCK I/O        PIDS
b5076ac1d50b   nginx-running   0.00%   7.68MiB / 7.808GiB   0.10%   830B / 126B   7.29MB / 4.1kB   9

```


#### 포트 매핑이 필요한 이유 
Docker 컨테이너는 호스트 컴퓨터와 분리된 네트워크 환경에서 실행됩니다. 
``` bash
호스트 컴퓨터                 Docker 컨테이너
localhost:8080  ──────────▶  컨테이너:80
```

- 포트 매핑 명령어
``` bash 
docker run -d --name nginx-running -p 8080:80 nginx

-p 호스트_포트:컨테이너_포트
-p 8080:80
```

#### EXPOSE와 -p의 차이
| 구분 | 역할 |
|---|---|
| `EXPOSE 80` | 이미지가 80번 포트를 사용한다고 문서화 |
| `-p 8080:80` | 호스트와 컨테이너 포트를 실제로 연결 |




#### Docker 볼륨 영속성 검증
Docker 볼륨이란?
Docker 볼륨은 컨테이너의 데이터를 컨테이너 외부에 저장하는 공간입니다

``` bash
컨테이너의 /data
       │
       ▼
Docker 볼륨 volume-data
       │
       └── 컨테이너를 삭제해도 유지
```

- 볼륨 명령어들

``` bash
# 볼륨 생성
$ docker volume create volume-data
volume-data

# 볼륨 목록
$ docker volume ls
DRIVER    VOLUME NAME
local     volume-data

# 볼륨 상세 설명
$ docker volume inspect volume-data
[
    {
        "CreatedAt": "2026-07-30T05:00:00Z",
        "Driver": "local",
        "Mountpoint": "/var/lib/docker/volumes/volume-data/_data",
        "Name": "volume-data",
        "Scope": "local"
    }
]

# 볼륨 붙이고 컨테이서 실행
$ docker run -d \
  --name volume-test-1 \
  -v volume-data:/data \
  alpine \
  sh -c 'echo "Docker volume persistence test" > /data/message.txt && tail -f /dev/null'

7db891e759c5a1d9bb34b32dfe99a47bd8a55ac092377231ca787876577549d2

```
- 볼륨 연결 명령어 설명

| 부분 | 설명 |
|---|---|
| `-d` | 컨테이너를 백그라운드에서 실행 |
| `--name volume-test-1` | 첫 번째 컨테이너 이름 |
| `-v volume-data:/data` | 볼륨을 컨테이너의 `/data`에 연결 |
| `alpine` | 사용할 이미지 |
| `echo ... > /data/message.txt` | 볼륨에 테스트 파일 작성 |
| `tail -f /dev/null` | 컨테이너가 종료되지 않도록 유지 |



#### 데이터 영속성 검증 과정
``` bash
# 실습 이미지 다운로드
$ docker pull alpine:latest

# 볼륨 생성
$ docker volume create volume-data

# 볼륨 목록 확인
$ docker volume ls
volume-data

# 볼륨 상세 정보 확인
$ docker volume ls
DRIVER    VOLUME NAME
local     volume-data

# 첫 번째 컨테이너 생성 및 테스트 파일 작성
$ docker run -d \
  --name volume-test-1 \
  -v volume-data:/data \
  alpine \
  sh -c 'echo "Docker volume persistence test" > /data/message.txt && tail -f /dev/null'
# && tail -f /dev/null ->  docker 프로세스가 종료되지 않게 하는 명령어

# 볼륨 연결 상태 확인
$ docker inspect \
  --format '{{range .Mounts}}{{.Type}}: {{.Name}} -> {{.Destination}}{{end}}' \
  volume-test-1
volume: volume-data -> /data

# 삭제 전 데이터 확인
$ docker exec volume-test-1 cat /data/message.txt
Docker volume persistence test

$ docker exec volume-test-1 ls -l /data
total 4  -rw-r--r--    1 root     root            31 Jul 30 09:53 message.txt

# 첫 번째 컨테이너 중지 및 삭제
$ docker stop volume-test-1
$ docker rm volume-test-1

# 삭제 확인
$ docker ps -a --filter name=volume-test-1
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS        NAMES

# 볼륨이 남아 있는지 확인
$ docker volume ls --filter name=volume-data
DRIVER    VOLUME NAME
local     volume-data

# 새로운 컨테이너에서 기존 데이터 확인
$ docker run --rm \
  --name volume-test-2 \
  -v volume-data:/data \
  alpine \
  cat /data/message.txt
Docker volume persistence test
```

















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
