---
name: review-before-pr
description: Run a pre-review quality pass on LangChain changes before opening a PR — conventions, tests, deprecated APIs, and hard gates.
disable-model-invocation: true
metadata:
  recommended-model: claude-sonnet
  alternate-model: claude-opus
  role: qa
---

# Review before opening a PR

Run a pre-review quality pass on the current changes before human code review. Intended for engineers and QA.

## Model

**Use Claude Sonnet** (or **Opus** for high-risk or public API changes).

**Cross-model rule:** This skill must run on a **different model** than `/scaffold-contribution` (which uses Composer). The reviewer independently re-reads the diff, challenges test adequacy, and re-runs gates — code written by one model, verified by another.

If this session also authored the code, stop and ask the user to start a **new chat on Sonnet/Opus** before continuing.

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

Cursor's default agent sandbox **cannot access the Docker daemon**, even when Docker works in your WSL terminal. For packages that use Docker in `make test` (notably `libs/langchain_v1`), you **must** run the gate script with **unrestricted permissions** so Docker can start Postgres/Redis.

When using the terminal/shell tool:

1. Run `pre_pr.sh` with **full/unrestricted permissions** (disable sandbox).
2. If unrestricted access is denied or Docker is still unavailable, re-run with `--fast` or accept the script's automatic fallback to `make test_fast`.

```bash
.cursor/scripts/pre_pr.sh <package-path> "<proposed-pr-title>"
```

For `libs/langchain_v1` only:

- **Preferred:** unrestricted run → full `make test` (Docker)
- **Fallback:** `--fast` or auto-fallback → `make test_fast` (in-memory services)

Partner packages and most other paths do not need Docker.

Record pass/fail for each gate. If multiple packages were touched, run once per package or note that the PR should be split.

Parse the script header line `Tests: make test (...)` vs `Tests: make test_fast (...)` for the report.

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
- make test (Docker): PASS/FAIL/SKIPPED — full Postgres/Redis suite; SKIPPED if auto-fallback to test_fast
- make test_fast: PASS/FAIL/N/A — ran when Docker unavailable or `--fast`
- PR title: PASS/FAIL/N/A

Note when Docker-backed tests were skipped: recommend the author run full `pre_pr.sh` locally or rely on CI.

## Blockers (must fix before PR)
1. ...

## Suggestions (non-blocking)
1. ...

## Deprecated API / anti-pattern findings
- ...
```

Be honest about uncertainty: if you cannot verify something, say how you would verify it.
