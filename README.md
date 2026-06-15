# 응용시스템 감리 자동 점검 워크플로우 (Quality Engineering)

NIA 감리점검해설서 V3.0(SD/응용시스템) 기반으로, **단계별 개발 산출물을 감리 제출 전 자동으로 점검**하는 품질 게이트 시스템입니다.

> 🆕 **처음 합류하셨나요?** 산출물 작성 → 로컬 점검 → PR → CI 통과까지 직접 따라하는 [신입 개발자 온보딩 가이드 (ONBOARDING.md)](ONBOARDING.md)부터 보세요 (실습 포함, 30~40분).

## 무엇을 하나

```
산출물 작성 ──► [로컬 점검: pre-submit.sh] ──► 커밋/PR ──► [CI 게이트: audit-gate.yml] ──► 머지/감리 제출
                      │                                          │
                      └── 산출물 누락·키워드 누락·금지토큰(TBD)·요구사항 추적성 단절 자동 탐지 ──┘
```

- **산출물 존재 점검**: 단계별 필수 산출물(`audit_rules.yaml`)이 실제로 있는지
- **내용 점검**: 각 검토항목(예: `SD22-2-F1`)이 요구하는 핵심 키워드 포함 여부
- **형식 점검**: TBD/미정/공란 등 금지 토큰, 개정이력·목차 등 필수 섹션
- **추적성 점검**: `RTM.csv`로 요구사항→유스케이스→클래스→코드→시험 추적 단절 탐지
- **코드 품질 연계**: Lint / 단위테스트 / 커버리지 결과를 게이트에 통합

## 구성

| 파일 | 역할 |
|------|------|
| `rules/audit_rules.yaml` | 단계별 산출물·점검 룰셋 (감리코드 1:1 매핑, **여기만 수정하면 룰 확장**) |
| `audit_engine.py` | 룰셋 실행 엔진 → `audit_report.md` / `.json` 생성, 결함 시 exit 1 |
| `scripts/pre-submit.sh` | 로컬 통합 점검 루프 (산출물+Lint+테스트) |
| `.github/workflows/audit-gate.yml` | PR/푸시 시 자동 점검, PR 코멘트, 머지 차단 |
| `deliverables/` | 산출물 루트 (단계별 폴더 `01_요구분석` ~ `05_운영준비`) |
| `deliverables/RTM.csv` | 요구사항 추적 매트릭스 |

## 빠른 시작

```bash
pip install pyyaml python-docx pdfplumber openpyxl   # docx/pdf/xlsx 내용 점검 시

# 전체 점검
python audit_engine.py --rules rules/audit_rules.yaml

# 특정 단계만
python audit_engine.py --rules rules/audit_rules.yaml --phase SD22-2

# 제출 직전 통합 게이트 (산출물+Lint+테스트)
bash scripts/pre-submit.sh
```

## 산출물 폴더 규칙

룰셋의 `pattern`과 매칭되도록 파일을 배치합니다(포맷: md/docx/hwp/pdf/xlsx 지원).

```
deliverables/
├── 01_요구분석/        비전기술서, 사용자요구사항정의서, 유스케이스모형기술서 ...
├── 02_분석설계/        업무상세분석서, 클래스명세서, 컴포넌트설계서, 단위시험계획서 ...
├── 03_구현/src/        컴포넌트 코드 (js/ts/py/java)
├── 04_시험활동/        시험계획서, 통합/시스템시험결과서, 운영자지침서 ...
├── 05_운영준비/        전환계획/결과서, 인수시험결과서, 요구사항추적표 ...
└── RTM.csv             요구사항 추적 매트릭스
```

## RTM.csv 형식

```csv
REQ_ID,UC_ID,CLS_ID,CMP_ID,UT_ID,UAT_ID
REQ-001,UC-01,CLS-01,CMP-01,UT-01,UAT-01
```
하나라도 비어 있으면 "추적성 단절"로 결함 처리됩니다.

## 룰 확장 방법

`audit_rules.yaml`의 `checks`에 한 줄 추가하면 새 점검이 생깁니다. 코드 수정 불필요.

```yaml
- { code: "SD22-2-NEW", type: contains, target: D5,
    keywords: ["트랜잭션", "동시성"], desc: "동시성 설계 명시 여부" }
```

지원 타입: `exists` · `contains` · `not_contains` · `min_count` · `traceability`

## 품질 엔지니어링(QE) 운영 권장 루프

1. **단계 착수 시** 해당 단계 룰을 `--phase`로 돌려 산출물 골격(템플릿) 확보
2. **작성 중** 로컬에서 `pre-submit.sh <단계>`를 수시 실행해 결함을 조기 해소
3. **PR 시** CI가 자동 점검 + PR 코멘트로 결함 가시화 → 통과해야 머지
4. **감리 제출 직전** `workflow_dispatch`로 전체 최종 점검 → `audit_report.md`를 감리 증빙으로 첨부
5. **회고** 감리 지적사항을 룰셋에 반영 → 다음 사업에서 재발 방지(지식 복리)
