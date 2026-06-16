#!/usr/bin/env bash
# Pre-PR gate for LangChain monorepo packages.
# Mirrors CI expectations: format, lint, unit tests, optional PR title lint.
#
# Usage:
#   .cursor/scripts/pre_pr.sh <package-path> ["type(scope): description"]
#
# Examples:
#   .cursor/scripts/pre_pr.sh libs/partners/anthropic
#   .cursor/scripts/pre_pr.sh libs/partners/anthropic "feat(anthropic): add retry helper"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PACKAGE_PATH="${1:-}"
PR_TITLE="${2:-}"

ALLOWED_TYPES="feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|release|hotfix"
ALLOWED_SCOPES="core|langchain|langchain-classic|model-profiles|standard-tests|text-splitters|docs|anthropic|chroma|deepseek|exa|fireworks|groq|huggingface|mistralai|nomic|ollama|openai|openrouter|perplexity|qdrant|xai|infra|deps|partners"

usage() {
  cat <<EOF
Usage: $(basename "$0") <package-path> ["type(scope): description"]

Run format, lint, and unit tests for a LangChain monorepo package.
Optionally validate a Conventional Commit PR title (see .github/workflows/pr_lint.yml).

Examples:
  $(basename "$0") libs/partners/anthropic
  $(basename "$0") libs/core "fix(core): resolve type hint issue"
EOF
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

if [[ -z "$PACKAGE_PATH" ]] || [[ "$PACKAGE_PATH" == "-h" ]] || [[ "$PACKAGE_PATH" == "--help" ]]; then
  usage
  exit 0
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

echo "=== LangChain pre-PR gate ==="
echo "Repo:    $REPO_ROOT"
echo "Package: $PACKAGE_DIR"
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
echo "--- make test ---"
make test

echo ""
if [[ -n "$PR_TITLE" ]]; then
  echo "--- PR title validation ---"
  validate_pr_title "$PR_TITLE"
fi

echo ""
echo "=== Pre-PR gate passed ==="
