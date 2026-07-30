# 실행 환경 검증

2026년 7월 30일에 프로젝트 루트에서 실행했습니다. 사용자 이메일과 자격 증명 경로는 출력하지 않았습니다.

## 운영체제와 터미널

```console
$ sw_vers
ProductName:        macOS
ProductVersion:     26.5.2
BuildVersion:       25F84

$ printf 'shell=%s\n' "$SHELL"
shell=/bin/zsh

$ printf 'term_program=%s\n' "$TERM_PROGRAM"
term_program=iTerm.app

$ printf 'term=%s\n' "$TERM"
term=xterm-256color
```

## Docker

```console
$ docker --version
Docker version 29.4.1, build 055a478

$ docker info --format \
    'ServerVersion={{.ServerVersion}} Driver={{.Driver}} OperatingSystem={{.OperatingSystem}} OSType={{.OSType}} Architecture={{.Architecture}}'
ServerVersion=29.4.1 Driver=overlayfs OperatingSystem=Docker Desktop OSType=linux Architecture=aarch64

$ docker compose version
Docker Compose version v5.1.3
```

`docker info`가 서버 값을 반환했으므로 Docker CLI뿐 아니라 Docker Engine도 동작합니다. Docker Engine은 macOS 호스트 위의 Linux 환경에서 컨테이너를 실행합니다.

## Git

```console
$ git --version
git version 2.50.1 (Apple Git-155)

$ git config --get init.defaultBranch
main

$ git config --get user.name >/dev/null && echo 'user.name=configured'
user.name=configured

$ git config --get user.email >/dev/null && echo 'user.email=configured (value redacted)'
user.email=configured (value redacted)
```

이메일 값은 과제 수행 여부와 관계없는 개인정보이므로 존재 여부만 확인했습니다.

