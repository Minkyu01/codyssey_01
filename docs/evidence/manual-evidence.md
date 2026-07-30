# 사용자 확인이 필요한 마지막 증거

자동 검증으로 계정 화면을 열거나 GitHub 원격 저장소를 변경하지 않았습니다. 아래 두 단계는 제출 직전에 사용자가 직접 수행해야 합니다.

## 1. VS Code와 GitHub 연동 화면

1. VS Code에서 이 프로젝트 폴더를 엽니다.
2. 계정 메뉴에서 GitHub 로그인 상태를 확인합니다.
3. Source Control 화면에서 현재 브랜치가 `main`이고 원격이 `origin`임을 확인합니다.
4. 계정 이메일, 알림 내용, 토큰, 인증 코드, 다른 비공개 저장소 이름이 보이지 않도록 창을 정리합니다.
5. 로그인 상태와 저장소 연동을 확인할 수 있는 화면을 캡처해 `docs/images/`에 저장합니다.
6. 이 문서와 `README.md`에 이미지 링크를 추가합니다.

다음 로컬·원격 연결은 이미 읽기 전용으로 확인했습니다.

```console
$ git branch --show-current
main

$ git remote get-url origin
git@github.com:Minkyu01/codyssey_01.git

$ git ls-remote origin HEAD
906c5717a4becb786208b0f79dd7b000fba218b0    HEAD
```

## 2. 최종 검토, 커밋과 푸시

먼저 자동 검증을 다시 실행합니다.

```bash
./tests/static_check.sh
VERIFY_RUN_ID=submit HOST_PORT=38080 BIND_PORT=38081 ./scripts/verify.sh
git status --short
git diff --check
```

변경 목록에서 개인정보와 의도하지 않은 삭제가 없는지 직접 확인한 뒤 필요한 파일만 스테이징합니다. 특히 현재 작업 트리에는 이번 작업 전부터 있던 변경도 있으므로 `git add .`를 바로 실행하지 말고 파일별로 검토합니다.

```bash
git add <검토를 마친 파일>
git diff --cached
git commit -m "docs: complete ex01 workstation assignment"
git push origin main
```

푸시 후 공개 저장소에서 다음을 확인합니다.

- 루트의 `README.md`가 새 문서로 표시되는가
- README의 문서·이미지 링크가 모두 열리는가
- 주소창 포함 브라우저 이미지에서 포트가 읽히는가
- 토큰, 비밀번호, 이메일, 인증 코드가 노출되지 않았는가
- 제출할 저장소 URL이 `https://github.com/Minkyu01/codyssey_01`인가

## 완료 표시 규칙

VS Code 캡처를 추가하고 최종 커밋을 원격에서 확인한 뒤에만 [`requirements.md`](requirements.md)의 R1과 R18을 `PASS`로 변경합니다.
