# Git·GitHub 연동 검증

2026년 7월 30일에 로컬 저장소와 읽기 전용 원격 연결을 확인했습니다. 커밋·푸시와 계정 로그인은 외부 상태를 바꾸므로 자동으로 수행하지 않았습니다.

## 로컬 설정

```console
$ git branch --show-current
main

$ git config --get init.defaultBranch
main

$ git config --get user.name >/dev/null && echo 'user.name=configured'
user.name=configured

$ git config --get user.email >/dev/null && echo 'user.email=configured (value redacted)'
user.email=configured (value redacted)
```

Git 사용자 이름과 이메일은 설정돼 있습니다. 이메일은 문서에 노출하지 않았습니다.

## 원격 저장소

```console
$ git remote get-url origin
git@github.com:Minkyu01/codyssey_01.git

$ git ls-remote origin HEAD
906c5717a4becb786208b0f79dd7b000fba218b0    HEAD
```

읽기 전용 SSH 조회가 성공했습니다. 원격 저장소 [Minkyu01/codyssey_01](https://github.com/Minkyu01/codyssey_01)은 공개 상태이며 기본 브랜치는 `main`입니다.

Git은 로컬 파일의 변경 이력, 브랜치, 커밋을 관리합니다. GitHub은 Git 저장소를 원격에서 공유하고 협업하는 플랫폼입니다. `git commit`은 로컬 이력만 바꾸고, `git push`를 실행해야 GitHub에 새 커밋이 반영됩니다.

## 아직 필요한 사용자 증거

- [ ] VS Code의 계정 메뉴에서 GitHub 로그인 상태를 확인합니다.
- [ ] VS Code가 이 프로젝트의 `main` 브랜치와 `origin`을 인식하는 화면을 캡처합니다.
- [ ] 이메일, 알림, 토큰, 인증 코드가 보이지 않게 캡처합니다.
- [ ] 최종 문서를 검토한 뒤 사용자가 커밋하고 `origin/main`으로 푸시합니다.
- [ ] GitHub에서 새 `README.md`와 `docs/` 링크가 열리는지 확인합니다.

로그인 화면과 최종 푸시는 사용자 계정 상태와 외부 저장소를 변경하거나 노출할 수 있으므로 이번 자동 검증의 완료 항목으로 표시하지 않습니다.

