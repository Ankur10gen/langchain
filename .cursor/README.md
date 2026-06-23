# LangChain Onboarding Kit

Cursor-native onboarding for the LangChain monorepo. **AGENTS.md is the source of truth** for conventions; this kit operationalizes it into scoped rules, guided workflows, and CI-aligned gates.

## What this kit does

| Role | Entry point | Purpose |
|------|-------------|---------|
| PM / Tech lead | `/scope-contribution` | Turn an idea into a scoped spec; saves plan to `.cursor/plans/` |
| Engineer | `/scaffold-contribution` | Load a plan from `.cursor/plans/`, scaffold code + tests, run gates |
| QA / Engineer | `/review-before-pr` | Convention checklist + report; calls `pre_pr.sh` for hard gates |
| DevOps / CI | `pre_merge_ci.sh`, `/release-readiness` | PR-level CI compliance, dependency policy, release risk |

### Model-enforced path (recommended)

Use **Cursor Automations** (`.cursor/automations/`) to run the same skills with pinned models — no manual model switching. See [Automations setup](automations/README.md).

| Automation | Model |
|------------|-------|
| LangChain: Scope contribution | GPT-5.5 |
| LangChain: Scaffold contribution | Composer |
| LangChain: Review before PR | Sonnet |
| LangChain: Release readiness | Sonnet |

Slash commands (`/scope-contribution`, etc.) remain available for ad-hoc Agent chat.

## Quick start

1. Open this repo in Cursor (`/home/raina/langchain/langchain` or your clone path).
2. Ensure rules load from `.cursor/rules/` (automatic in Cursor).
3. Confirm docs MCP servers in [`.cursor/mcp.json`](mcp.json) are connected (see [Docs MCP](#docs-mcp) below).
4. Run a workflow:
   - PM: `/scope-contribution` → describe a feature idea
   - Engineer: `/scaffold-contribution` → implement the scoped task
   - QA: `/review-before-pr` → validate before opening PR
   - DevOps: `.cursor/scripts/pre_merge_ci.sh libs/partners/anthropic "refactor(anthropic): ..."`

## Rules (`.cursor/rules/`)

| Rule | When it applies |
|------|-----------------|
| `conventions.mdc` | Always — type hints, docstrings, API stability |
| `guardrails.mdc` | Always — approved boundaries, no external code |
| `partner-package.mdc` | `libs/partners/**` — package layout, exports |
| `tests.mdc` | `libs/**/tests/**` — unit vs integration, coverage |
| `git-pr.mdc` | On demand — branch names, Conventional Commits, PR body |
| `ci-compliance.mdc` | `.github/**` — CI workflows, release path, local gate mapping |

Rules are a **derived, scoped slice** of `AGENTS.md`. When conventions change, update `AGENTS.md` first, then refresh the matching rule files.

## Skills / slash commands

Cursor discovers these as **skills** under `.cursor/skills/` (preferred in Cursor 2.4+). Legacy copies also exist in `.cursor/commands/` for older setups.

| Invoke in Agent chat | Purpose |
|----------------------|---------|
| `/scaffold-contribution` | End-to-end first contribution workflow |
| `/review-before-pr` | QA pre-review report + `pre_pr.sh` gates |
| `/scope-contribution` | PM spec template aligned with issue templates |
| `/release-readiness` | DevOps/maintainer release PR checklist |

### If you don't see them in the `/` menu

1. **Open the repo root as your workspace** — folder must be `/home/raina/langchain/langchain` (where `.cursor/` lives), not a parent folder like `/home/raina`.
2. **Reload Cursor** — Command Palette → "Developer: Reload Window" so skills are re-discovered.
3. **Check Settings → Rules** — skills should appear under Agent Decides or Manual skills.
4. **Type `/` in Agent chat** and search for `scaffold`, `review`, or `scope`.
5. **Cursor version** — skills require a recent Cursor build (2.4+). Update if `/` shows no project skills.

## Model guide (cost + cross-model quality)

**Preferred:** run workflows from [Automations](automations/README.md) — each prefill sets `workflow.model`.  
**Ad-hoc:** switch model in the chat picker **before** invoking each `/skill`. Shell scripts (`pre_pr.sh`, `pre_merge_ci.sh`) are model-agnostic.

| Skill | Role | Model | Why |
|-------|------|-------|-----|
| `/scope-contribution` | PM | **GPT-5.5** | Spec and mapping — no codegen |
| `/scaffold-contribution` | Engineer | **Composer** | Fast, strong implementation + tests |
| `/review-before-pr` | QA | **Sonnet** or **Opus** | Independent verification |
| `/release-readiness` | DevOps | **Sonnet** | Release/CI/deps risk analysis |

### Cross-model rule (write vs verify)

```text
GPT-5.5 (scope → .cursor/plans/)  →  Composer (scaffold: load plan, write code + tests)  →  Sonnet/Opus (review: verify)
                         ↑ new chat, different model ↑
```

1. **Composer writes** — `/scaffold-contribution` drafts code and unit tests, runs `pre_pr.sh`.
2. **Sonnet/Opus reviews** — start a **new chat** on Sonnet or Opus, run `/review-before-pr`. The reviewer re-reads the diff, challenges test gaps, and re-runs `pre_pr.sh` without assuming the author's reasoning.
3. Do **not** run scaffold and review in the same Composer session for production-bound work.

**Interview line:** "We separate author and verifier models — Composer for speed on implementation, Sonnet for adversarial review — with hard gates in shell scripts either way."

## Gates: engineer vs QA vs DevOps

One quality bar, three layers:

| Layer | Tool | What it enforces |
|-------|------|------------------|
| **Package** | `pre_pr.sh` | `uv sync`, `make format/lint/test`, optional PR title |
| **PR** | `pre_merge_ci.sh` | Single-package scope, no lockfile/deps on feature PRs, calls `pre_pr.sh` |
| **Release** | `/release-readiness` | Version consistency, PyPI dep risk, `_release.yml` alignment |

**QA** (`/review-before-pr`) = soft checklist + report + invokes `pre_pr.sh`  
**DevOps** = `pre_merge_ci.sh` + `/release-readiness` for CI compliance and deployment risk

## Pre-PR gate (engineer / QA)

```bash
# From repo root — package-level
.cursor/scripts/pre_pr.sh <package-path> ["type(scope): description"]

# Examples
.cursor/scripts/pre_pr.sh libs/partners/anthropic
.cursor/scripts/pre_pr.sh libs/core "fix(core): resolve type hint issue"
```

Runs `uv sync --group test`, `make format`, `make lint`, `make test` (or `make test_fast` when Docker is unavailable / `--fast`), and optionally validates PR title format against `.github/workflows/pr_lint.yml`.

For `libs/langchain_v1`, `make test` starts Postgres and Redis via Docker. When the Cursor agent sandbox blocks Docker, the script **auto-falls back** to `make test_fast`. Run from a normal terminal or with unrestricted agent permissions for the full Docker-backed suite.

## Pre-merge gate (DevOps)

```bash
# PR-level: dependency policy + package scope + pre_pr.sh
.cursor/scripts/pre_merge_ci.sh [options] [package-path] ["type(scope): description"]

# Examples
.cursor/scripts/pre_merge_ci.sh libs/partners/anthropic "refactor(anthropic): extract helper"
.cursor/scripts/pre_merge_ci.sh --base master   # auto-detect package from diff

# Release / maintainer PRs (pyproject.toml / uv.lock allowed)
.cursor/scripts/pre_merge_ci.sh --allow-deps libs/core "release(core): 1.2.0"

# Infra PRs (.github/ changes)
.cursor/scripts/pre_merge_ci.sh --allow-infra --allow-deps ...
```

Checks on feature PRs:

- No `pyproject.toml` / `uv.lock` changes (unless `--allow-deps`)
- No `.github/` changes (unless `--allow-infra`)
- Single package in diff (or explicit `--package`)
- Then runs `pre_pr.sh`

Wire into a pre-push hook:

```bash
# Example pre-push hook (optional)
.cursor/scripts/pre_merge_ci.sh --base master
```

## Path to production

Deployment for LangChain libraries is **maintainer-triggered PyPI release** (`.github/workflows/_release.yml`), not app deploy. The kit secures the path **to merge**:

```text
Contributor PR     →  pre_merge_ci.sh  →  GitHub CI  →  merge  →  _release.yml  →  PyPI
(package gates)       (PR/deps policy)     (authoritative)              (maintainer)
```

Release PRs: use `/release-readiness` and `pre_merge_ci.sh --allow-deps` before merge.

## Docs MCP

Cursor reads project MCP config from [`.cursor/mcp.json`](mcp.json). The repo ships two public HTTP MCP servers (no API keys):

| Server | URL | Use for |
|--------|-----|---------|
| `docs-langchain` | https://docs.langchain.com/mcp | Concepts, guides, contributing docs |
| `reference-langchain` | https://reference.langchain.com/mcp | API reference lookups |

The repo root also has [`.mcp.json`](../.mcp.json) with the same servers for other MCP clients (for example Claude Code). Keep both files in sync when changing server URLs.

### Enable in Cursor

1. Open this repo — [`.cursor/mcp.json`](mcp.json) should load automatically.
2. Open **Cursor Settings → MCP** and confirm both servers show as connected.
3. If they do not appear, run **Developer: Reload Window** from the Command Palette.
4. In agent chat, prefer MCP doc lookups over memorized APIs when scoping or implementing features.

When connected, the agent can call tools such as `search_docs_by_lang_chain` and `query_docs_filesystem_docs_by_lang_chain`. Start a **new** chat after enabling MCP if an existing session was opened before the servers connected.

The onboarding skills instruct the agent to use these servers at decision points (scoping, API design, checking if a feature exists).

## Contribution plans (`.cursor/plans/`)

PM/engineer handoff folder for scoped specs:

1. **`/scope-contribution`** writes `<YYYY-MM-DD>-<scope>-<kebab-slug>.md` after producing the spec.
2. **`/scaffold-contribution`** lists plans (newest first), loads `latest` or a named file, and implements against acceptance criteria.

See [`.cursor/plans/README.md`](plans/README.md). Plans are local by default — commit only when sharing with a teammate.

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
- **New CI check?** Add it to `pre_merge_ci.sh` / `pre_pr.sh` and the review checklist.
- **New role?** Add a skill under `.cursor/skills/` pointing at the same rules layer.

## 45-minute live demo script

Use this timebox for the technical screen. Adjust pacing as needed.

| Time | Segment | What to show |
|------|---------|--------------|
| 0–5 min | Problem framing | Ramp time on convention-heavy libs; AGENTS.md exists but is passive — we operationalize it |
| 5–10 min | Architecture | Rules → commands → pre-PR gate → docs MCP; multi-role entry points |
| 10–15 min | PM flow | **Automation:** Scope contribution (GPT-5.5) — or `/scope-contribution` |
| 15–25 min | Engineer flow | **Automation:** Scaffold contribution (Composer) — new run |
| 25–32 min | QA flow | **Automation:** Review before PR (Sonnet) — cross-model, new run |
| 32–38 min | DevOps | `pre_merge_ci.sh` or **Pre-merge CI** automation; **Release readiness** for releases |
| 38–45 min | Limitations + Q&A | Rules ≠ enforcement; release via `_release.yml`; kit stops at merge-ready PR |

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
├── README.md
├── mcp.json
├── plans/
│   └── README.md
├── automations/
│   ├── README.md
│   └── prefill/
│       ├── scope-contribution.json
│       ├── scaffold-contribution.json
│       ├── review-before-pr.json
│       ├── release-readiness.json
│       └── pre-merge-ci.json
├── skills/
│   ├── scaffold-contribution/SKILL.md
│   ├── review-before-pr/SKILL.md
│   ├── scope-contribution/SKILL.md
│   └── release-readiness/SKILL.md
├── commands/
│   ├── scaffold-contribution.md
│   ├── review-before-pr.md
│   ├── scope-contribution.md
│   └── release-readiness.md
├── rules/
│   ├── conventions.mdc
│   ├── guardrails.mdc
│   ├── git-pr.mdc
│   ├── ci-compliance.mdc
│   ├── partner-package.mdc
│   └── tests.mdc
└── scripts/
    ├── pre_pr.sh
    └── pre_merge_ci.sh
```

## Related repo files

- [`AGENTS.md`](../AGENTS.md) — convention source of truth
- [`.github/workflows/pr_lint.yml`](../.github/workflows/pr_lint.yml) — allowed commit types/scopes
- [`.cursor/mcp.json`](mcp.json) — docs MCP server config for Cursor
- [`.mcp.json`](../.mcp.json) — same servers for other MCP clients
- [`.github/PULL_REQUEST_TEMPLATE.md`](../.github/PULL_REQUEST_TEMPLATE.md) — PR template
- [`.github/workflows/_release.yml`](../.github/workflows/_release.yml) — maintainer PyPI release
- [`.github/workflows/check_release_deps.yml`](../.github/workflows/check_release_deps.yml) — release dependency validation
