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





## 9 Docker compose 
여러개의 도커 파일들들과 컨테이너들의 구조들을 쉽게 구성하게 도와준다. 각각의 도커 컨테이너들을 직접 수행하게 되면 

``` bash
services:
  web:
    build:
      context: .
    image: workstation-web:1.0
    container_name: workstation-web
    ports:
      - "${HOST_PORT:-8080}:80"
    volumes:
      - workstation-data:/usr/share/nginx/html/data
    restart: unless-stopped

volumes:
  workstation-data:
```

#### 실행 병령어
``` bash
# docker compose 문법 검사
$ docker compose config

# 빌드 및 실행
$ docker compose up -d --build

# 실행중인 프로세스 확인
$ docker compose ps

# 로깅
$ $ docker compose logs web
ok

# 컨테이너 내부 실행
$ docker compose exec web sh

# 서비스 종료
$ docker compose down

# 볼륨 삭제 
$ docker compose down -v
```
전체 과정 요약

```
up으로 실행
    ↓
ps로 상태 확인
    ↓
logs로 내부 동작 확인
    ↓
down으로 종료
```

#### 환경 변수 활용
환경 변수 사용하는 흐름
``` text
동일한 코드·동일한 이미지
          +
실행할 때 환경 변수만 변경
          ↓
서로 다른 포트·실행 모드로 동작
```

```  yaml
services:
  web:
    ports:
      - "${HOST_PORT:-8080}:80"
```
- HOST_PORT가 정의되어 있지 않다면 8080을 사용한다


환경변수 주입
``` bash
HOST_PORT=18080 docker compose up -d
```

#### .env 파일 활용
기본적으로 docker compose파일은 같은 위치 디렉터리의 .env를 읽는다. 

```text
# 호스트에서 접속할 포트
HOST_PORT=18080

# 애플리케이션 실행 모드
APP_ENV=production
```


- 전체 검증 과정
``` bash
# 1. 기본 환경 변수 값으로 서비스를 실행한다.
docker compose up -d --build

# 2. 기본 포트 8080이 적용됐는지 확인한다.
docker compose ps

# 3. Dockerfile의 기본 실행 모드를 확인한다.
docker compose exec web printenv APP_ENV

# 4. 기본 포트의 HTTP 응답을 확인한다.
curl -fsS http://127.0.0.1:8080/healthz

# 5. 기존 서비스를 종료한다.
docker compose down

# 6. 호스트 포트를 18080으로 변경하여 실행한다.
HOST_PORT=18080 docker compose up -d

# 7. 변경된 포트가 적용됐는지 확인한다.
HOST_PORT=18080 docker compose ps

# 8. 테스트가 끝난 서비스를 정리한다.
HOST_PORT=18080 docker compose down
```




## 10. 트러블슈팅

실제 관찰한 두 사례를 [트러블슈팅 기록](docs/troubleshooting.md)에 문제 → 원인 가설 → 확인 → 해결 → 재검증 순서로 남겼습니다.

1. `docker ps`에는 보이지 않는 중지 컨테이너가 이미지를 참조해 이미지 삭제가 실패했습니다. `docker ps -a`로 대상을 확인하고 해당 컨테이너만 삭제한 뒤 해결했습니다.
2. 컨테이너 ID가 반환된 직후 `curl`이 종료 코드 52를 반환했습니다. 프로세스 시작과 서비스 준비 완료가 다름을 확인하고 `/healthz`에 제한 시간이 있는 재시도를 적용했습니다.

