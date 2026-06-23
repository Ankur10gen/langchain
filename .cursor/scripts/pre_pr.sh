#!/usr/bin/env bash
# Pre-PR gate for LangChain monorepo packages.
# Mirrors CI expectations: format, lint, unit tests, optional PR title lint.
#
# Usage:
#   .cursor/scripts/pre_pr.sh [options] <package-path> ["type(scope): description"]
#
# Options:
#   --fast            Use make test_fast (skip Docker services; langchain_v1 only)
#   --require-docker  Fail if Docker is required but the daemon is unavailable
#
# Examples:
#   .cursor/scripts/pre_pr.sh libs/partners/anthropic
#   .cursor/scripts/pre_pr.sh libs/langchain_v1 "fix(langchain): shell marker parsing"
#   .cursor/scripts/pre_pr.sh --fast libs/langchain_v1

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PACKAGE_PATH=""
PR_TITLE=""
FORCE_FAST=false
REQUIRE_DOCKER=false
TEST_TARGET="make test"
TEST_NOTE=""

ALLOWED_TYPES="feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|release|hotfix"
ALLOWED_SCOPES="core|langchain|langchain-classic|model-profiles|standard-tests|text-splitters|docs|anthropic|chroma|deepseek|exa|fireworks|groq|huggingface|mistralai|nomic|ollama|openai|openrouter|perplexity|qdrant|xai|infra|deps|partners"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] <package-path> ["type(scope): description"]

Run format, lint, and unit tests for a LangChain monorepo package.
Optionally validate a Conventional Commit PR title (see .github/workflows/pr_lint.yml).

Options:
  --fast            Use make test_fast instead of make test (skips Docker services)
  --require-docker  Exit with error when Docker is required but unavailable

Packages such as libs/langchain_v1 start Postgres/Redis via Docker for make test.
When Docker is unavailable (for example in the Cursor agent sandbox), this script
automatically falls back to make test_fast unless --require-docker is set.

Examples:
  $(basename "$0") libs/partners/anthropic
  $(basename "$0") libs/core "fix(core): resolve type hint issue"
  $(basename "$0") libs/langchain_v1 "fix(langchain): shell marker parsing"
  $(basename "$0") --fast libs/langchain_v1
EOF
}

docker_available() {
  command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1
}

package_uses_docker_for_tests() {
  [[ -f "$PACKAGE_DIR/Makefile" ]] && grep -q 'docker compose' "$PACKAGE_DIR/Makefile"
}

select_test_target() {
  if ! package_uses_docker_for_tests; then
    TEST_TARGET="make test"
    TEST_NOTE="standard unit tests"
    return 0
  fi

  if [[ "$FORCE_FAST" == "true" ]]; then
    TEST_TARGET="make test_fast"
    TEST_NOTE="in-memory services (--fast)"
    return 0
  fi

  if docker_available; then
    TEST_TARGET="make test"
    TEST_NOTE="Docker-backed services (Postgres/Redis)"
    return 0
  fi

  if [[ "$REQUIRE_DOCKER" == "true" ]]; then
    echo "ERROR: Docker is required for make test in $PACKAGE_PATH but the daemon is unavailable."
    echo "  - Run this script in a normal terminal with Docker Desktop (WSL integration enabled), or"
    echo "  - Re-run from Cursor Agent with unrestricted permissions, or"
    echo "  - Use --fast to run make test_fast (in-memory services only)."
    return 1
  fi

  TEST_TARGET="make test_fast"
  TEST_NOTE="in-memory services (Docker unavailable — auto fallback)"
  echo "WARNING: Docker daemon unavailable; falling back to make test_fast."
  echo "NOTE: Full make test with Postgres/Redis was not run. Verify locally or rely on CI."
  echo ""
}

validate_pr_title() {
  local title="$1"

  if [[ -z "$title" ]]; then
    return 0
  fi

  # Reject empty scope: type(): description
  if [[ "$title" =~ ^[a-z]+\(\)[!]?: ]]; then
    echo "ERROR: PR title has empty scope: '$title'"
    echo "Provide a scope, e.g. fix(core): ..."
    return 1
  fi

  # type(scope): description  OR  type!: description  OR  type(scope)!: description
  local pattern="^(${ALLOWED_TYPES})(\\(((${ALLOWED_SCOPES})(,(${ALLOWED_SCOPES}))*\\))?!?)?: .+"
  if [[ ! "$title" =~ $pattern ]]; then
    echo "ERROR: PR title does not match Conventional Commits format."
    echo "  Got:      '$title'"
    echo "  Expected: type(scope): description"
    echo "  Allowed types:  ${ALLOWED_TYPES//|/, }"
    echo "  Allowed scopes: ${ALLOWED_SCOPES//|/, }"
    echo "  See: .github/workflows/pr_lint.yml"
    return 1
  fi

  echo "PR title format: OK — '$title'"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fast)
      FORCE_FAST=true
      shift
      ;;
    --require-docker)
      REQUIRE_DOCKER=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "ERROR: Unknown option: $1"
      usage
      exit 1
      ;;
    *)
      if [[ -z "$PACKAGE_PATH" ]]; then
        PACKAGE_PATH="$1"
      elif [[ -z "$PR_TITLE" ]]; then
        PR_TITLE="$1"
      else
        echo "ERROR: Unexpected argument: $1"
        usage
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$PACKAGE_PATH" ]]; then
  usage
  exit 1
fi

# Resolve package path relative to repo root
if [[ "$PACKAGE_PATH" != /* ]]; then
  PACKAGE_DIR="${REPO_ROOT}/${PACKAGE_PATH}"
else
  PACKAGE_DIR="$PACKAGE_PATH"
fi

if [[ ! -d "$PACKAGE_DIR" ]]; then
  echo "ERROR: Package directory not found: $PACKAGE_DIR"
  exit 1
fi

if [[ ! -f "$PACKAGE_DIR/Makefile" ]]; then
  echo "ERROR: No Makefile in $PACKAGE_DIR — is this a LangChain package directory?"
  exit 1
fi

select_test_target

echo "=== LangChain pre-PR gate ==="
echo "Repo:    $REPO_ROOT"
echo "Package: $PACKAGE_DIR"
echo "Tests:   $TEST_TARGET ($TEST_NOTE)"
echo ""

cd "$PACKAGE_DIR"

echo "--- uv sync (test group) ---"
if command -v uv >/dev/null 2>&1; then
  uv sync --group test
else
  echo "WARNING: uv not found; skipping uv sync (ensure deps are installed)"
fi

echo ""
echo "--- make format ---"
make format

echo ""
echo "--- make lint ---"
make lint

echo ""
echo "--- $TEST_TARGET ---"
$TEST_TARGET

echo ""
if [[ -n "$PR_TITLE" ]]; then
  echo "--- PR title validation ---"
  validate_pr_title "$PR_TITLE"
fi

echo ""
echo "=== Pre-PR gate passed ==="
