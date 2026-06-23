# Scaffold a LangChain contribution

Guide a new engineer through a correct, convention-compliant first contribution in this monorepo.

## Model

**Composer** — implementation and initial tests. Hand off to **Sonnet/Opus** + `/review-before-pr` in a new chat for cross-model verification.

## Before you start

1. Read `AGENTS.md` at the repo root (source of truth for conventions).
2. **Load a contribution plan** from `.cursor/plans/` (see below) unless the user gives a different task inline.
3. Use the docs MCP servers from `.cursor/mcp.json` (`docs-langchain`, `reference-langchain`) when you need API or design context — do not rely on memorized LangChain APIs.

### Pick a plan

Plans are Markdown files from `/scope-contribution`. See `.cursor/plans/README.md`.

1. List `.cursor/plans/*.md` (ignore `README.md`), newest first.
2. User says **`latest`** or plans exist with no preference → use the newest plan.
3. User names a file or slug → load the matching plan.
4. Multiple plans and unclear intent → numbered list (title, scope, path); ask which to use.
5. No plans → ask package/task or use the default demo task below.

When a plan is loaded, implement against its **Acceptance criteria**, **Implementation hints**, and **Test plan**; use **Package and scope** for paths and PR scope; respect **Out of scope**.

## Default demo task (recommended)

A small, self-contained change in an **existing** partner package that needs **no API keys**:

- Add a utility function or small enhancement in `libs/partners/<name>/langchain_<name>/`
- Add matching unit tests in `tests/unit_tests/` (mirror source structure)
- Do **not** add integration tests unless the user explicitly requests them

Good packages to demo: `anthropic`, `ollama`, `deepseek` (pick one the user names or default to `anthropic`).

## Workflow

### Step 1 — Locate the package

- If using a plan from `.cursor/plans/`, start from its **Package and scope** section.
- Otherwise find the package under `libs/partners/<name>/` or `libs/core/`, `libs/langchain_v1/`, etc.
- Read `__init__.py`, nearby modules, and existing tests to match patterns.
- Identify the Conventional Commit **scope** (e.g. `anthropic`, `core`, `langchain`).

### Step 2 — Scaffold code

- Create or modify source files following existing naming and structure.
- Add type hints and Google-style docstrings on all public functions.
- Export new public symbols from `__init__.py` via `__all__` if applicable.
- Preserve public API signatures; use keyword-only args for new parameters.

### Step 3 — Scaffold tests

- Add unit tests under `tests/unit_tests/` mirroring source layout.
- No network calls in unit tests — use mocks/fixtures.
- Cover happy path, edge cases, and error conditions.

### Step 4 — Run the pre-PR gate

From the package directory:

```bash
cd libs/partners/<name>   # or relevant package path
uv sync --group test
make format
make lint
make test
```

Or from repo root:

```bash
.cursor/scripts/pre_pr.sh libs/partners/<name>
```

For `libs/langchain_v1`, run with **unrestricted permissions** in Agent chat so Docker can start test services; the script auto-falls back to `make test_fast` if Docker is unavailable.

Fix any failures before proceeding. Do not skip lint or test failures.

### Step 5 — Draft git artifacts

Produce these for the user (do not commit unless asked):

**Branch name:** `<github-username>/<scope>/<short-kebab-description>`

**PR title:** `type(scope): description` — types and scopes per `.github/workflows/pr_lint.yml`

**PR body** (no `# Summary` header):

```markdown
Fixes #<issue-number>

---

<1-2 sentences: who benefits, what problem, how this solves it>

> This contribution was prepared with AI assistance.

## How I verified

- `make format`, `make lint`, and `make test` pass in `libs/partners/<name>/`
```

## Stretch goal (only if user asks)

Scaffold a new partner package skeleton under `libs/partners/` — this is much larger and requires CI file updates per `AGENTS.md`. Prefer the default demo task for live sessions.

## Output summary

When done, report:

1. **Plan used:** path under `.cursor/plans/`, or "inline / demo task"
2. Files created or modified
3. Test results from `make test`
4. Draft branch name, PR title, and PR body
5. Any conventions you matched from existing code
6. Known limitations or follow-ups
