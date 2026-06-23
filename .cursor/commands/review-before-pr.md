# Review before opening a PR

Run a pre-review quality pass on the current changes before human code review. Intended for engineers and QA.

## Model

**Claude Sonnet** or **Opus** — must be a **different model** than `/scaffold-contribution` (Composer). Cross-model review: code written by one model, verified by another.

## Scope

Review only files changed in the working tree or branch diff. Stay inside this monorepo.

## Step 1 — Gather context

```bash
git status
git diff
git diff --name-only master...HEAD   # if on a feature branch
```

Identify which package(s) were touched and the Conventional Commit scope.

## Step 2 — Convention checklist

Check each item; mark PASS, FAIL, or N/A with a one-line note.

### Code quality

- [ ] Type hints and return types on all new/changed functions
- [ ] Google-style docstrings on public functions (types in signatures, not docstrings)
- [ ] American English spelling
- [ ] No bare `except:`; error messages use a `msg` variable
- [ ] No `eval()`, `exec()`, or `pickle` on user-controlled input
- [ ] No commented-out or unreachable code left behind
- [ ] Functions >20 lines split where appropriate

### Public API

- [ ] No breaking changes to exported signatures in `__init__.py`
- [ ] New parameters are keyword-only (`*, param=...`)
- [ ] New exports added to `__all__` if public

### Deprecated APIs and anti-patterns

- [ ] No use of deprecated LangChain APIs (search repo/tests for replacements)
- [ ] No direct `pip`/`poetry`/`conda` usage — `uv` only
- [ ] No unauthorized `pyproject.toml` or `uv.lock` changes
- [ ] Patterns match sibling modules in the same package

### Tests

- [ ] Every new feature/bugfix has unit test coverage
- [ ] Unit tests in `tests/unit_tests/` with no network calls
- [ ] Test file structure mirrors source structure
- [ ] Happy path, edge cases, and errors covered
- [ ] Tests are deterministic (no flaky patterns)
- [ ] Integration tests only where network behavior is explicitly required

### Git / PR hygiene

- [ ] Branch name: `<user>/<scope>/<kebab-description>`
- [ ] PR title matches Conventional Commits (`type(scope): description`)
- [ ] Scope is valid per `.github/workflows/pr_lint.yml`
- [ ] PR description has no `# Summary` header; includes AI disclaimer
- [ ] PR touches one package when possible

## Step 3 — Run hard gates

Delegate to the package pre-PR script (do not duplicate make targets).

### Run outside the Cursor agent sandbox

Cursor's default agent sandbox **cannot access the Docker daemon**. Run `pre_pr.sh` with **unrestricted permissions** when reviewing `libs/langchain_v1` (Docker-backed `make test`). If Docker is unavailable, the script auto-falls back to `make test_fast` unless `--require-docker` is set.

```bash
.cursor/scripts/pre_pr.sh <package-path> "<proposed-pr-title>"
.cursor/scripts/pre_pr.sh --fast libs/langchain_v1 "<title>"   # explicit fast path
```

Record pass/fail. Parse the script's `Tests: make test (...)` line for the report.

## Step 4 — Produce the pre-review report

Output a structured report:

```markdown
# Pre-review report

**Package(s):** ...
**Proposed PR title:** ...

## Summary
<1-2 sentence overall assessment: ready / needs work / blocked>

## Checklist
| Check | Status | Notes |
|-------|--------|-------|
| ... | PASS/FAIL/N/A | ... |

## Hard gates
- make format: PASS/FAIL
- make lint: PASS/FAIL
- make test (Docker): PASS/FAIL/SKIPPED
- make test_fast: PASS/FAIL/N/A
- PR title: PASS/FAIL/N/A

## Blockers (must fix before PR)
1. ...

## Suggestions (non-blocking)
1. ...

## Deprecated API / anti-pattern findings
- ...
```

Be honest about uncertainty: if you cannot verify something, say how you would verify it.
