# 신입 개발자 온보딩 가이드 — 감리 품질 게이트 따라하기

> 처음 합류한 개발자가 **이 문서 하나만 위에서 아래로 따라하면** 산출물 작성 → 로컬 점검 → PR → CI 게이트 통과 → 머지까지 전 과정을 직접 경험할 수 있습니다.
> 예상 소요시간: **30~40분** (실습 포함)

---

## 0. 이 프로젝트가 하는 일 (1분 요약)

우리는 NIA 감리점검해설서 V3.0(응용시스템) 기준으로 단계별 개발 산출물을 작성합니다.
**감리 제출 전에 사람이 일일이 체크리스트를 돌리지 않도록**, 자동 점검 게이트를 붙여 두었습니다.

```
산출물 작성 ──► [로컬 점검 pre-submit.sh] ──► PR 생성 ──► [CI 게이트 audit-gate.yml] ──► 머지 ──► 감리 제출
                     │                                        │
                     └─ 산출물 누락 · 키워드 누락 · 금지토큰(TBD) · 추적성 단절을 자동 탐지 ─┘
```

핵심 규칙 **딱 하나만 기억하세요**:
> **`audit` 점검을 통과하지 못하면 master에 머지할 수 없습니다.** (브랜치 보호 활성화됨)

---

## 1. 사전 준비 (최초 1회)

### 1-1. 필요한 도구
| 도구 | 용도 | 확인 명령 |
|------|------|-----------|
| Git | 버전관리 | `git --version` |
| Python 3.9+ | 점검 엔진 실행 | `python --version` |
| GitHub 계정 | PR 생성 (협업자 권한 필요) | — |
| (선택) gh CLI | 터미널에서 PR 관리 | `gh --version` |

### 1-2. 리포지토리 클론 & 의존성 설치
```bash
git clone https://github.com/junhansong/audit-quality-gate.git
cd audit-quality-gate

pip install -r requirements.txt   # pyyaml, python-docx, pdfplumber, openpyxl
```

### 1-3. 한 번 돌려보기 (모든 게 정상인지 확인)
```bash
python audit_engine.py --rules rules/audit_rules.yaml
```
화면 맨 아래가 `PASS` 면 환경 준비 완료입니다. `audit_report.md` 파일이 생성된 것도 확인해 보세요.

---

## 2. 폴더 구조 한눈에 보기

```
audit-quality-gate/
├─ ONBOARDING.md              ← (지금 이 문서)
├─ README.md                  ← 시스템 전체 설명
├─ audit_engine.py            ← 점검 엔진 (직접 수정할 일은 거의 없음)
├─ rules/audit_rules.yaml     ← 점검 룰셋 (감리코드 매핑. 룰 추가 시 여기만 수정)
├─ scripts/pre-submit.sh      ← 로컬 통합 점검 루프
├─ deliverables/              ← ★ 여러분이 작업하는 곳 ★
│  ├─ 01_요구분석/
│  ├─ 02_분석설계/
│  ├─ 03_구현/src/            ← 실제 소스코드
│  ├─ 04_시험활동/
│  ├─ 05_운영준비/
│  └─ RTM.csv                ← 요구사항 추적 매트릭스
├─ docs/감리_대비_산출물_체크리스트.md  ← 작성기준/점검항목 상세
└─ .github/workflows/audit-gate.yml    ← CI 게이트 (자동 실행)
```

> **여러분이 손대는 곳은 거의 항상 `deliverables/` 안입니다.** 엔진·룰셋은 룰을 새로 만들 때만 건드립니다.

---

## 3. 점검이 잡아내는 4가지 (무엇을 통과해야 하나)

| 점검 유형 | 의미 | 실패 예시 |
|-----------|------|-----------|
| **존재(exists)** | 단계별 필수 산출물이 실제로 있는가 | `비전기술서.md`가 없음 |
| **내용(contains)** | 감리 검토항목이 요구하는 핵심 키워드 포함 여부 | 연계설계서에 `연계 주기` 항목 누락 |
| **형식(not_contains)** | 금지 토큰이 없는가 | 문서에 `TBD`, `미정`, `추후작성` 잔존 |
| **추적성(traceability)** | 요구사항→유스케이스→클래스→코드→시험 추적이 끊기지 않았는가 | `RTM.csv`에서 REQ-002의 시험 ID 누락 |

공통 형식 규칙(`common_checks`):
- 모든 문서에 **`개정이력`, `목차` 섹션 필수**
- 금지 토큰: `TBD`, `T.B.D`, `미정`, `추후작성`, `작성예정`, `XXX`, `???`

---

## 4. 일상 작업 흐름 (매번 이렇게)

```bash
# 1) 최신 master 받기
git checkout master
git pull

# 2) 작업 브랜치 생성 (규칙: feature/<단계>-<내용>)
git checkout -b feature/sd22-연계설계서-보완

# 3) deliverables/ 안에서 산출물 작성·수정
#    (예: deliverables/02_분석설계/내외부시스템연계설계서.md)

# 4) ★ 커밋 전 로컬 점검 (가장 중요) ★
bash scripts/pre-submit.sh
#    특정 단계만 빠르게: bash scripts/pre-submit.sh SD22-2

# 5) 통과(✅)하면 커밋·푸시
git add .
git commit -m "docs(sd22): 연계설계서 연계 주기/방식 항목 보완"
git push -u origin feature/sd22-연계설계서-보완

# 6) PR 생성 (gh CLI 또는 GitHub 웹)
gh pr create --base master --fill
#    → CI 게이트(audit)가 자동 실행, 결과가 PR에 코멘트로 달림

# 7) audit 체크 ✅ + 리뷰 후 → master 머지
```

> **로컬에서 `pre-submit.sh`를 먼저 돌리는 습관**을 들이면, PR에서 빨간불(❌) 보는 일이 거의 없어집니다.

---

## 5. 🧪 실습: 일부러 실패시켜 보고, 고쳐서 통과시키기

> 실제로 게이트가 어떻게 막아주는지 손으로 체험하는 코너입니다. **꼭 직접 해보세요.**

### STEP 1 — 실습 브랜치 만들기
```bash
git checkout master && git pull
git checkout -b practice/onboarding-나의이름
```

### STEP 2 — 일부러 결함 심기 (금지 토큰 + 키워드 삭제)
`deliverables/02_분석설계/내외부시스템연계설계서.md` 파일을 열어서:
1. 아무 곳에나 `TBD` 라고 한 줄 추가
2. 본문에서 `연계 주기` 라는 단어를 찾아 지우거나 다른 말로 바꾸기

### STEP 3 — 로컬 점검 → 실패 확인 ❌
```bash
python audit_engine.py --rules rules/audit_rules.yaml --phase SD22-2
```
이렇게 두 군데서 실패가 떠야 정상입니다:
```
[FAIL] 형식점검: 금지 토큰 'TBD' 발견 → 내외부시스템연계설계서.md
[FAIL] SD22-2-F1 내외부 연계 설계: 필수 키워드 '연계 주기' 누락
...
종료코드 1
```
👉 게이트가 **여러분 대신 감리 지적사항을 미리 잡아낸 것**입니다.

### STEP 4 — (선택) PR에서도 막히는지 보기
그대로 커밋·푸시하고 PR을 만들면, **`audit` 체크가 빨간불(❌)** 이 되고 머지 버튼이 잠깁니다.
PR 하단 코멘트에 어떤 항목이 실패했는지 리포트가 자동으로 달립니다.

### STEP 5 — 결함 수정 → 통과 ✅
1. 추가했던 `TBD` 줄 삭제
2. `연계 주기` 키워드 원복 (`연계 대상`, `연계 주기`, `연계 방식` 세 항목이 모두 있어야 `SD22-2-F1` 통과)
3. 다시 점검:
```bash
python audit_engine.py --rules rules/audit_rules.yaml --phase SD22-2
```
맨 아래 `PASS` 가 뜨면 성공입니다. PR을 다시 푸시하면 `audit` 체크가 초록불(✅)로 바뀝니다.

### STEP 6 — 실습 정리
```bash
git checkout master
git branch -D practice/onboarding-나의이름     # 로컬 실습 브랜치 삭제
# (푸시했었다면) git push origin --delete practice/onboarding-나의이름
```

🎉 **여기까지 했다면 온보딩 완료입니다.** 게이트가 어떻게 작동하고, 무엇을 보고 고쳐야 하는지 체득했습니다.

---

## 6. 자주 막히는 곳 (FAQ)

**Q. `pre-submit.sh` 실행이 안 돼요 (Permission denied)**
→ `bash scripts/pre-submit.sh` 처럼 `bash`를 앞에 붙이거나, 한 번 `chmod +x scripts/pre-submit.sh`.

**Q. master에 직접 push가 거부돼요.**
→ 정상입니다. master는 보호되어 있어 **반드시 PR을 통해** 들어가야 합니다. 작업 브랜치에서 PR을 만드세요.

**Q. 산출물을 새로 추가했는데 "존재하지 않음"으로 떠요.**
→ 파일명이 룰셋의 `pattern`과 맞는지 확인하세요. 예: 연계설계서는 파일명에 `연계설계`가 들어가야 매칭됩니다 (`rules/audit_rules.yaml`에서 해당 단계 `pattern` 확인).

**Q. `python-docx`/`pdfplumber` 관련 에러가 나요.**
→ `pip install -r requirements.txt` 를 다시 실행하세요. `.docx`/`.pdf`/`.xlsx` 내용 점검에 필요합니다.

**Q. 새로운 점검 항목을 추가하고 싶어요.**
→ `rules/audit_rules.yaml`만 수정하면 됩니다. 엔진 코드는 건드릴 필요 없습니다. 변경 후 반드시 로컬 점검으로 룰이 의도대로 도는지 확인하고 PR을 올리세요.

**Q. RTM(요구사항추적표)는 언제 갱신하나요?**
→ 새 요구사항(REQ)·유스케이스(UC)·클래스(CLS)·컴포넌트(CMP)·시험(UT/UAT)을 만들 때마다 `deliverables/RTM.csv`에 해당 행을 채워야 추적성 점검을 통과합니다.

---

## 7. 단계별 산출물 & 감리코드 빠른 참조

| 단계 | 폴더 | 주요 산출물 | 대표 감리코드 |
|------|------|-------------|----------------|
| 요구분석 | `01_요구분석/` | 비전기술서, 사용자요구사항정의서, 유스케이스/클래스모형, UI프로토타이핑계획서 | SD21-2 |
| 분석설계 | `02_분석설계/` | 업무상세분석서, 클래스명세서, 연계설계서, 컴포넌트설계서, 보안정책문서, 단위시험계획서 | SD22-2 |
| 구현 | `03_구현/` | 컴포넌트코드(src/), 단위시험결과서, 통합시험계획서 | SD23-2 |
| 시험활동 | `04_시험활동/` | 시험계획서, 통합/시스템시험결과서, 결함관리대장, 사용자·운영자지침서, 인수시험계획서 | SD14-1 |
| 운영준비 | `05_운영준비/` | 전환계획/결과서, 데이터전환계획/결과서, 인수시험계획/결과서, 요구사항추적표 | SD15-1 |

> 각 산출물의 상세 작성기준·점검항목은 [`docs/감리_대비_산출물_체크리스트.md`](docs/감리_대비_산출물_체크리스트.md) 를 참고하세요.

---

## 8. 다음 단계 & 도움
- ✅ 실습을 끝냈다면 → **[신입 첫 과제 (docs/신입_첫과제.md)](docs/신입_첫과제.md)** 로 실제 PR을 머지해 보세요
- 📄 한 페이지 요약: [빠른 참조 치트시트 (docs/빠른참조_치트시트.md)](docs/빠른참조_치트시트.md)
- 시스템 전체 설명: [`README.md`](README.md)
- 점검 룰 정의: [`rules/audit_rules.yaml`](rules/audit_rules.yaml)
- 실패 리포트 해석: 점검 후 생성되는 `audit_report.md`

환영합니다. 첫 PR을 기다리겠습니다. 🚀
