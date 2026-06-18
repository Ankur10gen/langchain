---
name: scope-contribution
description: Turn a product idea or issue into a scoped LangChain engineering spec with package, scope, acceptance criteria, and test plan.
disable-model-invocation: true
metadata:
  recommended-model: gpt-5.5
  role: pm
---

# Scope a LangChain contribution

Turn a product idea or issue into a scoped engineering spec. Intended for PMs and tech leads before an engineer starts coding.

## Model

**Use GPT-5.5** for this skill (structured spec writing, package mapping, acceptance criteria).

No code changes — switch to **Composer** for `/scaffold-contribution` after the spec is approved.

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

Output this template (fill every section):

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
```

## Handoff to engineer

Run `/scaffold-contribution` with this spec (**Composer**). Then `/review-before-pr` on a **different model** (Sonnet or Opus). Engineer should link PR to approved issue per contributing guidelines.

## Constraints to enforce

- Do not begin work on a PR unless assigned to an approved issue (external contributors).
- One package per PR when possible.
- No new dependencies without maintainer approval.
- All specs in English.

## Output

Deliver the filled spec and ask whether to proceed to `/scaffold-contribution` or refine the scope.
