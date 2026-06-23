# Scope a LangChain contribution

Turn a product idea or issue into a scoped engineering spec. Intended for PMs and tech leads before an engineer starts coding.

## Model

**GPT-5.5** — spec only. Hand off to **Composer** for `/scaffold-contribution`.

## Input

The user provides one of:

- A feature idea or user problem
- A bug report summary
- A link to an existing GitHub issue

If unclear, ask one clarifying question about the desired outcome and affected users.

## Step 1 — Map to a package and scope

Use `.github/ISSUE_TEMPLATE/feature-request.yml` package list and `AGENTS.md` monorepo layout.

| User mentions | Likely package path | PR scope |
|---------------|--------------------|----------|
| ChatAnthropic, Claude | `libs/partners/anthropic/` | `anthropic` |
| ChatOpenAI, OpenAI | `libs/partners/openai/` | `openai` |
| Core abstractions, LCEL | `libs/core/` | `core` |
| Main langchain package | `libs/langchain_v1/` | `langchain` |
| Legacy langchain | `libs/langchain/` | `langchain-classic` |
| Text splitters | `libs/text-splitters/` | `text-splitters` |
| Model profiles | `libs/model-profiles/` | `model-profiles` |

Use the docs MCP (`docs-langchain`, `reference-langchain`) to check whether the feature already exists.

## Step 2 — Search for duplicates

Before scoping new work:

1. Search this repo for similar functionality (`grep` / codebase search).
2. Note if an existing issue or PR already covers it.

## Step 3 — Produce the scoped spec

Fill this template (every section):

```markdown
# Contribution spec: <short title>

## Problem / user story
As a <user>, I want <capability> so that <benefit>.

## Package and scope
- **Package:** `libs/partners/<name>/` (or other path)
- **Conventional Commit scope:** `<scope>`
- **Suggested branch:** `<username>/<scope>/<kebab-description>`

## Acceptance criteria
- [ ] ...
- [ ] ...

## Out of scope
- ...

## Implementation hints (for engineer)
- Likely files to touch: ...
- Patterns to follow: <point to similar module in repo>
- Public API impact: none / additive / breaking (justify)

## Test plan
- **Unit tests** (`tests/unit_tests/`): ...
- **Integration tests** (only if network/API needed): ...
- **Edge cases:** ...

## CI / release notes
- Packages touched: ...
- CI workflows affected: likely none / list if new partner
- Breaking changes: none / describe

## Issue template draft (for GitHub)
**Package:** langchain-<name>
**Feature description:** ...
**Use case:** ...

## Handoff to engineer
Run `/scaffold-contribution` and load this plan from `.cursor/plans/`. Then `/review-before-pr` on a **different model** (Sonnet or Opus). Link the PR to an approved issue per contributing guidelines.
```

## Step 4 — Save the plan for scaffold handoff

After the spec is approved (or on first delivery unless the user asks to refine first), **write the filled spec to disk**:

1. **Directory:** `.cursor/plans/` (create it if missing).
2. **Filename:** `<YYYY-MM-DD>-<scope>-<kebab-slug>.md`
3. **Content:** the full filled template from Step 3, including the Handoff section.
4. If that filename already exists, append `-2`, `-3`, etc. before `.md`.

Do **not** commit the plan unless the user asks.

## Handoff to engineer

Tell the user the saved plan path. Next: run `/scaffold-contribution` (Composer) with `latest` or a named plan file.

## Constraints to enforce

- Do not begin work on a PR unless assigned to an approved issue (external contributors).
- One package per PR when possible.
- No new dependencies without maintainer approval.
- All specs in English.

## Output

1. Show the filled spec in chat.
2. Save it under `.cursor/plans/` (Step 4) and report the file path.
3. Ask whether to refine the scope or hand off to `/scaffold-contribution`.
