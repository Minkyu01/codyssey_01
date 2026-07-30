# `purpose.md` 요구사항 최종 판정

판정일은 2026년 7월 30일입니다. [`purpose.md`](../../purpose.md)의 필수 요구사항을 최종 소스, 자동 검증 스크립트, 실제 실행 로그, 브라우저 화면과 대조했습니다.

## 판정 기준

- `PASS`: 산출물과 재현 가능한 증거가 모두 있습니다.
- `PARTIAL`: 구현 또는 연결은 확인했지만 사용자 계정이나 원격 반영 증거가 남았습니다.
- `FAIL`: 필수 구현이나 증거가 없습니다.
- `BLOCKED`: 현재 환경 밖의 조건 때문에 판정할 수 없습니다.

```text
PASS: 17
PARTIAL: 2
FAIL: 0
BLOCKED: 0
```

이 수치는 **현재 로컬 작업 트리** 기준입니다. GitHub에 최종 커밋을 푸시하기 전까지 제출 저장소에서 새 산출물 전체를 볼 수는 없습니다.

## 요구사항 추적표

| ID | 필수 요구사항 | 판정 | 검증 근거 |
|---|---|---|---|
| R1 | GitHub 저장소 링크로 전체 산출물 확인 | PARTIAL | 공개 원격 저장소와 SSH 읽기 연결은 확인했습니다. 새 문서와 소스는 아직 커밋·푸시하지 않았습니다. [`git-github.md`](git-github.md) |
| R2 | README에 개요·환경·체크리스트·검증 방법·증거 링크 | PASS | 새 `README.md`가 각 항목과 상세 증거 문서의 진입점을 제공합니다. |
| R3 | `pwd`, `ls -la`, `cd`, `mkdir`, `touch`, `cat`, `cp`, `mv`, `rm` 실행 로그 | PASS | [`terminal-permissions.md`](terminal-permissions.md) |
| R4 | 파일 권한 변경 전·후 | PASS | `644`에서 `640`으로 바꾸고 결과를 비교했습니다. [`terminal-permissions.md`](terminal-permissions.md) |
| R5 | 디렉터리 권한 변경 전·후 | PASS | `755`에서 `750`으로 바꾸고 결과를 비교했습니다. [`terminal-permissions.md`](terminal-permissions.md) |
| R6 | Docker 버전과 Engine 동작 점검 | PASS | CLI·Engine 버전과 `docker info` 결과를 기록했습니다. [`environment.md`](environment.md) |
| R7 | 이미지 다운로드·빌드·목록 확인 | PASS | 베이스 이미지 실행과 커스텀 이미지 빌드·`docker images` 결과가 있습니다. [`container-basics.md`](container-basics.md), [`docker-verification.md`](docker-verification.md) |
| R8 | 컨테이너 실행·중지·목록 확인 | PASS | `docker ps`, `docker ps -a`, `stop`, `start`를 실제 실행했습니다. [`docker-verification.md`](docker-verification.md) |
| R9 | 로그와 리소스 사용량 확인 | PASS | `docker logs`, `docker stats --no-stream` 결과가 있습니다. [`docker-verification.md`](docker-verification.md) |
| R10 | `hello-world` 실행 성공 | PASS | Docker 공식 확인 메시지를 기록했습니다. [`container-basics.md`](container-basics.md) |
| R11 | Ubuntu 실행과 내부 명령, 전경·분리·`exec` 차이 설명 | PASS | 전경 실행과 백그라운드 실행을 각각 검증하고 `attach`와 `exec`의 차이를 정리했습니다. [`container-basics.md`](container-basics.md) |
| R12 | 기존 베이스를 활용한 커스텀 Dockerfile | PASS | `nginx:1.27.5-alpine`에 콘텐츠·설정·헬스체크·보안 헤더를 추가했습니다. [`Dockerfile`](../../Dockerfile), [`default.conf`](../../nginx/default.conf) |
| R13 | 커스텀 이미지 빌드·실행 명령과 결과 | PASS | 최종 소스로 새 이미지를 빌드하고 격리된 컨테이너를 실행했습니다. [`docker-verification.md`](docker-verification.md) |
| R14 | `-p` 포트 매핑, HTTP 응답, 주소창 포함 브라우저 증거 | PASS | `127.0.0.1:38082` 주소창과 응답 화면, `curl`의 `200`/`ok`를 확인했습니다. [`ui-verification.md`](ui-verification.md) |
| R15 | 바인드 마운트 변경 전·후 | PASS | 이미지 재빌드 없이 `bind-before`가 `bind-after`로 바뀌는 응답을 확인했습니다. [`docker-verification.md`](docker-verification.md) |
| R16 | 이름 있는 볼륨의 컨테이너 삭제 전·후 영속성 | PASS | 첫 컨테이너를 삭제한 뒤 새 컨테이너에서 같은 데이터를 읽었습니다. [`docker-verification.md`](docker-verification.md) |
| R17 | Git 사용자 정보와 기본 브랜치 설정 | PASS | 이름·이메일 설정 여부와 `main` 기본 브랜치를 개인정보 없이 확인했습니다. [`git-github.md`](git-github.md) |
| R18 | GitHub 로그인 및 VS Code 저장소 연동 증거 | PARTIAL | `origin`, `main`, SSH 원격 조회는 확인했습니다. VS Code 로그인 상태가 보이는 개인정보 제거 캡처는 사용자 확인이 남았습니다. [`manual-evidence.md`](manual-evidence.md) |
| R19 | 로그·문서·화면의 민감정보 보호 | PASS | 이메일은 값 대신 설정 여부만 기록했고, 브라우저는 계정 없는 별도 프로필로 캡처했습니다. 정적 민감정보 검사도 최종 검증에 포함합니다. |

## 보너스 구현

`compose.yaml`에는 단일 `web` 서비스, 환경 변수로 바꿀 수 있는 호스트 포트와 이름 있는 볼륨이 정의돼 있습니다. 이 구성은 필수 19개 판정에는 포함하지 않았습니다. 기존 사용자 서비스가 실행 중이므로 최종 감사에서는 `docker compose config`로 구문과 해석 결과만 검사하고 실행 중인 서비스는 변경하지 않았습니다. `backend/`는 기존 실험 파일로 보존했으며 현재 Compose 실행 경로에는 포함하지 않았습니다.

## 제출 전 남은 작업

사용자가 [`manual-evidence.md`](manual-evidence.md)의 두 단계, 즉 VS Code 연동 화면 캡처와 최종 커밋·푸시를 완료하면 R1과 R18을 다시 `PASS`로 바꿀 수 있습니다.
