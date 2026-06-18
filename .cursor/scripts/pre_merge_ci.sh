#!/usr/bin/env bash
# Pre-merge CI gate for LangChain monorepo PRs (DevOps / release managers).
# PR-level checks (scope, dependencies, CI shape) then delegates package gates to pre_pr.sh.
#
# Usage:
#   .cursor/scripts/pre_merge_ci.sh [options] [package-path] ["type(scope): description"]
#
# Examples:
#   .cursor/scripts/pre_merge_ci.sh libs/partners/anthropic "refactor(anthropic): extract helper"
#   .cursor/scripts/pre_merge_ci.sh --base master libs/partners/anthropic
#   .cursor/scripts/pre_merge_ci.sh --allow-deps --package libs/core "release(core): 1.2.0"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PRE_PR="${SCRIPT_DIR}/pre_pr.sh"

BASE_REF="master"
ALLOW_DEPS=0
ALLOW_INFRA=0
PACKAGE_PATH=""
PR_TITLE=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] [package-path] ["type(scope): description"]

PR-level pre-merge gate: changed-package scope, dependency policy, then pre_pr.sh.

Options:
  --base REF        Base ref for git diff (default: master, or origin/master if present)
  --package PATH    Package path under libs/ (auto-detected from diff if omitted)
  --allow-deps      Allow pyproject.toml / uv.lock changes (release/maintainer PRs)
  --allow-infra     Allow .github/ changes (infra/maintainer PRs)
  -h, --help        Show this help

Examples:
  $(basename "$0") libs/partners/anthropic "feat(anthropic): add helper"
  $(basename "$0") --base origin/master
  $(basename "$0") --allow-deps libs/core "release(core): 1.2.0"
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      BASE_REF="${2:?--base requires a ref}"
      shift 2
      ;;
    --package)
      PACKAGE_PATH="${2:?--package requires a path}"
      shift 2
      ;;
    --allow-deps)
      ALLOW_DEPS=1
      shift
      ;;
    --allow-infra)
      ALLOW_INFRA=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      echo "ERROR: Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      if [[ -z "$PACKAGE_PATH" ]] && [[ -d "${REPO_ROOT}/${1}" || "$1" == libs/* ]]; then
        PACKAGE_PATH="$1"
        shift
      elif [[ -z "$PR_TITLE" ]]; then
        PR_TITLE="$1"
        shift
      else
        echo "ERROR: Unexpected argument: $1"
        usage
        exit 1
      fi
      ;;
  esac
done

cd "$REPO_ROOT"

resolve_base_ref() {
  if git rev-parse --verify "${BASE_REF}" >/dev/null 2>&1; then
    echo "$BASE_REF"
    return
  fi
  if git rev-parse --verify "origin/${BASE_REF}" >/dev/null 2>&1; then
    echo "origin/${BASE_REF}"
    return
  fi
  echo "$BASE_REF"
}

BASE="$(resolve_base_ref)"

if ! git rev-parse --verify "$BASE" >/dev/null 2>&1; then
  echo "ERROR: Base ref not found: $BASE"
  exit 1
fi

mapfile -t CHANGED_FILES < <(git diff --name-only "${BASE}...HEAD" 2>/dev/null || git diff --name-only "${BASE}" HEAD)

if [[ ${#CHANGED_FILES[@]} -eq 0 ]]; then
  echo "WARNING: No changed files vs ${BASE} — using working tree diff"
  mapfile -t CHANGED_FILES < <(git diff --name-only HEAD)
fi

if [[ ${#CHANGED_FILES[@]} -eq 0 ]]; then
  echo "ERROR: No changes detected to review"
  exit 1
fi

echo "=== LangChain pre-merge CI gate ==="
echo "Repo:  $REPO_ROOT"
echo "Base:  $BASE"
echo "Files: ${#CHANGED_FILES[@]} changed"
echo ""

# --- Dependency / lockfile policy ---
DEP_FILES=()
for f in "${CHANGED_FILES[@]}"; do
  if [[ "$f" =~ (^|/)pyproject\.toml$ || "$f" =~ (^|/)uv\.lock$ ]]; then
    DEP_FILES+=("$f")
  fi
done

if [[ ${#DEP_FILES[@]} -gt 0 ]]; then
  if [[ "$ALLOW_DEPS" -eq 1 ]]; then
    echo "--- Dependency files (allowed via --allow-deps) ---"
    printf '  %s\n' "${DEP_FILES[@]}"
  else
    echo "ERROR: Dependency manifest changes not allowed on feature PRs:"
    printf '  %s\n' "${DEP_FILES[@]}"
    echo "Use --allow-deps for release/maintainer PRs, or revert lockfile/pyproject changes."
    exit 1
  fi
else
  echo "--- Dependency policy: OK (no pyproject.toml / uv.lock changes) ---"
fi

# --- Infra / workflow policy ---
INFRA_FILES=()
for f in "${CHANGED_FILES[@]}"; do
  if [[ "$f" == .github/* ]]; then
    INFRA_FILES+=("$f")
  fi
done

if [[ ${#INFRA_FILES[@]} -gt 0 ]]; then
  if [[ "$ALLOW_INFRA" -eq 1 ]]; then
    echo "--- Infra files (allowed via --allow-infra) ---"
    printf '  %s\n' "${INFRA_FILES[@]}"
  else
    echo "ERROR: .github/ changes require --allow-infra (infra/maintainer PRs):"
    printf '  %s\n' "${INFRA_FILES[@]}"
    exit 1
  fi
else
  echo "--- Infra policy: OK (no .github/ changes) ---"
fi

# --- Package scope detection ---
detect_packages() {
  local f pkg
  local -A seen=()
  for f in "${CHANGED_FILES[@]}"; do
    if [[ "$f" =~ ^libs/partners/[^/]+/ ]]; then
      pkg="$(echo "$f" | sed -n 's|^\(libs/partners/[^/]*\)/.*|\1|p')"
      [[ -n "$pkg" ]] && seen["$pkg"]=1
    elif [[ "$f" =~ ^libs/(core|langchain_v1|langchain|text-splitters|standard-tests|model-profiles)/ ]]; then
      pkg="$(echo "$f" | sed -n 's|^\(libs/[^/]*\)/.*|\1|p')"
      [[ -n "$pkg" ]] && seen["$pkg"]=1
    fi
  done
  for pkg in "${!seen[@]}"; do
    echo "$pkg"
  done
}

mapfile -t PACKAGES < <(detect_packages | sort -u)

if [[ -z "$PACKAGE_PATH" ]]; then
  if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    echo ""
    echo "WARNING: No libs/ package detected in diff (docs/infra/.cursor-only change?)"
    echo "Skipping pre_pr.sh — review CI workflows manually."
    echo ""
    echo "=== Pre-merge CI gate passed (no package gate) ==="
    exit 0
  elif [[ ${#PACKAGES[@]} -eq 1 ]]; then
    PACKAGE_PATH="${PACKAGES[0]}"
    echo "--- Package scope: OK (single package: ${PACKAGE_PATH}) ---"
  else
    echo "ERROR: Multiple packages touched — one package per PR is preferred:"
    printf '  %s\n' "${PACKAGES[@]}"
    echo "Pass --package to run gates for one package only, or split the PR."
    exit 1
  fi
else
  echo "--- Package scope: explicit (${PACKAGE_PATH}) ---"
  if [[ ${#PACKAGES[@]} -gt 1 ]]; then
    echo "WARNING: Diff touches multiple packages; gating only ${PACKAGE_PATH}"
  fi
fi

# --- CI workflow hints ---
echo ""
echo "--- Expected CI (see .github/workflows/check_diffs.yml) ---"
echo "  - PR title lint (.github/workflows/pr_lint.yml)"
echo "  - Lint + unit tests for changed package(s)"
if [[ ${#DEP_FILES[@]} -gt 0 ]] && [[ "$ALLOW_DEPS" -eq 1 ]]; then
  echo "  - check_release_deps.yml (release PRs with pyproject.toml changes)"
  echo "  - check_versions.yml"
fi
echo ""

# --- Delegate to package gate ---
if [[ ! -x "$PRE_PR" ]]; then
  echo "ERROR: pre_pr.sh not found or not executable: $PRE_PR"
  exit 1
fi

"$PRE_PR" "$PACKAGE_PATH" "$PR_TITLE"

echo ""
echo "=== Pre-merge CI gate passed ==="
