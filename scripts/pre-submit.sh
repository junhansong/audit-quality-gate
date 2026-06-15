#!/usr/bin/env bash
# =====================================================================
# 감리 제출 전 로컬 자동 점검 루프 (Pre-Submit Quality Gate)
# 개발자가 산출물 제출/커밋 직전 로컬에서 한 번에 돌리는 통합 게이트.
#
#   1) 산출물/문서 점검  (audit_engine.py)
#   2) 코드 정적분석     (ESLint / Ruff 등 — 존재 시)
#   3) 단위 테스트+커버리지 (npm test / pytest — 존재 시)
#   4) 결과 요약 → 하나라도 실패하면 종료코드 1
# =====================================================================
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
FAIL=0
PHASE="${1:-}"   # 인자로 단계 지정 가능 (예: ./pre-submit.sh SD22-2)

echo "════════════════════════════════════════════════════"
echo "  감리 제출 전 자동 점검 루프 시작"
echo "════════════════════════════════════════════════════"

# --- 1) 산출물 감리 점검 ---
echo "▶ [1/4] 산출물 감리 점검"
if [ -n "$PHASE" ]; then
  python audit_engine.py --rules rules/audit_rules.yaml --phase "$PHASE" || FAIL=1
else
  python audit_engine.py --rules rules/audit_rules.yaml || FAIL=1
fi

# --- 2) 코드 정적분석 ---
echo "▶ [2/4] 코드 정적분석(Lint)"
if [ -f package.json ] && grep -q '"lint"' package.json; then
  npm run lint || FAIL=1
elif command -v ruff >/dev/null 2>&1 && [ -d deliverables/03_구현/src ]; then
  ruff check deliverables/03_구현/src || FAIL=1
else
  echo "  (lint 도구 미구성 — 건너뜀)"
fi

# --- 3) 단위 테스트 + 커버리지 ---
echo "▶ [3/4] 단위 테스트 / 커버리지"
if [ -f package.json ] && grep -q '"test"' package.json; then
  npm test || FAIL=1
elif command -v pytest >/dev/null 2>&1; then
  pytest -q || FAIL=1
else
  echo "  (test 도구 미구성 — 건너뜀)"
fi

# --- 4) 요약 ---
echo "▶ [4/4] 결과 요약"
if [ "$FAIL" -eq 0 ]; then
  echo "  ✅ 모든 점검 통과 — 감리 제출 가능"
else
  echo "  ❌ 점검 실패 항목 존재 — audit_report.md 확인 후 보완 필요"
fi
echo "════════════════════════════════════════════════════"
exit $FAIL
