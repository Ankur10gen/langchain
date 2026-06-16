# LangChain Onboarding Kit

Cursor-native onboarding for the LangChain monorepo. **AGENTS.md is the source of truth** for conventions; this kit operationalizes it into scoped rules, guided workflows, and CI-aligned gates.

## What this kit does

| Role | Entry point | Purpose |
|------|-------------|---------|
| PM / Tech lead | `/scope-contribution` | Turn an idea into a scoped spec with package, scope, acceptance criteria |
| Engineer | `/scaffold-contribution` | Scaffold code + tests, run gates, draft branch/PR |
| QA / Engineer | `/review-before-pr` | Pre-review checklist before human review |
| DevOps / CI | `.cursor/scripts/pre_pr.sh` | Headless format/lint/test + optional PR title check |

## Quick start

1. Open this repo in Cursor (`/home/raina/langchain/langchain` or your clone path).
2. Ensure rules load from `.cursor/rules/` (automatic in Cursor).
3. Enable MCP servers from `.mcp.json` (see [Docs MCP](#docs-mcp) below).
4. Run a workflow:
   - PM: `/scope-contribution` → describe a feature idea
   - Engineer: `/scaffold-contribution` → implement the scoped task
   - QA: `/review-before-pr` → validate before opening PR
   - DevOps: `.cursor/scripts/pre_pr.sh libs/partners/anthropic "feat(anthropic): ..."`

## Rules (`.cursor/rules/`)

| Rule | When it applies |
|------|-----------------|
| `conventions.mdc` | Always — type hints, docstrings, API stability |
| `guardrails.mdc` | Always — approved boundaries, no external code |
| `partner-package.mdc` | `libs/partners/**` — package layout, exports |
| `tests.mdc` | `libs/**/tests/**` — unit vs integration, coverage |
| `git-pr.mdc` | On demand — branch names, Conventional Commits, PR body |

Rules are a **derived, scoped slice** of `AGENTS.md`. When conventions change, update `AGENTS.md` first, then refresh the matching rule files.

## Commands (`.cursor/commands/`)

- **`scaffold-contribution`** — End-to-end first contribution workflow
- **`review-before-pr`** — QA pre-review report with checklist
- **`scope-contribution`** — PM spec template aligned with issue templates

## Pre-PR gate (DevOps / headless)

```bash
# From repo root
.cursor/scripts/pre_pr.sh <package-path> ["type(scope): description"]

# Examples
.cursor/scripts/pre_pr.sh libs/partners/anthropic
.cursor/scripts/pre_pr.sh libs/core "fix(core): resolve type hint issue"
```

Runs `uv sync --group test`, `make format`, `make lint`, `make test`, and optionally validates PR title format against `.github/workflows/pr_lint.yml`.

Wire into CI or a local git hook:

```bash
# Example pre-push hook (optional)
PACKAGE=$(git diff --name-only master | grep -oP '^libs/[^/]+/[^/]+' | head -1)
[[ -n "$PACKAGE" ]] && .cursor/scripts/pre_pr.sh "$PACKAGE"
```

## Docs MCP

The repo ships [`.mcp.json`](../.mcp.json) with two HTTP MCP servers:

| Server | URL | Use for |
|--------|-----|---------|
| `docs-langchain` | https://docs.langchain.com/mcp | Concepts, guides, contributing docs |
| `reference-langchain` | https://reference.langchain.com/mcp | API reference lookups |

### Enable in Cursor

1. Open **Cursor Settings → MCP** (or use the repo's `.mcp.json` if Cursor auto-detects project MCP config).
2. Confirm both servers appear and are enabled.
3. In agent chat, prefer MCP doc lookups over memorized APIs when scoping or implementing features.

The onboarding commands instruct the agent to use these servers at decision points (scoping, API design, checking if a feature exists).

## Team ownership and maintenance

### Refreshing rules from AGENTS.md

When `AGENTS.md` or `pr_lint.yml` changes:

1. Diff the changed sections in `AGENTS.md` / `.github/workflows/pr_lint.yml`.
2. Update the corresponding `.cursor/rules/*.mdc` file(s).
3. Update command steps if workflows changed (e.g. new `make` targets).
4. Re-run `.cursor/scripts/pre_pr.sh` on a sample package to verify gates still pass.

LangChain CI enforces `AGENTS.md` ↔ `CLAUDE.md` sync (`.github/workflows/check_agents_sync.yml`). Do not fork conventions into this kit — derive from those files.

### Extending the kit

- **New package type?** Add a scoped rule with appropriate `globs`.
- **New CI check?** Add it to `pre_pr.sh` and the review checklist.
- **New role?** Add a command under `.cursor/commands/` pointing at the same rules layer.

## 45-minute live demo script

Use this timebox for the technical screen. Adjust pacing as needed.

| Time | Segment | What to show |
|------|---------|--------------|
| 0–5 min | Problem framing | Ramp time on convention-heavy libs; AGENTS.md exists but is passive — we operationalize it |
| 5–10 min | Architecture | Rules → commands → pre-PR gate → docs MCP; multi-role entry points |
| 10–15 min | PM flow | `/scope-contribution` — "Add retry helper to anthropic client utils" → scoped spec |
| 15–30 min | Engineer flow | `/scaffold-contribution` — implement small util + unit tests in `libs/partners/anthropic/` |
| 30–38 min | QA + DevOps | `/review-before-pr` report; run `.cursor/scripts/pre_pr.sh libs/partners/anthropic "feat(anthropic): ..."` |
| 38–45 min | Limitations + Q&A | Rules ≠ enforcement; integration tests need keys; rules drift if AGENTS.md changes |

### Demo task (recommended)

Add a small pure function in `libs/partners/anthropic/langchain_anthropic/_client_utils.py` (or a new `_utils.py`) with unit tests — no API keys, fast `make test`.

### Talking points

- **Why not duplicate AGENTS.md?** It's the constitution; we built scoped rules + workflows + gates.
- **Why Cursor-native?** Runnable live, team owns `.cursor/` in-repo, no separate app to maintain.
- **Where it breaks:** Agent may miss edge conventions; hard gates (`make lint`/`test`) catch what prose cannot.
- **Honesty:** If unsure about an API, query docs MCP — don't guess.

## File layout

```txt
.cursor/
├── README.md                 # This file
├── commands/
│   ├── scaffold-contribution.md
│   ├── review-before-pr.md
│   └── scope-contribution.md
├── rules/
│   ├── conventions.mdc
│   ├── guardrails.mdc
│   ├── git-pr.mdc
│   ├── partner-package.mdc
│   └── tests.mdc
└── scripts/
    └── pre_pr.sh
```

## Related repo files

- [`AGENTS.md`](../AGENTS.md) — convention source of truth
- [`.github/workflows/pr_lint.yml`](../.github/workflows/pr_lint.yml) — allowed commit types/scopes
- [`.mcp.json`](../.mcp.json) — docs MCP server config
- [`.github/PULL_REQUEST_TEMPLATE.md`](../.github/PULL_REQUEST_TEMPLATE.md) — PR template
